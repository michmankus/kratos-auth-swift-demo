//
//  OryFlowForm.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth
import SwiftUI

// MARK: - OryFlowForm

/// A complete, server-driven form rendered from an Ory Kratos ``FlowContainer``.
///
/// Combines ``OryNodeMessages``, ``OryFormField``, and ``OrySubmitButton``
/// into a single drop-in component. Designed to be placed inside a SwiftUI
/// `Form` or `List` — it renders `Section` blocks for messages, fields,
/// and the submit action.
///
/// For full customization, use the individual components directly instead.
///
/// ```swift
/// Form {
///     OryFlowForm(
///         flow: flow,
///         fieldValues: $fieldValues,
///         isLoading: isLoading,
///         submitLabel: "Sign in"
///     ) {
///         await viewModel.submit()
///     }
/// }
/// ```
public struct OryFlowForm: View {

    /// The flow containing all parsed nodes to render.
    public let flow: FlowContainer

    /// Two-way binding to the dictionary of field name → current value.
    @Binding public var fieldValues: [String: String]

    /// Whether the form is currently being submitted.
    public let isLoading: Bool

    /// Fallback label for the submit button if no submit node exists.
    public let submitLabel: String

    /// Optional error message to display above the form (e.g. from ViewModel).
    public let errorMessage: String?

    /// Optional success message to display above the form.
    public let successMessage: String?

    /// The action to perform on submit.
    public let onSubmit: () async -> Void

    public init(
        flow: FlowContainer,
        fieldValues: Binding<[String: String]>,
        isLoading: Bool,
        submitLabel: String = "Submit",
        errorMessage: String? = nil,
        successMessage: String? = nil,
        onSubmit: @escaping () async -> Void
    ) {
        self.flow = flow
        self._fieldValues = fieldValues
        self.isLoading = isLoading
        self.submitLabel = submitLabel
        self.errorMessage = errorMessage
        self.successMessage = successMessage
        self.onSubmit = onSubmit
    }

    public var body: some View {
        messagesSection
        fieldsSection
        submitSection
    }

    // MARK: - Sections

    @ViewBuilder
    private var messagesSection: some View {
        if let errorMessage {
            Section {
                Label {
                    Text(errorMessage)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                }
                .foregroundStyle(.red)
            }
        }

        if let successMessage {
            Section {
                Label {
                    Text(successMessage)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .foregroundStyle(.green)
            }
        }

        if !flow.messages.isEmpty {
            Section {
                OryNodeMessages(messages: flow.messages)
            }
        }
    }

    @ViewBuilder
    private var fieldsSection: some View {
        let inputNodes = flow.visibleFields.filter {
            $0.fieldType != .submit && $0.fieldType != .button
        }

        if !inputNodes.isEmpty {
            Section {
                ForEach(inputNodes) { node in
                    OryFormField(
                        node: node,
                        value: binding(for: node.name)
                    )
                }
            }
        }
    }

    private var submitSection: some View {
        Section {
            OrySubmitButton(
                flow: flow,
                isLoading: isLoading,
                fallbackLabel: submitLabel,
                action: onSubmit
            )
        }
    }

    // MARK: - Helpers

    private func binding(for fieldName: String) -> Binding<String> {
        Binding(
            get: { fieldValues[fieldName] ?? "" },
            set: { fieldValues[fieldName] = $0 }
        )
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Login form") {
    Form {
        OryFlowForm(
            flow: FlowContainer(
                id: "preview-login",
                expiresAt: .distantFuture,
                nodes: [
                    FormNode(
                        id: "default.identifier",
                        name: "identifier",
                        fieldType: .email,
                        group: .default,
                        label: "Email",
                        isRequired: true,
                        isDisabled: false,
                        value: nil,
                        messages: [],
                        autocomplete: "email"
                    ),
                    FormNode(
                        id: "password.password",
                        name: "password",
                        fieldType: .password,
                        group: .password,
                        label: "Password",
                        isRequired: true,
                        isDisabled: false,
                        value: nil,
                        messages: [],
                        autocomplete: "current-password"
                    ),
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
            fieldValues: .constant(["identifier": "user@example.com"]),
            isLoading: false,
            submitLabel: "Sign in",
            onSubmit: {}
        )
    }
}

#Preview("Form with errors") {
    Form {
        OryFlowForm(
            flow: FlowContainer(
                id: "preview-error",
                expiresAt: .distantFuture,
                nodes: [
                    FormNode(
                        id: "default.identifier",
                        name: "identifier",
                        fieldType: .email,
                        group: .default,
                        label: "Email",
                        isRequired: true,
                        isDisabled: false,
                        value: nil,
                        messages: [],
                        autocomplete: "email"
                    ),
                    FormNode(
                        id: "password.password",
                        name: "password",
                        fieldType: .password,
                        group: .password,
                        label: "Password",
                        isRequired: true,
                        isDisabled: false,
                        value: nil,
                        messages: [
                            NodeMessage(
                                id: 4000006,
                                text: "The provided credentials are invalid.",
                                type: .error
                            )
                        ],
                        autocomplete: "current-password"
                    ),
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
            fieldValues: .constant([:]),
            isLoading: false,
            submitLabel: "Sign in",
            errorMessage: "The provided credentials are invalid.",
            onSubmit: {}
        )
    }
}

#endif
