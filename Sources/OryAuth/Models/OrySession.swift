//
//  OryAuth.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 25/03/2026.
//

import Foundation
import OryClient

// MARK: - OrySession

/// Represents an authenticated user session returned after successful login or registration.
///
/// Contains the session token (for authenticating subsequent requests),
/// the user's identity information, and session metadata.
public struct OrySession: Sendable {

    /// The unique session identifier.
    public let id: String

    /// The session token used to authenticate API requests.
    /// Sent via the `X-Session-Token` header.
    public let token: String

    /// The authenticated user's identity.
    public let identity: OryIdentity

    /// When this session expires, if set.
    public let expiresAt: Date?

    /// When the user authenticated to create this session.
    public let authenticatedAt: Date?

    /// Whether this session is currently active.
    public let isActive: Bool

    public init(
        id: String,
        token: String,
        identity: OryIdentity,
        expiresAt: Date?,
        authenticatedAt: Date?,
        isActive: Bool
    ) {
        self.id = id
        self.token = token
        self.identity = identity
        self.expiresAt = expiresAt
        self.authenticatedAt = authenticatedAt
        self.isActive = isActive
    }
}

// MARK: - OryIdentity

/// The authenticated user's identity, containing profile traits.
public struct OryIdentity: Sendable {

    /// The unique identity identifier.
    public let id: String

    /// The identity schema ID (defines which traits are available).
    public let schemaId: String

    /// The identity's state (e.g. `"active"`, `"inactive"`).
    public let state: String?

    /// The user's profile traits as key-value pairs.
    ///
    /// The available traits depend on your Ory identity schema.
    /// Common traits include `"email"`, `"name"`, etc.
    ///
    /// Access values using subscript:
    /// ```swift
    /// let email = identity.traits["email"] // "user@example.com"
    /// ```
    public let traits: [String: String]

    public init(id: String, schemaId: String, state: String?, traits: [String: String]) {
        self.id = id
        self.schemaId = schemaId
        self.state = state
        self.traits = traits
    }
}

// MARK: - Internal Parsing

extension OrySession {

    /// Create an `OrySession` from the generated OryClient types.
    static func from(
        session: OryClient.Session,
        token: String
    ) -> OrySession {
        OrySession(
            id: session.id,
            token: token,
            identity: OryIdentity.from(session.identity),
            expiresAt: session.expiresAt,
            authenticatedAt: session.authenticatedAt,
            isActive: session.active ?? false
        )
    }
}

extension OryIdentity {

    /// Create an `OryIdentity` from the generated OryClient `Identity`.
    static func from(_ identity: OryClient.Identity?) -> OryIdentity {
        guard let identity else {
            return OryIdentity(id: "", schemaId: "", state: nil, traits: [:])
        }
        return OryIdentity(
            id: identity.id,
            schemaId: identity.schemaId,
            state: identity.state?.rawValue,
            traits: flattenTraits(identity.traits)
        )
    }

    /// Flatten `JSONValue` traits into a simple `[String: String]` dictionary.
    ///
    /// Only extracts top-level string, number, and boolean values.
    /// Nested objects and arrays are skipped for simplicity.
    private static func flattenTraits(_ traits: OryClient.JSONValue?) -> [String: String] {
        guard let dict = traits?.dictionaryValue else { return [:] }
        var result: [String: String] = [:]
        for (key, value) in dict {
            if let stringValue = NodeParser.jsonValueToString(value) {
                result[key] = stringValue
            }
        }
        return result
    }
}
