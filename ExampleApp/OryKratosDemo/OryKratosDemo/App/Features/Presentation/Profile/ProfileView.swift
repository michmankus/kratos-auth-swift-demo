//
//  ProfileView.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth
import SwiftUI

/// Displays the authenticated user's profile information from the session.
struct ProfileView<ViewModel: ProfileViewModelProtocol>: View {
    @Bindable var viewModel: ViewModel

    var body: some View {
        List {
            sessionSection
            traitsSection
            logoutSection
        }
        .navigationTitle("Profile")
    }

    // MARK: - Sections

    private var sessionSection: some View {
        Section("Session") {
            LabeledContent("Session ID", value: viewModel.session.id)
            LabeledContent("Active", value: viewModel.session.isActive ? "Yes" : "No")

            if let expiresAt = viewModel.session.expiresAt {
                LabeledContent("Expires", value: expiresAt.formatted())
            }
        }
    }

    private var traitsSection: some View {
        Section("Identity Traits") {
            let traits = viewModel.session.identity.traits

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
                Task { await viewModel.logout() }
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

#Preview {
    NavigationStack {
        ProfileView(viewModel: ProfileViewModelFixture())
    }
}
