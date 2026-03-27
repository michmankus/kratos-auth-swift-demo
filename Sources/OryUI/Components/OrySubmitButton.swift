//
//  OrySubmitButton.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth
import SwiftUI

// MARK: - OrySubmitButton

/// A server-driven submit button rendered from the flow's submit nodes.
///
/// The label text comes from the Ory Kratos API response, so it adapts
/// to the configured flow (e.g. "Sign in", "Sign up", "Continue").
/// Shows a loading indicator while the form is being submitted.
///
/// ```swift
/// OrySubmitButton(
///     flow: flow,
///     isLoading: viewModel.isLoading,
///     action: { await viewModel.submit() }
/// )
/// ```
public struct OrySubmitButton: View {

    /// The current flow container, used to read the submit node label.
    public let flow: FlowContainer

    /// Whether the form is currently being submitted.
    public let isLoading: Bool

    /// The fallback label when no submit node is present.
    public let fallbackLabel: String

    /// The action to perform when the button is tapped.
    public let action: () async -> Void

    public init(
        flow: FlowContainer,
        isLoading: Bool,
        fallbackLabel: String = "Submit",
        action: @escaping () async -> Void
    ) {
        self.flow = flow
        self.isLoading = isLoading
        self.fallbackLabel = fallbackLabel
        self.action = action
    }

    public var body: some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(flow.submitNodes.first?.label ?? fallbackLabel)
                }
                Spacer()
            }
        }
        .disabled(isLoading)
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Submit button") {
    OrySubmitButton(
        flow: FlowContainer(
            id: "preview",
            expiresAt: .distantFuture,
            nodes: [
                FormNode(
                    id: "password.method",
                    name: "method",
                    fieldType: .submit,
                    group: .password,
                    label: "Sign in",
                    isRequired: false,
                    isDisabled: false,
                    value: "password",
                    messages: [],
                    autocomplete: nil
                )
            ],
            messages: [],
            actionURL: ""
        ),
        isLoading: false,
        action: {}
    )
    .padding()
}

#Preview("Loading state") {
    OrySubmitButton(
        flow: FlowContainer(
            id: "preview",
            expiresAt: .distantFuture,
            nodes: [],
            messages: [],
            actionURL: ""
        ),
        isLoading: true,
        action: {}
    )
    .padding()
}

#endif
