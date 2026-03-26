//
//  OryAuthClient.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Foundation
import OryClient
import SecureStorage

// MARK: - OryAuthClient

/// The main entry point for the Ory Auth SDK.
///
/// Provides a clean, async/await API for Ory Network Kratos authentication flows.
/// All UI node parsing, error mapping, and session token management is handled
/// internally — consumers only work with platform-native Swift types.
///
/// ```swift
/// let client = OryAuthClient(
///     configuration: OryConfiguration(serverURL: URL(string: "https://your.oryapis.com")!)
/// )
///
/// let flow = try await client.initLoginFlow()
/// // Render flow.visibleFields in your UI...
///
/// let session = try await client.submitLogin(
///     flowId: flow.id,
///     credentials: .password(identifier: "user@example.com", password: "s3cret")
/// )
/// ```
public final class OryAuthClient: OryAuthClientProtocol {

    private let configuration: OryConfiguration
    private let tokenStorage: TokenStorage

    /// Creates a new Ory Auth client.
    ///
    /// - Parameters:
    ///   - configuration: The SDK configuration with your Ory project URL.
    ///   - keychain: A `KeychainProtocol` implementation for secure token storage.
    ///               Defaults to `KeychainImplementation()` which uses the iOS Keychain.
    public init(
        configuration: OryConfiguration,
        keychain: any KeychainProtocol = KeychainImplementation()
    ) {
        self.configuration = configuration
        self.tokenStorage = TokenStorage(keychain: keychain)
    }

    // MARK: - Login Flow

    /// Initialize a new native login flow.
    ///
    /// Calls the Ory Kratos API to create a login flow and returns
    /// a `FlowContainer` with parsed, UI-ready form nodes.
    ///
    /// - Returns: A `FlowContainer` containing the form fields to render.
    /// - Throws: `OryError` if the request fails.
    public func initLoginFlow() async throws -> FlowContainer {
        do {
            let apiConfig = configuration.makeAPIConfiguration()
            let sessionToken = await tokenStorage.loadToken()
            let loginFlow = try await FrontendAPI.createNativeLoginFlow(
                xSessionToken: sessionToken,
                apiConfiguration: apiConfig
            )
            return NodeParser.parseLoginFlow(loginFlow)
        } catch {
            throw OryError.map(from: error, flowType: .login)
        }
    }

    /// Submit login credentials for a given flow.
    ///
    /// On success, the session token is automatically stored in the Keychain.
    ///
    /// - Parameters:
    ///   - flowId: The flow ID from `FlowContainer.id`.
    ///   - credentials: Type-safe credentials for the chosen auth method.
    /// - Returns: The authenticated `OrySession`.
    /// - Throws: `OryError` if login fails (validation, expired flow, network, etc.).
    public func submitLogin(
        flowId: String,
        credentials: LoginCredentials
    ) async throws -> OrySession {
        let body = credentials.toUpdateBody()

        do {
            let apiConfig = configuration.makeAPIConfiguration()
            let sessionToken = await tokenStorage.loadToken()
            let result = try await FrontendAPI.updateLoginFlow(
                flow: flowId,
                updateLoginFlowBody: body,
                xSessionToken: sessionToken,
                apiConfiguration: apiConfig
            )

            guard let token = result.sessionToken else {
                throw OryError.missingSessionToken
            }

            return try await storeAndBuildSession(token: token, session: result.session)
        } catch {
            throw OryError.map(from: error, flowType: .login)
        }
    }

    // MARK: - Registration Flow

    /// Initialize a new native registration flow.
    ///
    /// - Returns: A `FlowContainer` containing the registration form fields.
    /// - Throws: `OryError` if the request fails.
    public func initRegistrationFlow() async throws -> FlowContainer {
        do {
            let apiConfig = configuration.makeAPIConfiguration()
            let registrationFlow = try await FrontendAPI.createNativeRegistrationFlow(
                apiConfiguration: apiConfig
            )
            return NodeParser.parseRegistrationFlow(registrationFlow)
        } catch {
            throw OryError.map(from: error, flowType: .registration)
        }
    }

