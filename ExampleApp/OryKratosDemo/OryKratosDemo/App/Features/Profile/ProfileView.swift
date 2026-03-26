//
//  ProfileView.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth
import SwiftUI

struct ProfileView<ViewModel: ProfileViewModelProtocol>: View {
    
    @StateObject private var viewModel: ViewModel
    
    init(viewModel: @autoclosure @escaping ReturnClosure<ViewModel>) {
        _viewModel = .init(wrappedValue: viewModel())
    }

    var body: some View {
        VStack {
            switch viewModel.state {
            case .sessionLoaded(let orySession):
                sessionInfoView(orySession)
            case .sessionNotLoaded:
                sessionNotLoadedView
            }
        }
        .navigationTitle("Profile")
        .task { await viewModel.onTask() }
    }
    
    // MARK: - MainView
    
    private func sessionInfoView(_ session: OrySession) -> some View {
        List {
            sessionSection(session)
            traitsSection(session)
            logoutSection
        }
        
    }
    
    private var sessionNotLoadedView: some View {
        Text("Session not loaded")
            .foregroundStyle(.secondary)
    }

    // MARK: - Sections

    private func sessionSection(_ session: OrySession) -> some View {
        Section("Session") {
            LabeledContent("Session ID", value: session.id)
            LabeledContent("Active", value: session.isActive ? "Yes" : "No")

            if let expiresAt = session.expiresAt {
                LabeledContent("Expires", value: expiresAt.formatted())
            }
        }
    }

    private func traitsSection(_ session: OrySession) -> some View {
        Section("Identity Traits") {
            let traits = session.identity.traits

            if traits.isEmpty {
                Text("No traits available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(traits.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    LabeledContent(key.capitalized, value: value)
                }
            }
        }
    }

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                Task {
                    await viewModel.logout()
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Log out")
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.isLoading)
        }
    }
}

#if DEBUG

#Preview {
    NavigationStack {
        ProfileView(viewModel: ProfileViewModelFixture())
    }
}

#endif
