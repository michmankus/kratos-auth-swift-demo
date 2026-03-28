//
//  OryErrorMapper.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 27/03/2026.
//

import Foundation
import OryClient

// MARK: - OryErrorMapper

/// Maps any error thrown by the generated OryClient into a typed ``OryError``.
///
/// Conforms to ``Mapper`` with `Failure == Never`, so callers use
/// `flatMap` for a guaranteed result:
///
/// ```swift
/// throw OryErrorMapper.flatMap(error)
/// ```
///
/// Internally composes ``ValidationErrorMapper`` (HTTP 400) and
/// ``FlowExpiredErrorMapper`` (HTTP 410) for status-specific handling.
enum OryErrorMapper: Mapper {

    typealias Input = any Error
    typealias Output = OryError
    typealias Failure = Never

    static func map(_ input: any Error) -> Result<OryError, Never> {
        if let oryError = input as? OryError {
            return .success(oryError)
        }

        if input is URLError {
            return .success(.network(underlying: input))
        }

        if let errorResponse = input as? OryClient.ErrorResponse {
            return .success(mapErrorResponse(errorResponse))
        }

        return .success(.network(underlying: input))
    }

    // MARK: - Private

    private static func mapErrorResponse(_ errorResponse: OryClient.ErrorResponse) -> OryError {
        guard case .error(let statusCode, let data, _, let underlyingError) = errorResponse else {
            return .unknown(statusCode: -1, message: "Unexpected error format")
        }

        if statusCode < 0 || underlyingError is URLError {
            return .network(underlying: underlyingError)
        }

        switch statusCode {
        case 400:
            guard let data else {
                return .unknown(statusCode: 400, message: nil)
            }
            return ValidationErrorMapper.flatMap(data)

        case 401:
            return .unauthorized

        case 410:
            return FlowExpiredErrorMapper.flatMap(data)

        default:
            let message = extractMessage(from: data)
            return .unknown(statusCode: statusCode, message: message)
        }
    }

    private static func extractMessage(from data: Data?, jsonDecoder: JSONDecoder = JSONDecoder()) -> String? {
        guard let data else { return nil }
        if let genericError = try? jsonDecoder.decode(OryClient.GenericError.self, from: data) {
            return genericError.message
        }
        return String(data: data, encoding: .utf8)
    }
}
