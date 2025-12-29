//
//  SwiftDataService.swift
//  aatodo
//
//  Local persistence service using SwiftData
//  Issue: aatodo-8oz.1
//

import Foundation
import SwiftData
import Observation

// MARK: - Swift Data Errors

/// SwiftData-specific errors
enum SwiftDataError: LocalizedError {
    case notInitialized
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case invalidTodo

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "SwiftData is not properly initialized"
        case .fetchFailed(let message):
            return "Failed to fetch data: \(message)"
        case .saveFailed(let message):
            return "Failed to save data: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete data: \(message)"
        case .invalidTodo:
            return "Invalid todo data"
        }
    }
}

// MARK: - Swift Data Service

/// SwiftData service actor for local persistence
/// - All operations must run on @MainActor
/// - Provides CRUD operations for TodoItem model
/// - Supports sync state tracking via needsSync flag
@MainActor
actor SwiftDataService {
    // MARK: - Properties

    /// ModelContext for SwiftData operations
    private let modelContext: ModelContext

    // MARK: - Singleton

    static let shared: SwiftDataService

    // MARK: - Initialization

    /// Initialize with ModelContext
    /// - Parameter modelContext: The SwiftData ModelContext
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Private initializer for singleton pattern
    private init?() {
        // Use shared(modelContext:) instead
        return nil
    }

    // MARK: - Fetch Operations

    /// Fetch all todos for a specific user
    /// - Parameter userId: The user ID to filter todos
    /// - Returns: Array of TodoItem sorted by createdAt descending
    /// - Throws: SwiftDataError if fetch fails
    func fetchTodos(userId: String) throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let todos = try modelContext.fetch(descriptor)
            return todos
        } catch {
            throw SwiftDataError.fetchFailed(error.localizedDescription)
        }
    }

    /// Fetch todos that need to be synced to server
    /// - Parameter userId: The user ID to filter todos
    /// - Returns: Array of TodoItem with needsSync == true
    /// - Throws: SwiftDataError if fetch fails
    func fetchPendingSync(userId: String) throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.userId == userId && $0.needsSync == true },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        do {
            let todos = try modelContext.fetch(descriptor)
            return todos
        } catch {
            throw SwiftDataError.fetchFailed(error.localizedDescription)
        }
    }

    /// Fetch active (non-completed) todos for a user
    /// - Parameter userId: The user ID to filter todos
    /// - Returns: Array of active TodoItem
    /// - Throws: SwiftDataError if fetch fails
    func fetchActiveTodos(userId: String) throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.userId == userId && $0.isCompleted == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let todos = try modelContext.fetch(descriptor)
            return todos
        } catch {
            throw SwiftDataError.fetchFailed(error.localizedDescription)
        }
    }

    /// Fetch completed todos for a user
    /// - Parameter userId: The user ID to filter todos
    /// - Returns: Array of completed TodoItem
    /// - Throws: SwiftDataError if fetch fails
    func fetchCompletedTodos(userId: String) throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.userId == userId && $0.isCompleted == true },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        do {
            let todos = try modelContext.fetch(descriptor)
            return todos
        } catch {
            throw SwiftDataError.fetchFailed(error.localizedDescription)
        }
    }

    /// Fetch a specific todo by ID
    /// - Parameter todoId: The todo ID to fetch
    /// - Returns: TodoItem if found
    /// - Throws: SwiftDataError if not found or fetch fails
    func fetchTodo(todoId: String) throws -> TodoItem {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.id == todoId }
        )

        do {
            let todos = try modelContext.fetch(descriptor)
            guard let todo = todos.first else {
                throw SwiftDataError.fetchFailed("Todo not found")
            }
            return todo
        } catch {
            throw SwiftDataError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Save Operations

    /// Save a new todo to local database
    /// - Parameter todo: The TodoItem to save
    /// - Throws: SwiftDataError if save fails
    func save(_ todo: TodoItem) throws {
        modelContext.insert(todo)

        do {
            try modelContext.save()
        } catch {
            throw SwiftDataError.saveFailed(error.localizedDescription)
        }
    }

    /// Batch save multiple todos to local database
    /// - Parameter todos: Array of TodoItem to save
    /// - Throws: SwiftDataError if save fails
    func batchSave(_ todos: [TodoItem]) throws {
        guard !todos.isEmpty else { return }

        for todo in todos {
            modelContext.insert(todo)
        }

        do {
            try modelContext.save()
        } catch {
            throw SwiftDataError.saveFailed(error.localizedDescription)
        }
    }

    // MARK: - Update Operations

    /// Update an existing todo
    /// - Parameter todo: The TodoItem with updated values
    /// - Throws: SwiftDataError if update fails
    func update(_ todo: TodoItem) throws {
        do {
            try modelContext.save()
        } catch {
            throw SwiftDataError.saveFailed(error.localizedDescription)
        }
    }

    // MARK: - Delete Operations

    /// Delete a todo from local database
    /// - Parameter todo: The TodoItem to delete
    /// - Throws: SwiftDataError if delete fails
    func delete(_ todo: TodoItem) throws {
        modelContext.delete(todo)

        do {
            try modelContext.save()
        } catch {
            throw SwiftDataError.deleteFailed(error.localizedDescription)
        }
    }

    /// Batch delete multiple todos
    /// - Parameter todos: Array of TodoItem to delete
    /// - Throws: SwiftDataError if delete fails
    func batchDelete(_ todos: [TodoItem]) throws {
        guard !todos.isEmpty else { return }

        for todo in todos {
            modelContext.delete(todo)
        }

        do {
            try modelContext.save()
        } catch {
            throw SwiftDataError.deleteFailed(error.localizedDescription)
        }
    }

    /// Delete all todos for a specific user
    /// - Parameter userId: The user ID whose todos will be deleted
    /// - Throws: SwiftDataError if delete fails
    func deleteAllTodos(userId: String) throws {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.userId == userId }
        )

        do {
            let todos = try modelContext.fetch(descriptor)
            for todo in todos {
                modelContext.delete(todo)
            }
            try modelContext.save()
        } catch {
            throw SwiftDataError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Sync State Operations

    /// Mark a todo as synced (clear needsSync flag)
    /// - Parameter todo: The TodoItem to mark as synced
    /// - Throws: SwiftDataError if update fails
    func markSynced(_ todo: TodoItem) throws {
        todo.needsSync = false
        try update(todo)
    }

    /// Batch mark multiple todos as synced
    /// - Parameter todos: Array of TodoItem to mark as synced
    /// - Throws: SwiftDataError if update fails
    func batchMarkSynced(_ todos: [TodoItem]) throws {
        for todo in todos {
            todo.needsSync = false
        }
        try update(todos.first ?? TodoItem(title: "", userId: ""))

        // Save all changes
        do {
            try modelContext.save()
        } catch {
            throw SwiftDataError.saveFailed(error.localizedDescription)
        }
    }

    // MARK: - Count Operations

    /// Count total todos for a user
    /// - Parameter userId: The user ID
    /// - Returns: Number of todos
    /// - Throws: SwiftDataError if count fails
    func countTodos(userId: String) throws -> Int {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.userId == userId }
        )

        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            throw SwiftDataError.fetchFailed(error.localizedDescription)
        }
    }

    /// Count active todos for a user
    /// - Parameter userId: The user ID
    /// - Returns: Number of active todos
    /// - Throws: SwiftDataError if count fails
    func countActiveTodos(userId: String) throws -> Int {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.userId == userId && $0.isCompleted == false }
        )

        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            throw SwiftDataError.fetchFailed(error.localizedDescription)
        }
    }

    /// Count completed todos for a user
    /// - Parameter userId: The user ID
    /// - Returns: Number of completed todos
    /// - Throws: SwiftDataError if count fails
    func countCompletedTodos(userId: String) throws -> Int {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.userId == userId && $0.isCompleted == true }
        )

        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            throw SwiftDataError.fetchFailed(error.localizedDescription)
        }
    }

    /// Count pending sync todos for a user
    /// - Parameter userId: The user ID
    /// - Returns: Number of todos needing sync
    /// - Throws: SwiftDataError if count fails
    func countPendingSync(userId: String) throws -> Int {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.userId == userId && $0.needsSync == true }
        )

        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            throw SwiftDataError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Utility Operations

    /// Clear all todos (useful for testing or logout)
    /// - Throws: SwiftDataError if clear fails
    func clearAllTodos() throws {
        let descriptor = FetchDescriptor<TodoItem>()

        do {
            let todos = try modelContext.fetch(descriptor)
            for todo in todos {
                modelContext.delete(todo)
            }
            try modelContext.save()
        } catch {
            throw SwiftDataError.deleteFailed(error.localizedDescription)
        }
    }

    /// Check if a todo exists by ID
    /// - Parameter todoId: The todo ID to check
    /// - Returns: true if todo exists
    /// - Throws: SwiftDataError if check fails
    func todoExists(todoId: String) throws -> Bool {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.id == todoId }
        )

        do {
            let count = try modelContext.fetchCount(descriptor)
            return count > 0
        } catch {
            throw SwiftDataError.fetchFailed(error.localizedDescription)
        }
    }
}

// MARK: - Shared Instance Factory

extension SwiftDataService {
    /// Create shared instance with ModelContext
    /// - Parameter modelContext: The SwiftData ModelContext
    /// - Returns: SwiftDataService instance
    static func shared(modelContext: ModelContext) -> SwiftDataService {
        return SwiftDataService(modelContext: modelContext)
    }
}
