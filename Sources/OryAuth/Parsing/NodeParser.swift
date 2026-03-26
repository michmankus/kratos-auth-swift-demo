//
//  OryAuth.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 25/03/2026.
//

import Foundation
import OryClient

// MARK: - NodeParser

/// Internal parser that converts generated OryClient types into
/// the SDK's platform-native models.
///
/// This is the bridge between the raw OpenAPI-generated types and
/// the clean, UI-friendly `FormNode` / `FlowContainer` models.
enum NodeParser {

    // MARK: - Flow Parsing

    /// Parse a raw `LoginFlow` from OryClient into a `FlowContainer`.
    static func parseLoginFlow(_ raw: OryClient.LoginFlow) -> FlowContainer {
        FlowContainer(
            id: raw.id,
            expiresAt: raw.expiresAt,
            nodes: parseNodes(from: raw.ui.nodes),
            messages: parseMessages(from: raw.ui.messages),
            actionURL: raw.ui.action
        )
    }

    /// Parse a raw `RegistrationFlow` from OryClient into a `FlowContainer`.
    static func parseRegistrationFlow(_ raw: OryClient.RegistrationFlow) -> FlowContainer {
        FlowContainer(
            id: raw.id,
            expiresAt: raw.expiresAt,
            nodes: parseNodes(from: raw.ui.nodes),
            messages: parseMessages(from: raw.ui.messages),
            actionURL: raw.ui.action
        )
    }

    // MARK: - Node Parsing

    /// Parse an array of raw `UiNode` objects into `FormNode` models.
    ///
    /// Only input-type nodes are parsed. Other node types (text, image,
    /// script, anchor, div) are skipped as they are not needed for
    /// form rendering in a native mobile context.
    static func parseNodes(from uiNodes: [OryClient.UiNode]) -> [FormNode] {
        uiNodes.compactMap { parseNode($0) }
    }

    /// Parse a single `UiNode` into a `FormNode`, or `nil` if it's not an input node.
    private static func parseNode(_ node: OryClient.UiNode) -> FormNode? {
        // Only process input-type nodes
        guard case .typeUiNodeInputAttributes(let attributes) = node.attributes else {
            return nil
        }

        let group = mapGroup(node.group)
        let fieldType = mapFieldType(attributes.type)
        let label = resolveLabel(node: node, attributes: attributes)

        return FormNode(
            id: "\(group.rawValue).\(attributes.name)",
            name: attributes.name,
            fieldType: fieldType,
            group: group,
            label: label,
            isRequired: attributes._required ?? false,
            isDisabled: attributes.disabled,
            value: jsonValueToString(attributes.value),
            messages: parseMessages(from: node.messages),
            autocomplete: attributes.autocomplete?.rawValue
        )
    }

    // MARK: - Message Parsing

    /// Parse an array of `UiText` into `NodeMessage` models.
    static func parseMessages(from uiTexts: [OryClient.UiText]?) -> [NodeMessage] {
        guard let uiTexts else { return [] }
        return uiTexts.map { parseMessage($0) }
    }

    /// Parse an array of `UiText` (non-optional) into `NodeMessage` models.
    static func parseMessages(from uiTexts: [OryClient.UiText]) -> [NodeMessage] {
        uiTexts.map { parseMessage($0) }
    }

    private static func parseMessage(_ text: OryClient.UiText) -> NodeMessage {
        NodeMessage(
            id: text.id,
            text: text.text,
            type: mapMessageType(text.type)
        )
    }

    // MARK: - Type Mapping

    /// Map the generated `UiNode.Group` enum to our `NodeGroup`.
    private static func mapGroup(_ group: OryClient.UiNode.Group) -> NodeGroup {
        switch group {
        case ._default: .default
        case .password: .password
        case .oidc: .oidc
        case .profile: .profile
        case .link: .link
        case .code: .code
        case .totp: .totp
        case .lookupSecret: .lookupSecret
        case .webauthn: .webauthn
        case .passkey: .passkey
        case .identifierFirst: .identifierFirst
        case .captcha: .captcha
        case .saml: .saml
        case .oauth2Consent: .oauth2Consent
        }
    }

    /// Map the generated `UiNodeInputAttributes.ModelType` to our `FieldType`.
    private static func mapFieldType(_ type: OryClient.UiNodeInputAttributes.ModelType) -> FieldType {
        switch type {
        case .text: .text
        case .password: .password
        case .email: .email
        case .hidden: .hidden
        case .submit: .submit
        case .button: .button
        case .checkbox: .checkbox
        case .number: .number
        case .tel: .tel
        case .url: .url
        case .datetimeLocal: .datetimeLocal
        case .date: .date
        }
    }

    /// Map the generated `UiText.ModelType` to our `MessageType`.
    private static func mapMessageType(_ type: OryClient.UiText.ModelType) -> MessageType {
        switch type {
        case .error: .error
        case .info: .info
        case .success: .success
        }
    }

    // MARK: - Label Resolution

    /// Resolve the best human-readable label for a node.
    ///
    /// Priority:
    /// 1. `node.meta.label.text` — the server-provided label
    /// 2. `attributes.label.text` — fallback from input attributes
    /// 3. `attributes.name` — last resort, use the field name itself
    private static func resolveLabel(
        node: OryClient.UiNode,
        attributes: OryClient.UiNodeInputAttributes
    ) -> String {
        if let metaLabel = node.meta.label?.text, !metaLabel.isEmpty {
            return metaLabel
        }
        if let attrLabel = attributes.label?.text, !attrLabel.isEmpty {
            return attrLabel
        }
        return attributes.name
    }

    // MARK: - Value Conversion

    /// Convert a `JSONValue` to a `String` representation.
    ///
    /// Ory uses `JSONValue` for field values which can be strings, numbers,
    /// booleans, etc. We flatten to `String?` for simple form binding.
    static func jsonValueToString(_ value: OryClient.JSONValue?) -> String? {
        guard let value else { return nil }
        switch value {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return String(b)
        case .null: return nil
        case .array, .dictionary: return nil
        }
    }
}
