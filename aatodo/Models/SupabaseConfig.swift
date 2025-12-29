//
//  SupabaseConfig.swift
//  aatodo
//
//  Supabase configuration loader
//  Issue: aatodo-83e.4, aatodo-1vp.4
//

import Foundation

// MARK: - Supabase Dashboard Configuration

/// Rate limiting must be configured in Supabase Dashboard:
/// 1. Navigate to: API > Rate Limiting
/// 2. Enable rate limiting
/// 3. Set limits: 100 requests/minute per IP
/// 4. Configure burst allowance: 20 requests
/// 5. Save and test
///
/// HTTP 429 (Too Many Requests) will be returned when limit exceeded.
/// See Constants.RateLimit for configured values.

/// Supabase configuration loaded from environment variables
struct SupabaseConfig {
    let url: URL
    let anonKey: String

    /// Load Supabase configuration from environment variables
    /// - Returns: SupabaseConfig with URL and anon key
    /// - Note: For development, reads from .env file. For production, use environment variables or xcconfig
    static func load() throws -> SupabaseConfig {
        // Try to get values from environment variables first (for production)
        if let urlEnv = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           let anonKeyEnv = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
           let url = URL(string: urlEnv) {
            return SupabaseConfig(url: url, anonKey: anonKeyEnv)
        }

        // Fallback to hardcoded values for development
        // TODO: Replace with actual Supabase credentials from .env
        let urlString = "https://rwhjjiizrwkmmxwqdrrj.supabase.co"
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3aGpqaWl6cndrbW14d3FkcnJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY5MTcwNDIsImV4cCI6MjA4MjQ5MzA0Mn0.2HdJNQShJW0hZM6apkTkPlaU4rB8QwNUtbq91Be6ZEE"

        guard let url = URL(string: urlString) else {
            throw ConfigError.invalidURL
        }

        return SupabaseConfig(url: url, anonKey: anonKey)
    }

    /// Configuration errors
    enum ConfigError: Error, LocalizedError {
        case invalidURL
        case missingAnonKey

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid SUPABASE_URL"
            case .missingAnonKey:
                return "SUPABASE_ANON_KEY is missing"
            }
        }
    }
}
