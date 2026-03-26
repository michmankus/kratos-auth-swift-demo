//
//  ProfileViewModel.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Combine
import OryAuth
import SwiftUI

final class ProfileViewModel: ProfileViewModelProtocol {
    
    // MARK: - Properties

    @Published private(set) var state: ProfileViewState = .sessionNotLoaded
    @Published private(set) var isLoading = false

    private let authRepository: AuthRepository
    private let onLogout: Closure
    
    // MARK: - Init

    init(
        authRepository: AuthRepository,
        onLogout: @escaping Closure
    ) {
        self.authRepository = authRepository
        self.onLogout = onLogout
    }
    
    // MARK: - Public methods
    
    func onTask() async {
        guard let currentSession = authRepository.currentSession else {
            state = .sessionNotLoaded
            return
        }
        
        state = .sessionLoaded(currentSession)
    }

    func logout() async {
        isLoading = true
        try? await authRepository.logout()
        isLoading = false
        onLogout()
    }
    
    // MARK: - Private methods
}

#if DEBUG

// MARK: - Fixture

final class ProfileViewModelFixture: ProfileViewModelProtocol {
    var state: ProfileViewState
    var isLoading = false

    init() {
        state = .sessionLoaded(
            OrySession( // TODO: - Consider StubFactory
                id: "session-123",
                token: "ory_st_preview",
                identity: OryIdentity(
                    id: "identity-456",
                    schemaId: "default",
                    state: "active",
                    traits: ["email": "jane@example.com", "name": "Jane Doe"]
                ),
                expiresAt: Date().addingTimeInterval(86400),
                authenticatedAt: Date(),
                isActive: true
            )
        )
    }

    func onTask() async {}
    func logout() async {}
}

#endif
