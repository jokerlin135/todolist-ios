//
//  SupabaseTodo.swift
//  aatodo
//
//  Supabase DTO for API serialization
//  Issue: aatodo-83o.1
//

import Foundation

/// Data Transfer Object for Supabase API
/// - Uses snake_case for field names (Supabase/PostgreSQL convention)
/// - ISO8601 date strings for timestamps
struct SupabaseTodo: Codable {
    let id: String
    let title: String
    let is_completed: Bool
    let created_at: String
    let updated_at: String
    let user_id: String

    /// Coding keys for snake_case JSON mapping
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case is_completed
        case created_at
        case updated_at
        case user_id
    }

    /// Convert to TodoItem SwiftData model
    /// - Returns: TodoItem instance
    func toTodoItem() -> TodoItem {
        return TodoItem(from: self)
    }
}
