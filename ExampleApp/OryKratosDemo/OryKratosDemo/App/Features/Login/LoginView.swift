//
//  LoginView.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth
import SwiftUI

struct LoginView<ViewModel: LoginViewModelProtocol>: View {
    
    @StateObject private var viewModel: ViewModel
    
    init(viewModel: @autoclosure @escaping ReturnClosure<ViewModel>) {
        _viewModel = .init(wrappedValue: viewModel())
    }

    var body: some View {
        Form {
            if let flow = viewModel.flow {
                flowMessages(flow)
                inputFields(flow)
                submitSection(flow)
            }
        }
        .navigationTitle("Sign In")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                dismissButton
            }
        }
        .overlay { loadingOverlay }
        .task { await viewModel.loadFlow() }
    }
    
    private var dismissButton: some View {
        Button(
            action: {
                viewModel.dismiss()
            }, label: {
                Image(systemName: "xmark")
            }
        )
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
            viewModel: LoginViewModelFixture.withFlow
        )
    }
}

#Preview("Login with error") {
    NavigationStack {
        LoginView(
            viewModel: LoginViewModelFixture.withError
        )
    }
}
