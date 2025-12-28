//
//  SupabaseTodo.swift
//  aatodo
//
//  Placeholder for Supabase DTO
//  Issue: aatodo-83o.1
//

import Foundation

struct SupabaseTodo: Codable {
    let id: String
    let title: String
    let is_completed: Bool
    let created_at: String
    let updated_at: String
    let user_id: String

    // TODO: Implement conversion methods in aatodo-83o.1
}
