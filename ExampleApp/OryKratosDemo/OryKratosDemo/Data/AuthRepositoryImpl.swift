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
final class AuthRepositoryImpl: AuthRepository {

    private let client: OryAuthClient

    init(client: OryAuthClient) {
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
        try await client.submitRegistration(flowId: flowId, credentials: credentials)
    }

    func getSession() async throws -> OrySession? {
        try await client.getSession()
    }

    func logout() async throws {
        try await client.logout()
    }
}
