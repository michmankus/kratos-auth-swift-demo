//
//  OryAuth.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 25/03/2026.
//

import Foundation

// MARK: - FlowContainer

/// A parsed authentication flow containing all the form nodes needed for rendering.
///
/// `FlowContainer` wraps the raw Ory Kratos flow response into a clean,
/// UI-ready model. App developers use this to dynamically build authentication
/// forms driven entirely by the server response.
///
/// - Note: The form is never hardcoded. The `nodes` array contains exactly
///   what the server says should be rendered, including fields, buttons,
///   and hidden values.
public struct FlowContainer: Sendable {

    /// The unique flow identifier. Pass this to `submitLogin(flowId:values:)`.
    public let id: String

    /// When this flow expires and must be re-initialized.
    public let expiresAt: Date

    /// All parsed form nodes in this flow.
    public let nodes: [FormNode]

    /// Flow-level messages (e.g. "The provided credentials are invalid").
    public let messages: [NodeMessage]

    /// The action URL this flow submits to (for reference/debugging).
    public let actionURL: String

    public init(
        id: String,
        expiresAt: Date,
        nodes: [FormNode],
        messages: [NodeMessage],
        actionURL: String
    ) {
        self.id = id
        self.expiresAt = expiresAt
        self.nodes = nodes
        self.messages = messages
        self.actionURL = actionURL
    }
}

// MARK: - Convenience

extension FlowContainer {

    /// Nodes that should be rendered visibly to the user (excludes hidden fields).
    public var visibleFields: [FormNode] {
        nodes.filter { $0.fieldType != .hidden }
    }

    /// Hidden nodes whose values must be submitted but not displayed.
    public var hiddenFields: [FormNode] {
        nodes.filter { $0.fieldType == .hidden }
    }

    /// Submit button nodes.
    public var submitNodes: [FormNode] {
        nodes.filter { $0.fieldType == .submit || $0.fieldType == .button }
    }

    /// The distinct authentication method groups that have visible nodes in this flow.
    public var availableGroups: [NodeGroup] {
        let groups = Set(visibleFields.map(\.group))
        return Array(groups).sorted { $0.rawValue < $1.rawValue }
    }

    /// Filter nodes belonging to a specific group.
    public func nodes(for group: NodeGroup) -> [FormNode] {
        nodes.filter { $0.group == group }
    }

    /// Whether this flow has expired.
    public var isExpired: Bool {
        expiresAt < Date()
    }

    /// Whether this flow has any error messages (flow-level or field-level).
    public var hasErrors: Bool {
        messages.contains { $0.type == .error } || nodes.contains { $0.hasErrors }
    }
}
