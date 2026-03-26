//
//  FormNode.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Foundation

// MARK: - FormNode

/// A platform-native, UI-friendly representation of a single Ory Kratos UI node.
///
/// `FormNode` is the core model that app developers use to dynamically render
/// authentication forms. Each node represents one form element (text field,
/// password field, submit button, hidden value, etc.) as described by the
/// Ory Kratos API response.
///
/// Nodes are parsed from the server-provided `UiNode` objects, so the form
/// is never hardcoded — it adapts to whatever the server returns.
public struct FormNode: Identifiable, Sendable, Hashable {

    /// Unique identifier combining group and field name (e.g. `"password.password"`).
    public let id: String

    /// The field name used when submitting the form (e.g. `"identifier"`, `"password"`, `"method"`).
    public let name: String

    /// The input type of this field, determining how it should be rendered.
    public let fieldType: FieldType

    /// The authentication method group this node belongs to.
    public let group: NodeGroup

    /// Human-readable label for this field (e.g. `"Email"`, `"Password"`, `"Sign in"`).
    public let label: String

    /// Whether this field is required for form submission.
    public let isRequired: Bool

    /// Whether this field is disabled and should not accept user input.
    public let isDisabled: Bool

    /// The current or default value for this field, if any.
    public let value: String?

    /// Validation errors and informational messages attached to this field.
    public let messages: [NodeMessage]

    /// Autocomplete hint for this field (e.g. `"email"`, `"current-password"`).
    public let autocomplete: String?

    public init(
        id: String,
        name: String,
        fieldType: FieldType,
        group: NodeGroup,
        label: String,
        isRequired: Bool,
        isDisabled: Bool,
        value: String?,
        messages: [NodeMessage],
        autocomplete: String?
    ) {
        self.id = id
        self.name = name
        self.fieldType = fieldType
        self.group = group
        self.label = label
        self.isRequired = isRequired
        self.isDisabled = isDisabled
        self.value = value
        self.messages = messages
        self.autocomplete = autocomplete
    }
}

// MARK: - FieldType

/// The input type of a form node, determining how the UI should render it.
///
/// Maps directly from the Ory Kratos `UiNodeInputAttributes.type` values.
public enum FieldType: String, Sendable, Hashable, CaseIterable {
    case text
    case password
    case email
    case hidden
    case submit
    case button
    case checkbox
    case number
    case tel
    case url
    case datetimeLocal = "datetime-local"
    case date
}

// MARK: - NodeGroup

/// The authentication method group a node belongs to.
///
/// Groups organize nodes by their purpose. For example, `"password"` group nodes
/// contain the password field and its submit button, while `"oidc"` group nodes
/// contain social login buttons.
public enum NodeGroup: String, Sendable, Hashable, CaseIterable {
    case `default`
    case password
    case oidc
    case profile
    case link
    case code
    case totp
    case lookupSecret = "lookup_secret"
    case webauthn
    case passkey
    case identifierFirst = "identifier_first"
    case captcha
    case saml
    case oauth2Consent = "oauth2_consent"
}

// MARK: - NodeMessage

/// A validation error or informational message attached to a form node or flow.
///
/// Messages are provided by the Ory Kratos API to communicate per-field
/// validation errors, success confirmations, or informational text.
public struct NodeMessage: Identifiable, Sendable, Hashable {

    /// The Ory message ID (e.g. `4000001` for "account not found").
    public let id: Int64

    /// The human-readable message text.
    public let text: String

    /// The severity of this message.
    public let type: MessageType

    public init(id: Int64, text: String, type: MessageType) {
        self.id = id
        self.text = text
        self.type = type
    }
}

// MARK: - MessageType

/// The severity level of a ``NodeMessage``.
public enum MessageType: String, Sendable, Hashable {
    case error
    case info
    case success
}

// MARK: - Convenience Extensions

extension FormNode {

    /// Whether this node has any error messages.
    public var hasErrors: Bool {
        messages.contains { $0.type == .error }
    }

    /// Only the error messages for this node.
    public var errorMessages: [NodeMessage] {
        messages.filter { $0.type == .error }
    }
}
