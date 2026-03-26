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

    private let repository: AuthRepository
    private let onLoginSuccess: ValueClosure<OrySession>
    private let onDismiss: Closure

    init(
        repository: AuthRepository,
        onLoginSuccess: @escaping ValueClosure<OrySession>,
        onDismiss: @escaping Closure
    ) {
        self.repository = repository
        self.onLoginSuccess = onLoginSuccess
        self.onDismiss = onDismiss
    }

    func loadFlow() async {
        isLoading = true
        errorMessage = nil

        do {
            let container = try await repository.initLoginFlow()
            flow = container
            prefillHiddenFields(from: container)
        } catch {
            errorMessage = describeError(error)
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
            let session = try await repository.submitLogin(flowId: flow.id, credentials: credentials)
            onLoginSuccess(session)
        } catch let error as OryError {
            handleOryError(error)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    func dismiss() {
        onDismiss()
    }

    // MARK: - Private

    private func prefillHiddenFields(from container: FlowContainer) {
        for node in container.hiddenFields {
            if let value = node.value {
                fieldValues[node.name] = value
            }
        }
    }

    private func handleOryError(_ error: OryError) {
        switch error {
        case .validation(let updatedFlow):
            flow = updatedFlow
            errorMessage = updatedFlow.messages.first(where: { $0.type == .error })?.text
        case .flowExpired:
            errorMessage = "Session expired. Loading a new form..."
            Task { await loadFlow() }
        case .network:
            errorMessage = "Network error. Please check your connection."
        case .sessionAlreadyAvailable:
            errorMessage = "You are already logged in."
        case .missingSessionToken:
            errorMessage = "Login succeeded but no session was created. Please try again."
        case .unauthorized:
            errorMessage = "Unauthorized."
        case .unknown(_, let message):
            errorMessage = message ?? "An unexpected error occurred."
        }
    }

    private func describeError(_ error: Error) -> String {
        if let oryError = error as? OryError {
            handleOryError(oryError)
            return errorMessage ?? "Unknown error"
        }
        return error.localizedDescription
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
