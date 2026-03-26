//
//  RootVIew.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 25/03/2026.
//

import OryAuth
import SwiftUI

struct RootView<ViewModel>: View where ViewModel: RootViewModel {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: ViewModel

    public init(viewModel: @autoclosure @escaping () -> ViewModel) {
        _viewModel = .init(wrappedValue: viewModel())
    }
    
    // MARK: - View
    
    var body: some View {
       rootView
            .task {
                await viewModel.onTask()
            }
            .animation(.spring(duration: 0.2), value: viewModel.appState)
    }
    
    @ViewBuilder private var rootView: some View {
        ZStack {
            switch viewModel.appState {
            case .idle:
                Text("idle")
            case .loadingInitialState:
                VStack {
                    Text("loading initial state")
                    ProgressView()
                }
            case .loggedIn:
                mainView
            case .loggedOut:
                welcomeJourney
            }
        }
    }
    
    private var mainView: some View {
        ProfileView(
            viewModel: ProfileViewModel(
                authRepository: AppComponents.authRepository,
                onLogout: {
                    viewModel.logout()
                }
            )
        )
    }
    
    private var welcomeJourney: some View {
        WelcomeJourneyCoordinatorView(
            coordinator: WelcomeJourneyCoordinator(
                onComplete: {
                    viewModel.onWelcomeJourneyCompletion()
                }
            )
        )
    }
}
