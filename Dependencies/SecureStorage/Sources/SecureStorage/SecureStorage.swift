import Foundation
import Security

public protocol KeychainProtocol: Actor {
    func readValue<T>(from service: String, for key: String) throws -> T where T: Decodable & Sendable
    
    func setValue<T>(in service: String, for key: String, with value: T) throws where T: Encodable & Sendable
    
    func removeValue(from service: String, for key: String) throws
}

public enum KeychainError: Error {
    case deleteFailed(OSStatus)
    case setValueFailed(OSStatus)
    case readValueFailed(OSStatus)
    case errorCastinData
    case decodingFailed
}

public final actor KeychainImplementation: KeychainProtocol {
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init() {}
    
    public func readValue<T>(
        from service: String,
        for key: String
    ) throws -> T where T: Decodable & Sendable {
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service
        query[kSecAttrAccount as String] = key
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecAttrSynchronizable as String] = kCFBooleanFalse
        
        var queryResult: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &queryResult)
        
        guard status == errSecSuccess else {
            throw KeychainError.readValueFailed(status)
        }
        
        guard let data = queryResult as? Data else {
            throw KeychainError.errorCastinData
        }
            
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw KeychainError.decodingFailed
        }
    }
    
    public func setValue<T>(
        in service: String,
        for key: String,
        with value: T
    ) throws where T: Encodable & Sendable {
        try removeValue(from: service, for: key)
        
        let encodedData = try encoder.encode(value)
        
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        query[kSecAttrSynchronizable as String] = kCFBooleanFalse
        query[kSecAttrService as String] = service
        query[kSecAttrAccount as String] = key
        query[kSecValueData as String] = encodedData
        
        let result = SecItemAdd(query as CFDictionary, nil)
        guard result == errSecSuccess else {
            throw KeychainError.setValueFailed(result)
        }
    }
    
    public func removeValue(
        from service: String,
        for key: String
    ) throws {
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrSynchronizable as String] = kCFBooleanFalse
        query[kSecAttrService as String] = service
        query[kSecAttrAccount as String] = key
        
        let result = SecItemDelete(query as CFDictionary)
        guard result == errSecSuccess || result == errSecItemNotFound else {
            throw KeychainError.deleteFailed(result)
        }
    }
}
