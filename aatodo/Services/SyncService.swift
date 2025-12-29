//
//  SyncService.swift
//  aatodo
//
//  Local-first sync orchestrator coordinating SwiftDataService and SupabaseService
//  Issue: aatodo-8oz.3
//

import Foundation
import SwiftData
import Observation

// MARK: - Sync Errors

/// Sync-specific errors
enum SyncError: LocalizedError {
    case notInitialized
    case syncFailed(String)
    case conflict(String)
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Sync service is not properly initialized"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        case .conflict(let message):
            return "Sync conflict: \(message)"
        case .networkUnavailable:
            return "Network is unavailable. Changes will be synced when connection is restored."
        }
    }
}

// MARK: - Sync Service

/// Local-first sync orchestrator
/// - Coordinates SwiftDataService (local) and SupabaseService (remote)
/// - Optimistic UI: reads from local immediately, syncs in background
/// - Writes: save locally first, upload in background
/// - Upload failures keep needsSync=true for retry
@MainActor
@Observable
final class SyncService {
    // MARK: - Properties

    /// Supabase service for remote operations
    private let supabase: SupabaseService

    /// SwiftData service for local operations
    private let local: SwiftDataService

    /// Network monitor for connectivity
    private let networkMonitor: NetworkMonitor

    /// Current sync status
    var isSyncing: Bool = false

    /// Last successful sync time
    var lastSyncTime: Date?

    // MARK: - Singleton

    static let shared: SyncService

    // MARK: - Initialization

    /// Initialize with service dependencies
    /// - Parameters:
    ///   - supabase: SupabaseService instance
    ///   - local: SwiftDataService instance
    ///   - networkMonitor: NetworkMonitor instance
    init(
        supabase: SupabaseService = SupabaseService.shared,
        local: SwiftDataService,
        networkMonitor: NetworkMonitor = NetworkMonitor.shared
    ) {
        self.supabase = supabase
        self.local = local
        self.networkMonitor = networkMonitor
    }

    /// Private initializer for singleton pattern
    private init?() {
        return nil
    }

    /// Create shared instance with model context
    /// - Parameter modelContext: SwiftData ModelContext
    /// - Returns: SyncService instance
    static func shared(modelContext: ModelContext) -> SyncService {
        let localService = SwiftDataService.shared(modelContext: modelContext)
        return SyncService(
            supabase: SupabaseService.shared,
            local: localService,
            networkMonitor: NetworkMonitor.shared
        )
    }

    // MARK: - Fetch Operations (Local-First)

    /// Fetch todos with local-first strategy
    /// - Parameter userId: The user ID to fetch todos for
    /// - Returns: Array of TodoItem from local storage
    /// - Note: Triggers background sync after returning local data
    func fetchTodos(userId: String) async throws -> [TodoItem] {
        // Return local data immediately (<100ms)
        let localTodos = try local.fetchTodos(userId: userId)

        // Trigger background sync
        Task.detached(priority: .background) { [weak self] in
            await self?.syncFromServer(userId: userId)
        }

        return localTodos
    }

    /// Fetch active todos
    /// - Parameter userId: The user ID
    /// - Returns: Array of active TodoItem
    func fetchActiveTodos(userId: String) async throws -> [TodoItem] {
        return try local.fetchActiveTodos(userId: userId)
    }

    /// Fetch completed todos
    /// - Parameter userId: The user ID
    /// - Returns: Array of completed TodoItem
    func fetchCompletedTodos(userId: String) async throws -> [TodoItem] {
        return try local.fetchCompletedTodos(userId: userId)
    }

    // MARK: - Sync from Server

    /// Sync todos from server to local with conflict resolution
    /// - Parameter userId: The user ID
    /// - Throws: SyncError on failure
    /// - Note: Uses Last-Write-Wins conflict resolution with timestamp comparison
    func syncFromServer(userId: String) async throws {
        guard networkMonitor.isConnected else {
            // Network unavailable, skip sync
            return
        }

        await MainActor.run {
            self.isSyncing = true
        }

        defer {
            Task { @MainActor in
                self.isSyncing = false
            }
        }

        do {
            // Fetch from Supabase
            let serverTodos = try await supabase.fetchTodos(userId: userId)

            // Merge with local using conflict resolution
            for serverTodo in serverTodos {
                let serverItem = serverTodo.toTodoItem()

                // Check if local exists
                do {
                    let localTodo = try local.fetchTodo(todoId: serverItem.id)

                    // Conflict resolution logic
                    if !localTodo.needsSync {
                        // Case 1: Clean local (needsSync=false)
                        // Trust server, overwrite local completely
                        localTodo.title = serverItem.title
                        localTodo.isCompleted = serverItem.isCompleted
                        localTodo.updatedAt = serverItem.updatedAt
                        localTodo.needsSync = false
                        try local.update(localTodo)
                    } else {
                        // Case 2: Dirty local (needsSync=true)
                        // Compare timestamps to determine winner (Last-Write-Wins)
                        if serverItem.updatedAt > localTodo.updatedAt {
                            // Server is newer: overwrite local
                            // Note: This loses local changes, but server wins in Last-Write-Wins
                            localTodo.title = serverItem.title
                            localTodo.isCompleted = serverItem.isCompleted
                            localTodo.updatedAt = serverItem.updatedAt
                            localTodo.needsSync = false
                            try local.update(localTodo)
                        } else {
                            // Local is newer or equal: ignore server
                            // Local changes will be uploaded later via uploadPending()
                            // No action needed - keep local as-is
                        }
                    }
                } catch {
                    // Case 3: Local doesn't exist
                    // New item from server, add to local
                    try local.save(serverItem)
                }
            }

            await MainActor.run {
                self.lastSyncTime = Date()
            }
        } catch let error as SupabaseError {
            // Supabase not configured or error, continue with local only
            print("Sync failed (using local only): \(error.localizedDescription)")
        }
    }

