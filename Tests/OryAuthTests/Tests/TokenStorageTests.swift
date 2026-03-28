//
//  TokenStorageTests.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 28/03/2026.
//

import Foundation
import Testing
import SecureStorage
@testable import OryAuth

@Suite("TokenStorage")
struct TokenStorageTests {

    @Test func saveAndLoadToken() async throws {
        let keychain = MockKeychain()
        let storage = TokenStorage(keychain: keychain)

        try await storage.saveToken("test-token-123")
        let loaded = await storage.loadToken()

        #expect(loaded == "test-token-123")
    }

    @Test func loadTokenReturnsNilWhenEmpty() async {
        let keychain = MockKeychain()
        let storage = TokenStorage(keychain: keychain)

        let loaded = await storage.loadToken()

        #expect(loaded == nil)
    }

    @Test func deleteTokenRemovesStoredValue() async throws {
        let keychain = MockKeychain()
        let storage = TokenStorage(keychain: keychain)

        try await storage.saveToken("token-to-delete")
        try await storage.deleteToken()
        let loaded = await storage.loadToken()

        #expect(loaded == nil)
    }

    @Test func saveTokenOverwritesPreviousValue() async throws {
        let keychain = MockKeychain()
        let storage = TokenStorage(keychain: keychain)

        try await storage.saveToken("first-token")
        try await storage.saveToken("second-token")
        let loaded = await storage.loadToken()

        #expect(loaded == "second-token")
    }
}
