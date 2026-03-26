//
//  DynamicFormField.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth
import SwiftUI

/// Renders a single `FormNode` as the appropriate SwiftUI control.
///
/// This is the key component that makes the form server-driven —
/// the UI adapts to whatever fields the Ory API returns.
struct DynamicFormField: View {
    let node: FormNode
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            field
            errorMessages
        }
    }

    @ViewBuilder
    private var field: some View {
        switch node.fieldType {
        case .password:
            SecureField(node.label, text: $value)
                .textContentType(.password)
                .autocorrectionDisabled()

        case .email:
            TextField(node.label, text: $value)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

        case .text:
            TextField(node.label, text: $value)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

        default:
            TextField(node.label, text: $value)
        }
    }

    @ViewBuilder
    private var errorMessages: some View {
        ForEach(node.errorMessages) { message in
            Text(message.text)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}

#Preview("Text field") {
    DynamicFormField(
        node: FormNode(
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
        value: .constant("user@example.com")
    )
    .padding()
}

#Preview("Field with error") {
    DynamicFormField(
        node: FormNode(
            id: "password.password",
            name: "password",
            fieldType: .password,
            group: .password,
            label: "Password",
            isRequired: true,
            isDisabled: false,
            value: nil,
            messages: [
                NodeMessage(id: 4000006, text: "The provided credentials are invalid.", type: .error)
            ],
            autocomplete: "current-password"
        ),
        value: .constant("")
    )
    .padding()
}
