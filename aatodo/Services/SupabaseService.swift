//
//  SupabaseService.swift
//  aatodo
//
//  Placeholder for Supabase backend service
//  Issue: aatodo-83e.4
//

import Foundation
import Supabase

actor SupabaseService {
    static let shared = SupabaseService()

    private let client: SupabaseClient

    private init() {
        // TODO: Load from secure config in aatodo-83e.4
        self.client = SupabaseClient(
            supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
            supabaseKey: "YOUR_ANON_KEY"
        )
    }

    // Placeholder methods - implementation coming in aatodo-444.1
}
