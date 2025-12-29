//
//  Constants.swift
//  aatodo
//
//  App-wide constants
//  Issue: aatodo-1vp.4
//

import Foundation

enum Constants {
    // MARK: - App Info

    static let appName = "aatodo"
    static let bundleIdentifier = "com.aatodo.app"
    static let keychainService = "com.aatodo.keychain"

    // MARK: - Rate Limiting

    /// Rate limiting configuration for Supabase API
    /// Configured in Supabase Dashboard: API > Rate Limiting
    /// - 100 requests per minute per IP address
    /// - Burst allowance: 20 requests
    /// - Error response: HTTP 429 (Too Many Requests)
    enum RateLimit {
        static let requestsPerMinute = 100
        static let burstAllowance = 20
        static let retryAfterSeconds: TimeInterval = 60 // Default retry delay
    }
}
