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
    var hasActiveSession: Bool { get }
    var currentSession: OrySession? { get }
    
    func initLoginFlow() async throws -> FlowContainer
    func submitLogin(flowId: String, credentials: LoginCredentials) async throws -> OrySession
    func initRegistrationFlow() async throws -> FlowContainer
    func submitRegistration(flowId: String, credentials: RegistrationCredentials) async throws -> RegistrationResult
    @discardableResult func loadSession() async throws -> OrySession
    func logout() async throws
}
