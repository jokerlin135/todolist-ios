//
//  KeychainService.swift
//  aatodo
//
//  Secure token storage using Keychain
//  Issue: aatodo-83e.3
//

import Foundation

/// Secure storage service for sensitive tokens using iOS Keychain
/// - Thread-safe: Uses actor to prevent concurrent access issues
/// - Accessible only when device is unlocked (kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
actor KeychainService {
    static let shared = KeychainService()

    // MARK: - Constants

    private enum KeychainError: Error {
        case duplicateEntry
        case itemNotFound
        case unknown(OSStatus)
        case invalidData

        var localizedDescription: String {
            switch self {
            case .duplicateEntry:
                return "Item already exists in Keychain"
            case .itemNotFound:
                return "Item not found in Keychain"
            case .unknown(let status):
                return "Unknown Keychain error: \(status)"
            case .invalidData:
                return "Invalid data format"
            }
        }
    }

    private let service = "com.aatodo.keychain"

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Save a token to Keychain
    /// - Parameters:
    ///   - token: The token string to store
    ///   - key: Unique identifier for the token (e.g., "access_token", "refresh_token")
    /// - Throws: KeychainError if operation fails
    func saveToken(_ token: String, forKey key: String) throws {
        let data = token.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Try to add item
        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Item exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]

            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]

            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)

            guard updateStatus == errSecSuccess else {
                throw KeychainError.unknown(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unknown(status)
        }
    }

    /// Retrieve a token from Keychain
    /// - Parameter key: Unique identifier for the token
    /// - Returns: The token string if found, nil otherwise
    /// - Throws: KeychainError if operation fails (except item not found)
    func getToken(forKey key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let token = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return token
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unknown(status)
        }
    }

    /// Delete a specific token from Keychain
    /// - Parameter key: Unique identifier for the token to delete
    /// - Throws: KeychainError if operation fails
    func deleteToken(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }

    /// Delete ALL tokens from Keychain for this app
    /// - Warning: This is a destructive operation, use carefully (e.g., logout)
    /// - Throws: KeychainError if operation fails
    func clearAllTokens() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }

    /// Check if a token exists in Keychain
    /// - Parameter key: Unique identifier for the token
    /// - Returns: true if token exists, false otherwise
    func hasToken(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}

// MARK: - Convenience Token Keys

extension KeychainService {
    /// Predefined keys for common token types
    enum TokenKey {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userId = "user_id"
        static let userEmail = "user_email"
    }
}
