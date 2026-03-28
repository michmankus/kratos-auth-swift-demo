//
//  MockKeychain.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 28/03/2026.
//

import Foundation
import Testing
import SecureStorage
@testable import OryAuth

actor MockKeychain: KeychainProtocol {

    private var store: [String: Data] = [:]

    private func compositeKey(service: String, key: String) -> String {
        "\(service).\(key)"
    }

    func readValue<T>(from service: String, for key: String) throws -> T where T: Decodable & Sendable {
        let compositeKey = compositeKey(service: service, key: key)
        guard let data = store[compositeKey] else {
            throw KeychainError.readValueFailed(-25300) // errSecItemNotFound
        }
        return try JSONDecoder().decode(T.self, from: data)
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