    /// Submit registration data for a given flow.
    ///
    /// Registration may or may not produce an active session, depending on
    /// whether email verification is required in your Ory project.
    ///
    /// - Parameters:
    ///   - flowId: The flow ID from `FlowContainer.id`.
    ///   - credentials: Type-safe credentials for registration.
    /// - Returns: A ``RegistrationResult`` — either `.session` (authenticated)
    ///   or `.pendingVerification` (needs email confirmation).
    /// - Throws: `OryError` if registration fails.
    public func submitRegistration(
        flowId: String,
        credentials: RegistrationCredentials
    ) async throws -> RegistrationResult {
        let body = credentials.toUpdateBody()

        do {
            let apiConfig = configuration.makeAPIConfiguration()
            let result = try await OryClient.FrontendAPI.updateRegistrationFlow(
                flow: flowId,
                updateRegistrationFlowBody: body,
                apiConfiguration: apiConfig
            )

            // If a session token is returned, the user is immediately authenticated
            if let token = result.sessionToken, let session = result.session {
                let orySession = try await storeAndBuildSession(token: token, session: session)
                return .session(orySession)
            }

            // No session → verification is required before login
            return .pendingVerification(identity: OryIdentity.from(result.identity))
        } catch {
            throw OryError.map(from: error, flowType: .registration)
        }
    }

    // MARK: - Session

    /// Loads the current session.
    ///
    /// Uses the stored session token to query the Ory API for the current session.
    /// Shouldn't be called frequently, triggers network request.
    /// Store the OrySession object for future reuse if needed.
    ///
    /// - Returns: The current `OrySession`,
    /// - Throws: `OryError` if fails to retrieve session.
    public func loadSession() async throws -> OrySession {
        guard let token = await tokenStorage.loadToken() else {
            throw OryError.missingSessionToken
        }

        do {
            let apiConfig = configuration.makeAPIConfiguration()
            let session = try await FrontendAPI.toSession(
                xSessionToken: token,
                apiConfiguration: apiConfig
            )
            return OrySession.from(session: session, token: token)
        } catch {
            if case .error(let statusCode, _, _, _) = error,
               statusCode == 401
            {
                try? await tokenStorage.deleteToken()
                throw OryError.unauthorized
            }
            throw OryError.map(from: error, flowType: .login)
        }
    }

    /// Log out and clear the stored session token.
    ///
    /// - Throws: `OryError` if the logout API call fails.
    public func logout() async throws {
        guard let token = await tokenStorage.loadToken() else {
            return
        }

        do {
            let apiConfig = configuration.makeAPIConfiguration()
            let body = PerformNativeLogoutBody(sessionToken: token)
            try await FrontendAPI.performNativeLogout(
                performNativeLogoutBody: body,
                apiConfiguration: apiConfig
            )
            try? await tokenStorage.deleteToken()
        } catch {
            // Even if logout fails server-side, clear local token
            try? await tokenStorage.deleteToken()
            throw OryError.map(from: error, flowType: .login)
        }
    }

    /// Whether a session token is stored locally.
    ///
    /// - Note: This does not verify the token is still valid with the server.
    ///         Use `getSession()` for a verified check.
    public var isAuthenticated: Bool {
        get async {
            await tokenStorage.loadToken() != nil
        }
    }

    // MARK: - Private Helpers

    /// Store the session token in the Keychain and build an `OrySession`.
    ///
    /// Single responsibility: persists the token and converts the generated
    /// `Session` into our public `OrySession`. Used by both login and registration.
    private func storeAndBuildSession(
        token: String,
        session: OryClient.Session
    ) async throws -> OrySession {
        try await tokenStorage.saveToken(token)
        return OrySession.from(session: session, token: token)
    }
}

