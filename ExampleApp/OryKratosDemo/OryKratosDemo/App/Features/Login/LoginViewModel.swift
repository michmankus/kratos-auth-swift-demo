//
//  LoginViewModel.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Combine
import OryAuth
import SwiftUI

final class LoginViewModel: LoginViewModelProtocol {

    @Published private(set) var flow: FlowContainer?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    var fieldValues: [String: String] = [:]

    private let authRepository: AuthRepository
    private let onLoginSuccess: ValueClosure<OrySession>
    private let onDismiss: Closure

    init(
        authRepository: AuthRepository,
        onLoginSuccess: @escaping ValueClosure<OrySession>,
        onDismiss: @escaping Closure
    ) {
        self.authRepository = authRepository
        self.onLoginSuccess = onLoginSuccess
        self.onDismiss = onDismiss
    }

    func loadFlow() async {
        isLoading = true
        errorMessage = nil

        do {
            let container = try await authRepository.initLoginFlow()
            flow = container
            fieldValues.merge(container.hiddenFieldValues) { _, new in new }
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    func submit() async {
        guard let flow else { return }

        isLoading = true
        errorMessage = nil

        do {
            let credentials = LoginCredentials.password(
                identifier: fieldValues["identifier"] ?? "",
                password: fieldValues["password"] ?? ""
            )
            let session = try await authRepository.submitLogin(flowId: flow.id, credentials: credentials)
            onLoginSuccess(session)
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    func dismiss() {
        onDismiss()
    }

    // MARK: - Private

    private func handleError(_ error: Error) {
        let result = UserFacingOryErrorMapper.map(error)
        errorMessage = result.message

        if let updatedFlow = result.updatedFlow {
            flow = updatedFlow
        }

        if case .reloadFlow = result.action {
            Task { await loadFlow() }
        }
    }
}

#if DEBUG

// MARK: - Fixture

final class LoginViewModelFixture: LoginViewModelProtocol {

    var flow: FlowContainer?
    var fieldValues: [String: String] = ["identifier": "user@example.com"]
    var isLoading = false
    var errorMessage: String?

    func loadFlow() async {}
    func submit() async {}
    func dismiss() {}

    static var withFlow: LoginViewModelFixture {
        let fixture = LoginViewModelFixture()
        fixture.flow = FlowContainer(
            id: "preview-flow",
            expiresAt: Date().addingTimeInterval(3600),
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
                ),
            ],
            messages: [],
            actionURL: "https://example.com"
        )
        return fixture
    }

    static var withError: LoginViewModelFixture {
        let fixture = LoginViewModelFixture.withFlow
        fixture.errorMessage = "The provided credentials are invalid."
        return fixture
    }
}

#endif
