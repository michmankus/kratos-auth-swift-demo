//
//  FlowExpiredErrorMapper.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 27/03/2026.
//

import Foundation
import OryClient

// MARK: - FlowExpiredErrorMapper

/// Maps HTTP 410 response data to a ``OryError/flowExpired(newFlowId:)`` error.
///
/// Ory Kratos returns 410 when a self-service flow has expired. The response
/// may contain an `ErrorFlowReplaced` body with a `use_flow_id` pointing
/// to the replacement flow, or a `GenericError` confirming expiration.
enum FlowExpiredErrorMapper: Mapper {

    typealias Input = Data?
    typealias Output = OryError
    typealias Failure = Never

    static func map(_ input: Data?) -> Result<OryError, Never> {
        map(input, jsonDecoder: .iso8601Decoder)
    }

    static func map(_ input: Data?, jsonDecoder: JSONDecoder = .iso8601Decoder) -> Result<OryError, Never> {
        guard let data = input else {
            return .success(.flowExpired(newFlowId: nil))
        }

        if let replaced = try? jsonDecoder.decode(OryClient.ErrorFlowReplaced.self, from: data) {
            return .success(.flowExpired(newFlowId: replaced.useFlowId))
        }

        if let genericError = try? jsonDecoder.decode(OryClient.GenericError.self, from: data) {
            if genericError.id == "self_service_flow_expired" {
                return .success(.flowExpired(newFlowId: nil))
            }
        }

        return .success(.flowExpired(newFlowId: nil))
    }
}
