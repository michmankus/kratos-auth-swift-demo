//
//  SecureStorageTests.swift
//  SecureStorage
//
//  Created by Michal Mańkus on 28/03/2026.
//

import Foundation
import Testing
@testable import SecureStorage

@Suite("KeychainProtocol")
struct KeychainProtocolTests {
    
    private struct TestCredential: Codable, Sendable, Equatable {
        let username: String
        let token: String
    }

    private let service = "test.service"
    private let key = "test.key"

    @Test("Given a value is stored, When reading it back, Then it returns the original value")
    func storeAndRead() async throws {
        let keychain = MockKeychain()
        let credential = TestCredential(username: "alice", token: "abc123")

        try await keychain.setValue(in: service, for: key, with: credential)
        let result: TestCredential = try await keychain.readValue(from: service, for: key)

        #expect(result == credential)
    }

    @Test("Given a value is stored, When storing a new value for the same key, Then it overwrites the previous value")
    func overwrite() async throws {
        let keychain = MockKeychain()
        let first = TestCredential(username: "alice", token: "first")
        let second = TestCredential(username: "alice", token: "second")

        try await keychain.setValue(in: service, for: key, with: first)
        try await keychain.setValue(in: service, for: key, with: second)
        let result: TestCredential = try await keychain.readValue(from: service, for: key)

        #expect(result == second)
    }

    @Test("Given no value is stored, When reading a value, Then it throws readValueFailed")
    func readEmpty() async {
        let keychain = MockKeychain()

        await #expect(throws: KeychainError.self) {
            let _: TestCredential = try await keychain.readValue(from: service, for: key)
        }
    }

    @Test("Given a value is stored, When removing it, Then reading throws readValueFailed")
    func removeAndRead() async throws {
        let keychain = MockKeychain()
        let credential = TestCredential(username: "alice", token: "abc123")

        try await keychain.setValue(in: service, for: key, with: credential)
        try await keychain.removeValue(from: service, for: key)

        await #expect(throws: KeychainError.self) {
            let _: TestCredential = try await keychain.readValue(from: service, for: key)
        }
    }

    @Test("Given no value is stored, When removing it, Then it does not throw")
    func removeNonExistent() async throws {
        let keychain = MockKeychain()

        try await keychain.removeValue(from: service, for: key)
    }

    @Test("Given a value is stored for one key, When reading a different key, Then it throws readValueFailed")
    func readWrongKey() async throws {
        let keychain = MockKeychain()
        let credential = TestCredential(username: "alice", token: "abc123")

        try await keychain.setValue(in: service, for: key, with: credential)

        await #expect(throws: KeychainError.self) {
            let _: TestCredential = try await keychain.readValue(from: service, for: "other.key")
        }
    }

    @Test("Given values stored in different services, When reading from each service, Then each returns its own value")
    func differentServices() async throws {
        let keychain = MockKeychain()
        let credentialA = TestCredential(username: "alice", token: "tokenA")
        let credentialB = TestCredential(username: "bob", token: "tokenB")

        try await keychain.setValue(in: "service.a", for: key, with: credentialA)
        try await keychain.setValue(in: "service.b", for: key, with: credentialB)

        let resultA: TestCredential = try await keychain.readValue(from: "service.a", for: key)
        let resultB: TestCredential = try await keychain.readValue(from: "service.b", for: key)

        #expect(resultA == credentialA)
        #expect(resultB == credentialB)
    }
}

@Suite("KeychainError")
struct KeychainErrorTests {

    @Test("Given a deleteFailed error, When inspecting its associated status, Then it carries the correct OSStatus")
    func deleteFailedStatus() {
        let error = KeychainError.deleteFailed(-25300)

        guard case .deleteFailed(let status) = error else {
            Issue.record("Expected .deleteFailed, got \(error)")
            return
        }
        #expect(status == -25300)
    }

    @Test("Given a setValueFailed error, When inspecting its associated status, Then it carries the correct OSStatus")
    func setValueFailedStatus() {
        let error = KeychainError.setValueFailed(-25299)

        guard case .setValueFailed(let status) = error else {
            Issue.record("Expected .setValueFailed, got \(error)")
            return
        }
        #expect(status == -25299)
    }

    @Test("Given a readValueFailed error, When inspecting its associated status, Then it carries the correct OSStatus")
    func readValueFailedStatus() {
        let error = KeychainError.readValueFailed(-25300)

        guard case .readValueFailed(let status) = error else {
            Issue.record("Expected .readValueFailed, got \(error)")
            return
        }
        #expect(status == -25300)
    }

    @Test("Given an errorCastinData error, When matching it, Then it matches the correct case")
    func errorCastingData() {
        let error = KeychainError.errorCastinData

        guard case .errorCastinData = error else {
            Issue.record("Expected .errorCastinData, got \(error)")
            return
        }
    }

    @Test("Given a decodingFailed error, When matching it, Then it matches the correct case")
    func decodingFailed() {
        let error = KeychainError.decodingFailed

        guard case .decodingFailed = error else {
            Issue.record("Expected .decodingFailed, got \(error)")
            return
        }
    }
}
