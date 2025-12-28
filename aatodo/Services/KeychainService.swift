//
//  KeychainService.swift
//  aatodo
//
//  Placeholder for Keychain secure storage
//  Issue: aatodo-83e.3
//

import Foundation

actor KeychainService {
    static let shared = KeychainService()

    private init() {}

    func saveToken(_ token: String, forKey key: String) throws {
        // Implementation coming in aatodo-83e.3
        fatalError("Not implemented yet")
    }

    func getToken(forKey key: String) throws -> String? {
        // Implementation coming in aatodo-83e.3
        fatalError("Not implemented yet")
    }

    func deleteToken(forKey key: String) throws {
        // Implementation coming in aatodo-83e.3
        fatalError("Not implemented yet")
    }

    func clearAllTokens() throws {
        // Implementation coming in aatodo-83e.3
        fatalError("Not implemented yet")
    }
}
