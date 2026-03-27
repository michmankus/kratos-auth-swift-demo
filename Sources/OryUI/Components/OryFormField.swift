//
//  OryFormField.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth
import SwiftUI

// MARK: - OryFormField

/// Renders a single ``FormNode`` as the appropriate native SwiftUI control.
///
/// This is the core component that makes forms server-driven — the UI
/// adapts to whatever fields the Ory Kratos API returns. Each ``FieldType``
/// maps to an optimized native control with the correct keyboard, content
/// type, and accessibility configuration.
///
/// ```swift
/// ForEach(flow.visibleFields) { node in
///     OryFormField(node: node, value: $fieldValues[node.name])
/// }
/// ```
///
/// ## Supported field types
///
/// | FieldType       | SwiftUI Control | Keyboard / Content Type           |
/// |-----------------|-----------------|-----------------------------------|
/// | `.email`        | `TextField`     | `.emailAddress` / `.emailAddress`  |
/// | `.password`     | `SecureField`   | — / `.password`                    |
/// | `.text`         | `TextField`     | `.default`                         |
/// | `.number`       | `TextField`     | `.numberPad`                       |
/// | `.tel`          | `TextField`     | `.phonePad` / `.telephoneNumber`   |
/// | `.url`          | `TextField`     | `.URL` / `.URL`                    |
/// | `.checkbox`     | `Toggle`        | —                                  |
/// | `.date`         | `TextField`     | `.default` (placeholder hint)      |
/// | `.datetimeLocal` | `TextField`    | `.default` (placeholder hint)      |
/// | `.hidden`       | `EmptyView`     | — (not rendered)                   |
/// | `.submit`       | `EmptyView`     | — (use ``OrySubmitButton``)        |
/// | `.button`       | `EmptyView`     | — (use ``OrySubmitButton``)        |
public struct OryFormField: View {

    /// The form node describing this field.
    public let node: FormNode

    /// Two-way binding to the field's current value.
    @Binding public var value: String

    public init(node: FormNode, value: Binding<String>) {
        self.node = node
        self._value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            field
            OryNodeMessages(messages: node.messages)
        }
        .disabled(node.isDisabled)
        .opacity(node.isDisabled ? 0.5 : 1.0)
    }

    // MARK: - Field Rendering

    @ViewBuilder
    private var field: some View {
        switch node.fieldType {
        case .password:
            SecureField(fieldLabel, text: $value)
                #if os(iOS)
                .textContentType(.password)
                #endif
                .autocorrectionDisabled()

        case .email:
            TextField(fieldLabel, text: $value)
                #if os(iOS)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()

        case .number:
            TextField(fieldLabel, text: $value)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif

        case .tel:
            TextField(fieldLabel, text: $value)
                #if os(iOS)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
                #endif

        case .url:
            TextField(fieldLabel, text: $value)
                #if os(iOS)
                .textContentType(.URL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()

        case .checkbox:
            Toggle(fieldLabel, isOn: checkboxBinding)

        case .text:
            TextField(fieldLabel, text: $value)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()

        case .date, .datetimeLocal:
            TextField(fieldLabel, text: $value)

        case .hidden, .submit, .button:
            EmptyView()
        }
    }

    // MARK: - Helpers

    /// Label with a required indicator when the field is mandatory.
    private var fieldLabel: String {
        node.isRequired ? "\(node.label) *" : node.label
    }

    /// Bridges a `String` binding to a `Bool` binding for checkboxes.
    private var checkboxBinding: Binding<Bool> {
        Binding(
            get: { value == "true" },
            set: { value = $0 ? "true" : "false" }
        )
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Email field") {
    OryFormField(
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

#Preview("Password with error") {
    OryFormField(
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

#Preview("Disabled field") {
    OryFormField(
        node: FormNode(
            id: "default.identifier",
            name: "identifier",
            fieldType: .email,
            group: .default,
            label: "Email",
            isRequired: false,
            isDisabled: true,
            value: nil,
            messages: [],
            autocomplete: "email"
        ),
        value: .constant("locked@example.com")
    )
    .padding()
}

#Preview("Checkbox") {
    OryFormField(
        node: FormNode(
            id: "default.remember",
            name: "remember",
            fieldType: .checkbox,
            group: .default,
            label: "Remember me",
            isRequired: false,
            isDisabled: false,
            value: "false",
            messages: [],
            autocomplete: nil
        ),
        value: .constant("false")
    )
    .padding()
}

#Preview("Phone field") {
    OryFormField(
        node: FormNode(
            id: "default.phone",
            name: "phone",
            fieldType: .tel,
            group: .default,
            label: "Phone number",
            isRequired: false,
            isDisabled: false,
            value: nil,
            messages: [],
            autocomplete: "tel"
        ),
        value: .constant("")
    )
    .padding()
}

#endif
