//
//  FlowContainerTests.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 28/03/2026.
//

import Foundation
import Testing
@testable import OryAuth

@Suite("FlowContainer")
struct FlowContainerTests {

    private let sampleNodes = [
        FormNode(id: "default.identifier", name: "identifier", fieldType: .email, group: .default, label: "Email", isRequired: true, isDisabled: false, value: nil, messages: [], autocomplete: "email"),
        FormNode(id: "password.password", name: "password", fieldType: .password, group: .password, label: "Password", isRequired: true, isDisabled: false, value: nil, messages: [], autocomplete: "current-password"),
        FormNode(id: "default.csrf_token", name: "csrf_token", fieldType: .hidden, group: .default, label: "csrf_token", isRequired: false, isDisabled: false, value: "abc123", messages: [], autocomplete: nil),
        FormNode(id: "password.method", name: "method", fieldType: .submit, group: .password, label: "Sign in", isRequired: false, isDisabled: false, value: "password", messages: [], autocomplete: nil),
    ]

    private func makeFlow(
        messages: [NodeMessage] = [],
        expiresAt: Date = .distantFuture
    ) -> FlowContainer {
        FlowContainer(
            id: "flow-1",
            expiresAt: expiresAt,
            nodes: sampleNodes,
            messages: messages,
            actionURL: "https://example.com/self-service/login"
        )
    }

    @Test func visibleFieldsExcludesHidden() {
        let flow = makeFlow()
        let visible = flow.visibleFields

        #expect(visible.count == 3)
        #expect(!visible.contains { $0.fieldType == .hidden })
    }

    @Test func hiddenFieldsReturnsOnlyHidden() {
        let flow = makeFlow()
        let hidden = flow.hiddenFields

        #expect(hidden.count == 1)
        #expect(hidden.first?.name == "csrf_token")
    }

    @Test func submitNodesReturnsSubmitAndButton() {
        let flow = makeFlow()
        let submits = flow.submitNodes

        #expect(submits.count == 1)
        #expect(submits.first?.label == "Sign in")
    }

    @Test func availableGroupsReturnsDistinctSortedGroups() {
        let flow = makeFlow()
        let groups = flow.availableGroups

        #expect(groups.contains(.default))
        #expect(groups.contains(.password))
    }

    @Test func nodesForGroupFiltersCorrectly() {
        let flow = makeFlow()
        let passwordNodes = flow.nodes(for: NodeGroup.password)

        #expect(passwordNodes.count == 2)
        #expect(passwordNodes.allSatisfy { $0.group == NodeGroup.password })
    }

    @Test func isExpiredReturnsTrueForPastDate() {
        let flow = makeFlow(expiresAt: Date.distantPast)
        #expect(flow.isExpired)
    }

    @Test func isExpiredReturnsFalseForFutureDate() {
        let flow = makeFlow(expiresAt: Date.distantFuture)
        #expect(!flow.isExpired)
    }

    @Test func hasErrorsDetectsFlowLevelErrors() {
        let flow = makeFlow(messages: [
            NodeMessage(id: 4000001, text: "Account not found", type: .error)
        ])
        #expect(flow.hasErrors)
    }

    @Test func hasErrorsReturnsFalseWhenClean() {
        let flow = makeFlow()
        #expect(!flow.hasErrors)
    }
}
