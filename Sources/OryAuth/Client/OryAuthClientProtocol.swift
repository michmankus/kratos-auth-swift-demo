//
//  OryAuthClientProtocol.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Foundation

// MARK: - OryAuthClientProtocol

/// Public protocol defining the Ory Auth SDK interface.
///
/// Depend on this protocol instead of the concrete `OryAuthClient`
/// to enable unit testing with mock implementations.
///
/// ```swift
/// // In production
/// let client: any OryAuthClientProtocol = OryAuthClient(configuration: config)
///
/// // In tests
/// let client: any OryAuthClientProtocol = MockOryAuthClient()
/// ```
public protocol OryAuthClientProtocol: Sendable {

    /// Initialize a new native login flow.
    ///
    /// - Returns: A `FlowContainer` containing the form fields to render.
    /// - Throws: `OryError` if the request fails.
    func initLoginFlow() async throws(OryError) -> FlowContainer

    /// Submit login credentials for a given flow.
    ///
    /// On success, the session token is automatically stored in the Keychain.
    ///
    /// - Parameters:
    ///   - flowId: The flow ID from `FlowContainer.id`.
    ///   - credentials: Type-safe credentials for the chosen auth method.
    /// - Returns: The authenticated `OrySession`.
    /// - Throws: `OryError` if login fails.
    func submitLogin(flowId: String, credentials: LoginCredentials) async throws(OryError) -> OrySession

    /// Initialize a new native registration flow.
    ///
    /// - Returns: A `FlowContainer` containing the registration form fields.
    /// - Throws: `OryError` if the request fails.
    func initRegistrationFlow() async throws(OryError) -> FlowContainer

    /// Submit registration data for a given flow.
    ///
    /// - Parameters:
    ///   - flowId: The flow ID from `FlowContainer.id`.
    ///   - credentials: Type-safe credentials for registration.
    /// - Returns: A ``RegistrationResult`` indicating the outcome.
    /// - Throws: `OryError` if registration fails.
    func submitRegistration(flowId: String, credentials: RegistrationCredentials) async throws(OryError) -> RegistrationResult

    /// Loads the current session from the server using the stored token.
    ///
    /// - Returns: The current `OrySession`.
    /// - Throws: `OryError.missingSessionToken` if no token is stored,
    ///   `OryError.unauthorized` if the token is invalid.
    func loadSession() async throws(OryError) -> OrySession

    /// Log out and clear the stored session token.
    ///
    /// - Throws: `OryError` if the logout API call fails.
    func logout() async throws(OryError)

    /// Whether a session token is stored locally.
    ///
    /// - Note: This does not verify the token is still valid with the server.
    var isAuthenticated: Bool { get async }
}
