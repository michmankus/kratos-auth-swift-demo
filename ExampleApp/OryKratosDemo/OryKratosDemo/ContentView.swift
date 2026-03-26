//
//  ContentView.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 25/03/2026.
//

import OryAuth
import SwiftUI

/// Root view that switches between login and profile based on auth state.
///
/// Uses an `@Observable` `AppState` to drive navigation. ViewModels are
/// created here with the shared `AuthRepository` dependency.
struct ContentView: View {
    @State private var appState = AppState()

    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    var body: some View {
        NavigationStack {
            Group {
                switch appState.screen {
                case .login:
                    LoginView(
                        viewModel: makeLoginViewModel(),
                        onRegisterTap: { appState.screen = .registration }
                    )

                case .registration:
                    RegistrationView(viewModel: makeRegistrationViewModel())
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Back to Login") { appState.screen = .login }
                            }
                        }

                case .profile(let session):
                    ProfileView(viewModel: makeProfileViewModel(session: session))
                }
            }
        }
        .task { await checkExistingSession() }
    }

    // MARK: - Factory Methods

    private func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(repository: repository) { session in
            appState.screen = .profile(session)
        }
    }

    private func makeRegistrationViewModel() -> RegistrationViewModel {
        RegistrationViewModel(repository: repository) { session in
            appState.screen = .profile(session)
        }
    }

    private func makeProfileViewModel(session: OrySession) -> ProfileViewModel {
        ProfileViewModel(session: session, repository: repository) {
            appState.screen = .login
        }
    }

    // MARK: - Session Check

    private func checkExistingSession() async {
        if let session = try? await repository.getSession() {
            appState.screen = .profile(session)
        }
    }
}

// MARK: - App State

@Observable
@MainActor
private final class AppState {
    var screen: Screen = .login
}

private enum Screen {
    case login
    case registration
    case profile(OrySession)
}

#Preview {
    ContentView(
        repository: PreviewAuthRepository()
    )
}

// MARK: - Preview Repository

/// A no-op repository for SwiftUI previews.
private final class PreviewAuthRepository: AuthRepository {
    func initLoginFlow() async throws -> FlowContainer {
        FlowContainer(id: "", expiresAt: Date(), nodes: [], messages: [], actionURL: "")
    }
    func submitLogin(flowId: String, credentials: LoginCredentials) async throws -> OrySession {
        OrySession(id: "", token: "", identity: OryIdentity(id: "", schemaId: "", state: nil, traits: [:]), expiresAt: nil, authenticatedAt: nil, isActive: false)
    }
    func initRegistrationFlow() async throws -> FlowContainer {
        FlowContainer(id: "", expiresAt: Date(), nodes: [], messages: [], actionURL: "")
    }
    func submitRegistration(flowId: String, credentials: RegistrationCredentials) async throws -> RegistrationResult {
        .pendingVerification(identity: OryIdentity(id: "", schemaId: "", state: nil, traits: [:]))
    }
    func getSession() async throws -> OrySession? { nil }
    func logout() async throws {}
}
