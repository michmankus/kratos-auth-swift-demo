//
//  OryAuth.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 25/03/2026.
//

import Foundation
import OryClient

// MARK: - OryError

/// Typed error model for Ory authentication flows.
///
/// Clearly distinguishes between different error categories so app developers
/// can handle each case appropriately:
/// - Network failures → retry or show connectivity error
/// - Validation errors → re-render the form with field-level messages
/// - Expired flow → re-initialize the flow
/// - Session conflicts → redirect to profile
/// - Unknown errors → show generic error message
public enum OryError: Error, Sendable {

    /// A network-level error occurred (no connectivity, DNS failure, timeout, etc.).
    case network(underlying: Error)

    /// The server returned validation errors (HTTP 400).
    /// The associated `FlowContainer` contains updated nodes with per-field error messages.
    /// Re-render the form using this updated flow.
    case validation(flow: FlowContainer)

    /// The flow has expired and must be re-initialized (HTTP 410).
    /// If `newFlowId` is provided, you can fetch the replacement flow directly.
    case flowExpired(newFlowId: String?)

    /// The user already has an active session (HTTP 400, `session_already_available`).
    case sessionAlreadyAvailable

    /// Authentication is required but no valid session exists (HTTP 401).
    case unauthorized

    /// An unexpected error occurred.
    case unknown(statusCode: Int, message: String?)
}

// MARK: - Error Mapping

extension OryError {

    /// Maps a generated `ErrorResponse` from OryClient into a typed `OryError`.
    ///
    /// The generated client throws `ErrorResponse.error(statusCode, data, response, underlyingError)`.
    /// This method inspects the status code and response body to determine the specific error type.
    static func map(from errorResponse: OryClient.ErrorResponse, flowType: FlowType = .login) -> OryError {
        guard case .error(let statusCode, let data, _, let underlyingError) = errorResponse else {
            return .unknown(statusCode: -1, message: "Unexpected error format")
        }

        // Network-level errors (no HTTP response)
        if statusCode < 0 || underlyingError is URLError {
            return .network(underlying: underlyingError)
        }

        switch statusCode {
        case 400:
            return map400Error(data: data, flowType: flowType)
        case 401:
            return .unauthorized
        case 410:
            return map410Error(data: data)
        default:
            let message = extractMessage(from: data)
            return .unknown(statusCode: statusCode, message: message)
        }
    }

    /// Handle HTTP 400 — either a known error ID or a validation error with updated flow.
    private static func map400Error(data: Data?, flowType: FlowType) -> OryError {
        guard let data else {
            return .unknown(statusCode: 400, message: nil)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // First, check for known error IDs (e.g. session_already_available)
        if let genericError = try? decoder.decode(OryClient.GenericError.self, from: data) {
            if genericError.id == "session_already_available" {
                return .sessionAlreadyAvailable
            }
        }

        // Otherwise, treat as validation error — the body is an updated flow with messages
        switch flowType {
        case .login:
            if let loginFlow = try? decoder.decode(OryClient.LoginFlow.self, from: data) {
                return .validation(flow: NodeParser.parseLoginFlow(loginFlow))
            }
        case .registration:
            if let registrationFlow = try? decoder.decode(OryClient.RegistrationFlow.self, from: data) {
                return .validation(flow: NodeParser.parseRegistrationFlow(registrationFlow))
            }
        }

        let message = extractMessage(from: data)
        return .unknown(statusCode: 400, message: message)
    }

    /// Handle HTTP 410 — flow expired, possibly with a replacement flow ID.
    private static func map410Error(data: Data?) -> OryError {
        guard let data else {
            return .flowExpired(newFlowId: nil)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Try to decode as ErrorFlowReplaced which contains use_flow_id
        if let replaced = try? decoder.decode(OryClient.ErrorFlowReplaced.self, from: data) {
            return .flowExpired(newFlowId: replaced.useFlowId)
        }

        // Try GenericError for the error message
        if let genericError = try? decoder.decode(OryClient.GenericError.self, from: data) {
            if genericError.id == "self_service_flow_expired" {
                return .flowExpired(newFlowId: nil)
            }
        }

        return .flowExpired(newFlowId: nil)
    }

    /// Extract a human-readable message from response data.
    private static func extractMessage(from data: Data?) -> String? {
        guard let data else { return nil }
        let decoder = JSONDecoder()
        if let genericError = try? decoder.decode(OryClient.GenericError.self, from: data) {
            return genericError.message
        }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - FlowType

/// Identifies which type of flow is being processed, used for error mapping.
public enum FlowType: String, Sendable {
    case login
    case registration
}
