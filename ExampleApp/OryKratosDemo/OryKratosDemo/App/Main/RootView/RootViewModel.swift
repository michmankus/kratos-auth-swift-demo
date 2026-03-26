//
//  RootViewModel.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class RootViewModel: Sendable, ObservableObject {
    
    // MARK: - Properties

    @Published private(set) var appState: AppState
    
    private let authRepository: AuthRepository
    
    // MARK: - Init

    init(authRepository: AuthRepository) {
        self.appState = .idle
        self.authRepository = authRepository
    }
    
    // MARK: - Methods
    
    func onTask() async {
        await loadInitialState()
    }
    
    func onWelcomeJourneyCompletion() {
        appState = .loggedIn
    }
    
    // MARK: - Initial state loading

    private func loadInitialState() async {
        guard appState == .idle else { return }
        
        appState = .loadingInitialState
        
        try? await Task.sleep(for: .seconds(2)) // Simulating some heavy loading
        
        do {
            let currentSession = try await authRepository.loadSession() // Retrieves saved session upon app start
            print("debug: currentSession: \(currentSession)")
            appState = .loggedIn
        } catch {
            print("debug: no session found")
            appState = .loggedOut
        }
    }
}
