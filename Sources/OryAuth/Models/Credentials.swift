//
//  Credentials.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Foundation

// MARK: - LoginCredentials

/// Type-safe credentials for login submission.
///
/// Each case represents a supported authentication method with
/// its required parameters enforced at compile time.
///
/// ```swift
/// // Password login — compiler ensures identifier and password are provided
/// let credentials = LoginCredentials.password(
///     identifier: "user@example.com",
///     password: "s3cret"
/// )
///
/// // Passkey login — requires the signed WebAuthn assertion response
/// let credentials = LoginCredentials.passkey(
///     response: passkeyAssertionJSON
/// )
/// ```
public enum LoginCredentials: Sendable {

    /// Login with identifier (email/username) and password.
    case password(identifier: String, password: String)

    /// Login with a passkey (WebAuthn assertion).
    /// - Parameter response: The JSON-encoded WebAuthn assertion response
    ///   from `ASAuthorizationPlatformPublicKeyCredentialAssertion`.
    case passkey(response: String)
}

// MARK: - RegistrationCredentials

/// Type-safe credentials for registration submission.
///
/// Each case represents a supported registration method with
/// its required parameters enforced at compile time.
///
/// ```swift
/// let credentials = RegistrationCredentials.password(
///     password: "s3cret",
///     traits: ["email": "user@example.com", "name.first": "Jane"]
/// )
/// ```
public enum RegistrationCredentials: Sendable {

    /// Register with a password and identity traits.
    ///
    /// - Parameters:
    ///   - password: The user's chosen password.
    ///   - traits: Identity traits matching your Ory identity schema.
    ///     Keys should match the schema field names (e.g. `"email"`, `"name.first"`).
    case password(password: String, traits: [String: String])
}
