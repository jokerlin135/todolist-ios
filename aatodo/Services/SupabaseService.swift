//
//  SupabaseService.swift
//  aatodo
//
//  Supabase backend service integration
//  Issue: aatodo-83e.4
//
//  IMPORTANT: Before using this file, add the Supabase Swift SDK via SPM:
//  1. Open aatodo.xcodeproj in Xcode
//  2. File > Add Package Dependencies
//  3. Enter: https://github.com/supabase/supabase-swift
//  4. Select version: Up to Next Major Version (2.0.0)
//  5. Click "Add Package"
//  6. Select Supabase, Auth, Realtime libraries
//  7. Click "Add Package"
//

import Foundation
// TODO: Uncomment after adding Supabase package
// import Supabase
// import Auth
// import Realtime

/// Supabase service actor for thread-safe backend operations
/// - Singleton pattern with lazy initialization
/// - Uses anon key only (NEVER service_role key in client apps)
actor SupabaseService {
    static let shared = SupabaseService()

    /// Supabase client instance
    // TODO: Uncomment after adding Supabase package
    // let client: SupabaseClient

    /// Auth client instance
    // TODO: Uncomment after adding Supabase package
    // var auth: AuthClient {
    //     client.auth
    // }

    /// Private initializer with config loading
    private init() {
        // TODO: Uncomment after adding Supabase package
        /*
        do {
            let config = try SupabaseConfig.load()
            self.client = SupabaseClient(
                supabaseURL: config.url,
                supabaseKey: config.anonKey
            )
        } catch {
            fatalError("Failed to load Supabase configuration: \(error.localizedDescription)")
        }
        */
    }

    // MARK: - Auth Convenience Methods

    /// Get current session
    /// TODO: Uncomment after adding Supabase package
    /*
    func getCurrentSession() async throws -> Session {
        return try await auth.session
    }
    */

    /// Get current user
    /// TODO: Uncomment after adding Supabase package
    /*
    func getCurrentUser() async throws -> User {
        let session = try await getCurrentSession()
        return session.user
    }
    */

    /// Check if user is authenticated
    /// TODO: Uncomment after adding Supabase package
    /*
    func isAuthenticated() async -> Bool {
        do {
            _ = try await getCurrentSession()
            return true
        } catch {
            return false
        }
    }
    */
}
