//
//  DynamicFormField.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth
import OryUI
import SwiftUI

/// Renders a single `FormNode` as the appropriate SwiftUI control.
///
/// Thin wrapper around ``OryFormField`` from the `OryUI` module,
/// demonstrating how the SDK's ready-to-use components integrate
/// into a consumer app.
struct DynamicFormField: View {
    let node: FormNode
    @Binding var value: String

    var body: some View {
        OryFormField(node: node, value: $value)
    }
}

#if DEBUG

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

#endif
