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
public final class OryAuthClient: Sendable {

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

            if let token = result.sessionToken {
                try? await tokenStorage.saveToken(token)
            }

            return OrySession.from(
                session: result.session,
                token: result.sessionToken ?? ""
            )
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
    /// On success, the session token is automatically stored in the Keychain
    /// if auto-login is enabled on the Ory project.
    ///
    /// - Parameters:
    ///   - flowId: The flow ID from `FlowContainer.id`.
    ///   - credentials: Type-safe credentials for registration.
    /// - Returns: The authenticated `OrySession`.
    /// - Throws: `OryError` if registration fails.
    public func submitRegistration(
        flowId: String,
        credentials: RegistrationCredentials
    ) async throws -> OrySession {
        let body = credentials.toUpdateBody()

        do {
            let apiConfig = configuration.makeAPIConfiguration()
            let result = try await OryClient.FrontendAPI.updateRegistrationFlow(
                flow: flowId,
                updateRegistrationFlowBody: body,
                apiConfiguration: apiConfig
            )

            if let token = result.sessionToken {
                try? await tokenStorage.saveToken(token)
            }

            let session = result.session
            let token = result.sessionToken ?? ""

            if let session {
                return OrySession.from(session: session, token: token)
            }

            return OrySession(
                id: "",
                token: token,
                identity: OryIdentity.from(result.identity),
                expiresAt: nil,
                authenticatedAt: nil,
                isActive: false
            )
        } catch {
            throw OryError.map(from: error, flowType: .registration)
        }
    }

    // MARK: - Session

    /// Check the current session.
    ///
    /// Uses the stored session token to query the Ory API for the current session.
    ///
    /// - Returns: The current `OrySession`, or `nil` if not authenticated.
    /// - Throws: `OryError` for network errors.
    public func getSession() async throws -> OrySession? {
        guard let token = await tokenStorage.loadToken() else {
            return nil
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
                return nil
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
}

// MARK: - Credential → OryClient Body Conversion

extension LoginCredentials {

    /// Convert type-safe credentials to the generated OryClient body type.
    func toUpdateBody() -> UpdateLoginFlowBody {
        switch self {
        case .password(let identifier, let password):
            let body = UpdateLoginFlowWithPasswordMethod(
                identifier: identifier,
                method: "password",
                password: password
            )
            return .typeUpdateLoginFlowWithPasswordMethod(body)

        case .passkey(let response):
            let body = UpdateLoginFlowWithPasskeyMethod(
                method: "passkey",
                passkeyLogin: response
            )
            return .typeUpdateLoginFlowWithPasskeyMethod(body)
        }
    }
}

extension RegistrationCredentials {

    /// Convert type-safe credentials to the generated OryClient body type.
    func toUpdateBody() -> UpdateRegistrationFlowBody {
        switch self {
        case .password(let password, let traits):
            var traitsDict: [String: JSONValue] = [:]
            for (key, value) in traits {
                traitsDict[key] = .string(value)
            }

            let body = UpdateRegistrationFlowWithPasswordMethod(
                method: "password",
                password: password,
                traits: .dictionary(traitsDict)
            )
            return .typeUpdateRegistrationFlowWithPasswordMethod(body)
        }
    }
}
