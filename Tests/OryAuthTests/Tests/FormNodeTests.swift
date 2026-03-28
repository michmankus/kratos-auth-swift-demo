//
//  FormNodeTests.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 28/03/2026.
//

import Testing
@testable import OryAuth

@Suite("FormNode")
struct FormNodeTests {

    @Test func hasErrorsReturnsTrueWhenErrorMessagePresent() {
        let node = FormNode(
            id: "password.password", name: "password", fieldType: .password,
            group: .password, label: "Password", isRequired: true, isDisabled: false,
            value: nil,
            messages: [NodeMessage(id: 4000006, text: "Too short", type: .error)],
            autocomplete: nil
        )
        #expect(node.hasErrors)
    }

    @Test func hasErrorsReturnsFalseWhenOnlyInfoMessages() {
        let node = FormNode(
            id: "default.identifier", name: "identifier", fieldType: .email,
            group: .default, label: "Email", isRequired: true, isDisabled: false,
            value: nil,
            messages: [NodeMessage(id: 1010001, text: "Check your email", type: .info)],
            autocomplete: nil
        )
        #expect(!node.hasErrors)
    }

    @Test func errorMessagesFiltersCorrectly() {
        let node = FormNode(
            id: "password.password", name: "password", fieldType: .password,
            group: .password, label: "Password", isRequired: true, isDisabled: false,
            value: nil,
            messages: [
                NodeMessage(id: 4000006, text: "Too short", type: .error),
                NodeMessage(id: 1010001, text: "Hint: use 8+ chars", type: .info),
                NodeMessage(id: 4000007, text: "Missing number", type: .error),
            ],
            autocomplete: nil
        )
        let errors = node.errorMessages

        #expect(errors.count == 2)
        #expect(errors.allSatisfy { $0.type == .error })
    }

    @Test func identifierCombinesGroupAndName() {
        let node = FormNode(
            id: "password.password", name: "password", fieldType: .password,
            group: .password, label: "Password", isRequired: false, isDisabled: false,
            value: nil, messages: [], autocomplete: nil
        )
        #expect(node.id == "password.password")
    }
}
