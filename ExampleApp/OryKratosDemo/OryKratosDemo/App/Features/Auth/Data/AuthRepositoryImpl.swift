//
//  AuthRepositoryImpl.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth

/// Concrete implementation of `AuthRepository` backed by `OryAuthClient`.
///
/// This is the only place in the app that knows about `OryAuthClient`.
/// The presentation layer never touches it directly.
actor AuthRepositoryImpl: AuthRepository {

    private let client: any OryAuthClientProtocol
    private(set) var currentSession: OrySession?
    
    var hasActiveSession: Bool {
        guard let currentSession, currentSession.isActive else {
            return false
        }
        
        return true
    }

    init(client: any OryAuthClientProtocol) {
        self.client = client
    }

    func initLoginFlow() async throws -> FlowContainer {
        try await client.initLoginFlow()
    }

    func submitLogin(flowId: String, credentials: LoginCredentials) async throws -> OrySession {
        try await client.submitLogin(flowId: flowId, credentials: credentials)
    }

    func initRegistrationFlow() async throws -> FlowContainer {
        try await client.initRegistrationFlow()
    }

    func submitRegistration(flowId: String, credentials: RegistrationCredentials) async throws -> RegistrationResult {
        do {
            let result = try await client.submitRegistration(flowId: flowId, credentials: credentials)
            if case .session(let orySession) = result {
                currentSession = orySession
            }
            return result
        } catch {
            throw error
        }
    }

    @discardableResult
    func loadSession() async throws -> OrySession {
        do {
            let session = try await client.loadSession()
            print("debug: Successfully loaded session: \(session)")
            currentSession = session
            return session
        } catch {
            switch error {
            case .missingSessionToken:
                print("debug: No session token stored, loadSession() failed")
            case .unauthorized:
                print("debug: Failed to get session for token")
            default:
                print("debug: getSession() failed with other error: \(error)")
            }
            currentSession = nil
            throw error
        }
    }

    func logout() async throws {
        try await client.logout()
    }
}
