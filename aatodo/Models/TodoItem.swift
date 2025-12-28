//
//  TodoItem.swift
//  aatodo
//
//  SwiftData model for Todo items
//  Issue: aatodo-83o.1
//

import Foundation
import SwiftData

/// SwiftData model for Todo items
/// - Persistent storage using SwiftData
/// - Local-First sync with dirty flag (needsSync)
@Model
final class TodoItem {
    /// Unique identifier (UUID string)
    var id: String

    /// Todo title
    var title: String

    /// Completion status
    var isCompleted: Bool

    /// Creation timestamp
    var createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    /// User ID who owns this todo
    var userId: String

    /// Dirty flag for sync: true if needs to be synced to server
    var needsSync: Bool

    /// Create a new TodoItem
    /// - Parameters:
    ///   - title: The todo title
    ///   - userId: The user ID who owns this todo
    init(title: String, userId: String) {
        self.id = UUID().uuidString
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.userId = userId
        self.needsSync = true // New items need to be synced
    }

    /// Initialize from SupabaseTodo (when syncing from server)
    /// - Parameter supabaseTodo: The SupabaseTodo DTO
    init(from supabaseTodo: SupabaseTodo) {
        self.id = supabaseTodo.id
        self.title = supabaseTodo.title
        self.isCompleted = supabaseTodo.is_completed
        self.createdAt = ISO8601DateFormatter().date(from: supabaseTodo.created_at) ?? Date()
        self.updatedAt = ISO8601DateFormatter().date(from: supabaseTodo.updated_at) ?? Date()
        self.userId = supabaseTodo.user_id
        self.needsSync = false // Items from server are already synced
    }

    /// Convert to SupabaseTodo DTO for API calls
    /// - Returns: SupabaseTodo struct
    func toSupabaseTodo() -> SupabaseTodo {
        let formatter = ISO8601DateFormatter()
        return SupabaseTodo(
            id: self.id,
            title: self.title,
            is_completed: self.isCompleted,
            created_at: formatter.string(from: self.createdAt),
            updated_at: formatter.string(from: self.updatedAt),
            user_id: self.userId
        )
    }

    /// Mark as completed and update timestamps
    func markAsCompleted() {
        self.isCompleted = true
        self.updatedAt = Date()
        self.needsSync = true // Modified, needs sync
    }

    /// Mark as uncompleted and update timestamps
    func markAsUncompleted() {
        self.isCompleted = false
        self.updatedAt = Date()
        self.needsSync = true // Modified, needs sync
    }

    /// Update title and mark as needing sync
    /// - Parameter newTitle: The new title
    func updateTitle(_ newTitle: String) {
        self.title = newTitle
        self.updatedAt = Date()
        self.needsSync = true // Modified, needs sync
    }
}
