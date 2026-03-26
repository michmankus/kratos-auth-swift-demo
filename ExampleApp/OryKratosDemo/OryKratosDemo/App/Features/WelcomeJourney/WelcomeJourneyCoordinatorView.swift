//
//  WelcomeJourneyCoordinatorView.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import SwiftUI

struct WelcomeJourneyCoordinatorView<Coordinator>: View where Coordinator: WelcomeJourneyCoordinator {
    
    // MARK: - Properties
    
    @StateObject private var coordinator: Coordinator
    
    init(coordinator: @autoclosure @escaping () -> Coordinator) {
        _coordinator = .init(wrappedValue: coordinator())
    }
    
    // MARK: - View
    
    var body: some View {
        Router(
            $coordinator.path,
            withNavigation: false,
            root: {
                welcomeView
            },
            destination: { page in
                switch page {
                case .login:
                    loginView
                case .register:
                    registerView
                }
            }
        )
    }
    
    private var welcomeView: some View {
        WelcomeView(
            onLoginAction: {
                coordinator.showLogin()
            },
            onRegisterAction: {
                coordinator.showRegister()
            }
        )
    }
    
    // MARK: - Pages
    
    private var loginView: some View {
        Text("Login")
    }
    
    private var registerView: some View {
        RegistrationView(
            viewModel: RegistrationViewModel(
                repository: AppComponents.authRepository,
                onRegistrationSuccess: { session in
                    print("debug: registration success")
                    coordinator.didRegister()
                },
                onDismiss: {
                    coordinator.dismiss()
                }
            )
        )
    }
}
