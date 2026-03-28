//
//  ValidationErrorMapper.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 27/03/2026.
//

import Foundation
import OryClient

// MARK: - ValidationErrorMapper

/// Maps HTTP 400 response data to a typed ``OryError``.
///
/// Handles two categories of 400 responses from Ory Kratos:
/// 1. Known error IDs (e.g. `session_already_available`) → specific error case
/// 2. Updated flow with validation messages → `.validation(flow:)` with parsed nodes
///
/// Tries decoding as both `LoginFlow` and `RegistrationFlow` — the JSON
/// shapes are distinct enough that only the correct one succeeds. This
/// eliminates the need for the caller to specify which flow type is active.
enum ValidationErrorMapper: Mapper {

    typealias Input = Data
    typealias Output = OryError
    typealias Failure = Never

    static func map(_ input: Data) -> Result<OryError, Never> {
        map(input, jsonDecoder: .iso8601Decoder)
    }

    static func map(_ input: Data, jsonDecoder: JSONDecoder = .iso8601Decoder) -> Result<OryError, Never> {
        if let genericError = try? jsonDecoder.decode(OryClient.GenericError.self, from: input) {
            if genericError.id == "session_already_available" {
                return .success(.sessionAlreadyAvailable)
            }
        }

        if let loginFlow = try? jsonDecoder.decode(OryClient.LoginFlow.self, from: input) {
            return .success(.validation(flow: NodeParser.parseLoginFlow(loginFlow)))
        }

        if let registrationFlow = try? jsonDecoder.decode(OryClient.RegistrationFlow.self, from: input) {
            return .success(.validation(flow: NodeParser.parseRegistrationFlow(registrationFlow)))
        }

        let message = extractMessage(from: input, jsonDecoder: jsonDecoder)
        return .success(.unknown(statusCode: 400, message: message))
    }

    // MARK: - Private

    private static func extractMessage(from data: Data, jsonDecoder: JSONDecoder = JSONDecoder()) -> String? {
        if let genericError = try? jsonDecoder.decode(OryClient.GenericError.self, from: data) {
            return genericError.message
        }
        return String(data: data, encoding: .utf8)
    }
}