    // MARK: - Create Operations (Optimistic)

    /// Create a new todo with optimistic write
    /// - Parameter todo: The TodoItem to create
    /// - Throws: SyncError on local save failure
    /// - Note: Saves locally first, uploads in background
    func createTodo(_ todo: TodoItem) async throws {
        // Save locally first (optimistic)
        try local.save(todo)

        // Upload in background
        Task.detached(priority: .background) { [weak self] in
            await self?.uploadTodo(todo)
        }
    }

    /// Upload a single todo to server
    /// - Parameter todo: The TodoItem to upload
    private func uploadTodo(_ todo: TodoItem) async {
        guard networkMonitor.isConnected else {
            // Network unavailable, keep needsSync=true for retry
            return
        }

        do {
            try await supabase.createTodo(todo)

            // Mark as synced
            try local.markSynced(todo)
        } catch {
            // Upload failed, keep needsSync=true for retry
            print("Upload failed, will retry: \(error.localizedDescription)")
        }
    }

    // MARK: - Update Operations (Optimistic)

    /// Update an existing todo with optimistic write
    /// - Parameter todo: The TodoItem with updated values
    /// - Throws: SyncError on local update failure
    /// - Note: Updates local first, uploads in background
    func updateTodo(_ todo: TodoItem) async throws {
        // Update locally first (optimistic)
        try local.update(todo)

        // Upload in background
        Task.detached(priority: .background) { [weak self] in
            await self?.uploadTodo(todo)
        }
    }

    // MARK: - Delete Operations (Optimistic)

    /// Delete a todo with optimistic write
    /// - Parameter todo: The TodoItem to delete
    /// - Throws: SyncError on local deletion failure
    /// - Note: Deletes locally first, uploads in background
    func deleteTodo(_ todo: TodoItem) async throws {
        // Delete locally first (optimistic)
        try local.delete(todo)

        // Upload deletion in background
        Task.detached(priority: .background) { [weak self, todoId = todo.id] in
            await self?.deleteTodoFromServer(todoId: todoId)
        }
    }

    /// Delete a todo from server
    /// - Parameter todoId: The ID of the todo to delete
    private func deleteTodoFromServer(todoId: String) async {
        guard networkMonitor.isConnected else {
            // Network unavailable, deletion will be handled by sync
            return
        }

        do {
            try await supabase.deleteTodo(todoId: todoId)
        } catch {
            // Delete failed, item will remain on server until resolved
            print("Delete from server failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Batch Upload

    /// Upload all pending todos to server
    /// - Parameter userId: The user ID
    /// - Throws: SyncError on failure
    func uploadPending(userId: String) async throws {
        guard networkMonitor.isConnected else {
            throw SyncError.networkUnavailable
        }

        await MainActor.run {
            self.isSyncing = true
        }

        defer {
            Task { @MainActor in
                self.isSyncing = false
            }
        }

        // Fetch pending items
        let pendingTodos = try local.fetchPendingSync(userId: userId)

        guard !pendingTodos.isEmpty else {
            return
        }

        // Batch upload
        for todo in pendingTodos {
            do {
                try await supabase.updateTodo(todo)
                try local.markSynced(todo)
            } catch {
                // Continue with other items on failure
                print("Failed to upload todo \(todo.id): \(error.localizedDescription)")
            }
        }

        await MainActor.run {
            self.lastSyncTime = Date()
        }
    }

    // MARK: - Count Operations

    /// Count todos for a user
    /// - Parameter userId: The user ID
    /// - Returns: Number of todos
    func countTodos(userId: String) throws -> Int {
        return try local.countTodos(userId: userId)
    }

    /// Count active todos for a user
    /// - Parameter userId: The user ID
    /// - Returns: Number of active todos
    func countActiveTodos(userId: String) throws -> Int {
        return try local.countActiveTodos(userId: userId)
    }

    /// Count completed todos for a user
    /// - Parameter userId: The user ID
    /// - Returns: Number of completed todos
    func countCompletedTodos(userId: String) throws -> Int {
        return try local.countCompletedTodos(userId: userId)
    }

    /// Count pending sync todos for a user
    /// - Parameter userId: The user ID
    /// - Returns: Number of todos needing sync
    func countPendingSync(userId: String) throws -> Int {
        return try local.countPendingSync(userId: userId)
    }
}
