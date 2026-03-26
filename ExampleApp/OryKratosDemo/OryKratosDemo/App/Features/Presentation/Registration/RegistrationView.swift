//
//  RegistrationView.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth
import SwiftUI

struct RegistrationView<ViewModel: RegistrationViewModelProtocol>: View {

    @StateObject private var viewModel: ViewModel
    
    init(viewModel: @autoclosure @escaping ReturnClosure<ViewModel>) {
        _viewModel = .init(wrappedValue: viewModel())
    }

    var body: some View {
        Form {
            if let flow = viewModel.flow {
                errorSection
                successSection
                inputFields(flow)
                submitSection(flow)
            }
        }
        .navigationTitle("Register")
        .overlay { loadingOverlay }
        .task { await viewModel.loadFlow() }
    }

    // MARK: - Sections

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage = viewModel.errorMessage {
            Section {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var successSection: some View {
        if let successMessage = viewModel.successMessage {
            Section {
                Text(successMessage)
                    .foregroundStyle(.green)
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
                    Text(flow.submitNodes.first?.label ?? "Sign up")
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

#Preview {
    NavigationStack {
        RegistrationView(viewModel: RegistrationViewModelFixture.withFlow)
    }
}
