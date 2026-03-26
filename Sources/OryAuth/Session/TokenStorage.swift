//
//  TokenStorage.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Foundation
import SecureStorage

// MARK: - TokenStorage

/// Internal wrapper around `KeychainProtocol` with Ory-specific constants.
///
/// Provides a simple async interface for storing and retrieving the
/// session token securely in the iOS Keychain.
struct TokenStorage: Sendable {

    private static let service = "com.oryauth"
    private static let tokenKey = "session_token"

    private let keychain: any KeychainProtocol

    init(keychain: any KeychainProtocol = KeychainImplementation()) {
        self.keychain = keychain
    }

    /// Store a session token securely in the Keychain.
    func saveToken(_ token: String) async throws {
        try await keychain.setValue(in: Self.service, for: Self.tokenKey, with: token)
    }

    /// Retrieve the stored session token, or `nil` if none exists.
    func loadToken() async -> String? {
        try? await keychain.readValue(from: Self.service, for: Self.tokenKey)
    }

    /// Remove the stored session token from the Keychain.
    func deleteToken() async throws {
        try await keychain.removeValue(from: Self.service, for: Self.tokenKey)
    }
}
