//
//  AuthRepository.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth

/// Defines the authentication operations available to the app.
///
/// The presentation layer depends only on this protocol,
/// never on `OryAuthClient` directly.
protocol AuthRepository: Sendable {
    func initLoginFlow() async throws -> FlowContainer
    func submitLogin(flowId: String, credentials: LoginCredentials) async throws -> OrySession
    func initRegistrationFlow() async throws -> FlowContainer
    func submitRegistration(flowId: String, credentials: RegistrationCredentials) async throws -> RegistrationResult
    func getSession() async throws -> OrySession?
    func logout() async throws
}
