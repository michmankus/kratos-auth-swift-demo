//
//  MockKeychain.swift
//  SecureStorage
//
//  Created by Michal Mańkus on 28/03/2026.
//

import Foundation
@testable import SecureStorage

private actor MockKeychain: KeychainProtocol {

    private var store: [String: Data] = [:]

    private func compositeKey(service: String, key: String) -> String {
        "\(service).\(key)"
    }

    func readValue<T>(from service: String, for key: String) throws -> T where T: Decodable & Sendable {
        let compositeKey = compositeKey(service: service, key: key)
        guard let data = store[compositeKey] else {
            throw KeychainError.readValueFailed(-25300)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw KeychainError.decodingFailed
        }
    }

    func setValue<T>(in service: String, for key: String, with value: T) throws where T: Encodable & Sendable {
        let compositeKey = compositeKey(service: service, key: key)
        store[compositeKey] = try JSONEncoder().encode(value)
    }

    func removeValue(from service: String, for key: String) throws {
        let compositeKey = compositeKey(service: service, key: key)
        store.removeValue(forKey: compositeKey)
    }
}
