//
//  ProfileViewModel.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth
import SwiftUI

// MARK: - Protocol

@MainActor
protocol ProfileViewModelProtocol: Observable, AnyObject {
    var session: OrySession { get }
    var isLoading: Bool { get }

    func logout() async
}

// MARK: - Implementation

@Observable
@MainActor
final class ProfileViewModel: ProfileViewModelProtocol {

    let session: OrySession
    private(set) var isLoading = false

    private let repository: AuthRepository
    private let onLogout: () -> Void

    init(session: OrySession, repository: AuthRepository, onLogout: @escaping () -> Void) {
        self.session = session
        self.repository = repository
        self.onLogout = onLogout
    }

    func logout() async {
        isLoading = true
        try? await repository.logout()
        isLoading = false
        onLogout()
    }
}

// MARK: - Fixture

@Observable
@MainActor
final class ProfileViewModelFixture: ProfileViewModelProtocol {
    var session: OrySession
    var isLoading = false

    init() {
        session = OrySession(
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
    }

    func logout() async {}
}
