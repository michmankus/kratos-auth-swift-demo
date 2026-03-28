//
//  OryError.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Foundation

// MARK: - OryError

/// Typed error model for Ory authentication flows.
///
/// Clearly distinguishes between different error categories so app developers
/// can handle each case appropriately:
///
/// - `.network` → retry or show connectivity error
/// - `.validation` → re-render the form with field-level messages
/// - `.flowExpired` → re-initialize the flow
/// - `.sessionAlreadyAvailable` → redirect to profile
/// - `.unauthorized` → prompt login
/// - `.missingSessionToken` → no stored token, prompt login
/// - `.keychainError` → keychain failed when retrieving or saving data
/// - `.unknown` → show generic server error message
public enum OryError: Error, Sendable {

    /// A network-level error occurred (no connectivity, DNS failure, timeout, etc.).
    case network(underlying: Error)

    /// The server returned validation errors (HTTP 400).
    ///
    /// The associated `FlowContainer` contains updated nodes with per-field
    /// error messages. Re-render the form using this updated flow to show
    /// the user what needs to be fixed.
    case validation(flow: FlowContainer)

    /// The flow has expired and must be re-initialized (HTTP 410).
    ///
    /// If `newFlowId` is provided, you can fetch the replacement flow directly
    /// instead of creating a brand new one.
    case flowExpired(newFlowId: String?)

    /// The user already has an active session (HTTP 400, `session_already_available`).
    case sessionAlreadyAvailable

    /// Authentication is required but no valid session exists (HTTP 401).
    case unauthorized

    /// The server returned a success response but the session token was missing.
    ///
    /// This is unexpected for native API flows and may indicate a server
    /// misconfiguration or an incompatible Ory project setup.
    case missingSessionToken

    /// The Keychain operation threw an error.
    ///
    /// This is usually unexpected unless there is an issue with the device.
    /// Wraps the error thrown by the keychain as an associated value.
    case keychainError(Error)

    /// An unexpected server error occurred.
    case unknown(statusCode: Int, message: String?)
}
