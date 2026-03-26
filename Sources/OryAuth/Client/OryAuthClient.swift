//
//  OryAuth.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 25/03/2026.
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
///     values: ["identifier": "user@example.com", "password": "secret", "method": "password"]
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
    /// Collects field values from the UI and submits them to the Ory Kratos API.
    /// On success, the session token is automatically stored in the Keychain.
    ///
    /// - Parameters:
    ///   - flowId: The flow ID from `FlowContainer.id`.
    ///   - values: A dictionary of field name → value pairs. Must include a `"method"` key
    ///             (e.g. `"password"`, `"passkey"`).
    /// - Returns: The authenticated `OrySession`.
    /// - Throws: `OryError` if login fails (validation, expired flow, network, etc.).
    public func submitLogin(flowId: String, values: [String: String]) async throws -> OrySession {
        let body = try buildLoginBody(from: values)

        do {
            let apiConfig = configuration.makeAPIConfiguration()
            let sessionToken = await tokenStorage.loadToken()
            let result = try await FrontendAPI.updateLoginFlow(
                flow: flowId,
                updateLoginFlowBody: body,
                xSessionToken: sessionToken,
                apiConfiguration: apiConfig
            )

            // Store session token securely
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
    /// - Parameters:
    ///   - flowId: The flow ID from `FlowContainer.id`.
    ///   - values: A dictionary of field name → value pairs. Must include a `"method"` key.
    /// - Returns: The authenticated `OrySession` if auto-login is enabled, or a session
    ///            from the registration response.
    /// - Throws: `OryError` if registration fails.
    public func submitRegistration(flowId: String, values: [String: String]) async throws -> OrySession {
        let body = try buildRegistrationBody(from: values)

        do {
            let apiConfig = configuration.makeAPIConfiguration()
            let result = try await FrontendAPI.updateRegistrationFlow(
                flow: flowId,
                updateRegistrationFlowBody: body,
                apiConfiguration: apiConfig
            )

            // Store session token if provided (auto-login after registration)
            if let token = result.sessionToken {
                try? await tokenStorage.saveToken(token)
            }

            let session = result.session
            let token = result.sessionToken ?? ""

            if let session {
                return OrySession.from(session: session, token: token)
            }

            // If no session returned, build a minimal one from identity
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
            if case .error(let statusCode, _, _, _) = error, statusCode == 401 {
                // Token is invalid or expired — clean up
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

    // MARK: - Body Builders

    /// Build the `UpdateLoginFlowBody` from a values dictionary.
    private func buildLoginBody(from values: [String: String]) throws -> UpdateLoginFlowBody {
        guard let method = values["method"] else {
            throw OryError.unknown(statusCode: 0, message: "Missing 'method' key in values")
        }

        switch method {
        case "password":
            let body = UpdateLoginFlowWithPasswordMethod(
                identifier: values["identifier"] ?? "",
                method: method,
                password: values["password"] ?? ""
            )
            return .typeUpdateLoginFlowWithPasswordMethod(body)

        case "passkey":
            let body = UpdateLoginFlowWithPasskeyMethod(
                method: method,
                passkeyLogin: values["passkey_login"]
            )
            return .typeUpdateLoginFlowWithPasskeyMethod(body)

        default:
            throw OryError.unknown(statusCode: 0, message: "Unsupported login method: \(method)")
        }
    }

    /// Build the `UpdateRegistrationFlowBody` from a values dictionary.
    private func buildRegistrationBody(from values: [String: String]) throws -> UpdateRegistrationFlowBody {
        guard let method = values["method"] else {
            throw OryError.unknown(statusCode: 0, message: "Missing 'method' key in values")
        }

        switch method {
        case "password":
            // Build traits from values (exclude known non-trait fields)
            let reservedKeys: Set<String> = ["method", "password", "csrf_token"]
            var traitsDict: [String: JSONValue] = [:]
            for (key, value) in values where key.hasPrefix("traits.") {
                let traitKey = String(key.dropFirst("traits.".count))
                traitsDict[traitKey] = .string(value)
            }

            let body = UpdateRegistrationFlowWithPasswordMethod(
                method: method,
                password: values["password"] ?? "",
                traits: .dictionary(traitsDict)
            )
            return .typeUpdateRegistrationFlowWithPasswordMethod(body)

        default:
            throw OryError.unknown(statusCode: 0, message: "Unsupported registration method: \(method)")
        }
    }
}
