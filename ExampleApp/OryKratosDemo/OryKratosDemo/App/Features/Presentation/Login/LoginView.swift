//
//  LoginView.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth
import SwiftUI

/// Dynamically renders a login form from server-provided UI nodes.
///
/// No fields are hardcoded — the form adapts to whatever the Ory API returns.
struct LoginView<ViewModel: LoginViewModelProtocol>: View {
    @Bindable var viewModel: ViewModel
    let onRegisterTap: () -> Void

    var body: some View {
        Form {
            if let flow = viewModel.flow {
                flowMessages(flow)
                inputFields(flow)
                submitSection(flow)
            }

            registrationLink
        }
        .navigationTitle("Sign In")
        .overlay { loadingOverlay }
        .task { await viewModel.loadFlow() }
    }

    // MARK: - Sections

    @ViewBuilder
    private func flowMessages(_ flow: FlowContainer) -> some View {
        if let errorMessage = viewModel.errorMessage {
            Section {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private func inputFields(_ flow: FlowContainer) -> some View {
        let visibleInputs = flow.visibleFields.filter { $0.fieldType != .submit && $0.fieldType != .button }

        if !visibleInputs.isEmpty {
            Section {
                ForEach(visibleInputs) { node in
                    DynamicFormField(
                        node: node,
                        value: binding(for: node.name)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func submitSection(_ flow: FlowContainer) -> some View {
        Section {
            Button {
                Task { await viewModel.submit() }
            } label: {
                HStack {
                    Spacer()
                    Text(flow.submitNodes.first?.label ?? "Sign in")
                    Spacer()
                }
            }
            .disabled(viewModel.isLoading)
        }
    }

    private var registrationLink: some View {
        Section {
            Button("Don't have an account? Register") {
                onRegisterTap()
            }
        }
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isLoading && viewModel.flow == nil {
            ProgressView("Loading...")
        }
    }

    // MARK: - Helpers

    private func binding(for fieldName: String) -> Binding<String> {
        Binding(
            get: { viewModel.fieldValues[fieldName] ?? "" },
            set: { viewModel.fieldValues[fieldName] = $0 }
        )
    }
}

#Preview("Login") {
    NavigationStack {
        LoginView(
            viewModel: LoginViewModelFixture.withFlow,
            onRegisterTap: {}
        )
    }
}

#Preview("Login with error") {
    NavigationStack {
        LoginView(
            viewModel: LoginViewModelFixture.withError,
            onRegisterTap: {}
        )
    }
}
