//
//  RegistrationViewModel.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Combine
import OryAuth
import SwiftUI

// MARK: - Implementation

final class RegistrationViewModel: RegistrationViewModelProtocol {

    @Published private(set) var flow: FlowContainer?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?
    
    var fieldValues: [String: String] = [:]
    
    private let authRepository: AuthRepository
    private let onRegistrationSuccess: ValueClosure<OrySession>
    private let onOpenEmailVerification: ValueClosure<OryIdentity>
    private let onDismiss: Closure

    init(
        authRepository: AuthRepository,
        onRegistrationSuccess: @escaping ValueClosure<OrySession>,
        onOpenEmailVerification: @escaping ValueClosure<OryIdentity>,
        onDismiss: @escaping Closure
    ) {
        self.authRepository = authRepository
        self.onRegistrationSuccess = onRegistrationSuccess
        self.onOpenEmailVerification = onOpenEmailVerification
        self.onDismiss = onDismiss
    }

    func loadFlow() async {
        isLoading = true
        errorMessage = nil

        do {
            let container = try await authRepository.initRegistrationFlow()
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
        successMessage = nil

        do {
            let traits = extractTraits()
            let credentials = RegistrationCredentials.password(
                password: fieldValues["password"] ?? "",
                traits: traits
            )
            let result = try await authRepository.submitRegistration(flowId: flow.id, credentials: credentials)

            switch result {
            case .session(let session):
                onRegistrationSuccess(session)
            case .pendingVerification(let identity):
                onOpenEmailVerification(identity)
            }
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    func dismiss() {
        onDismiss()
    }

    // MARK: - Private

    /// Extracts trait values from field inputs.
    ///
    /// Registration forms include fields like `traits.email`, `traits.name.first`.
    /// We strip the `traits.` prefix to build the traits dictionary.
    private func extractTraits() -> [String: String] {
        var traits: [String: String] = [:]
        for (key, value) in fieldValues where key.hasPrefix("traits.") {
            let traitKey = String(key.dropFirst("traits.".count))
            traits[traitKey] = value
        }
        return traits
    }

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

final class RegistrationViewModelFixture: RegistrationViewModelProtocol {

    var flow: FlowContainer?
    var fieldValues: [String: String] = [:]
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?

    func loadFlow() async {}
    func submit() async {}
    func dismiss() {}

    static var withFlow: RegistrationViewModelFixture {
        let fixture = RegistrationViewModelFixture()
        fixture.flow = FlowContainer(
            id: "preview-reg-flow",
            expiresAt: Date().addingTimeInterval(3600),
            nodes: [
                FormNode(
                    id: "default.traits.email",
                    name: "traits.email",
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
                    autocomplete: "new-password"
                ),
                FormNode(
                    id: "password.method",
                    name: "method",
                    fieldType: .submit,
                    group: .password,
                    label: "Sign up",
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
}

#endif
