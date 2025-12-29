//
//  TodoViewModel.swift
//  aatodo
//
//  Todo view model with Local-First sync
//  Issue: aatodo-444.2, aatodo-8oz.6
//

import Foundation
import SwiftData
import Observation

// MARK: - Todo Errors

/// Todo-specific errors
enum TodoError: LocalizedError {
    case notAuthenticated
    case networkError(String)
    case serverError(String)
    case invalidInput
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidInput:
            return "Invalid input. Please check your data and try again."
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        }
    }
}

// MARK: - Todo ViewModel

/// Todo view model using @Observable with Local-First sync
/// - Manages todo list state
/// - Handles CRUD operations via SyncService for Local-First behavior
/// - Shows sync status indicator
@Observable
final class TodoViewModel {
    // MARK: - Published Properties

    /// All todos for the current user
    var todos: [TodoItem] = []

    /// Loading state indicator
    var isLoading: Bool = false

    /// Error message
    var error: TodoError?

    /// Sync status for UI display
    var syncStatus: SyncStatus = .unknown

    /// Last successful sync time
    var lastSyncTime: Date? {
        syncService.lastSyncTime
    }

    /// Current user ID
    private var currentUserId: String?

    // MARK: - Sync Status

    /// Sync status states
    enum SyncStatus: CustomStringConvertible {
        case unknown
        case synced
        case syncing
        case offline

        var description: String {
            switch self {
            case .unknown:
                return "Unknown"
            case .synced:
                return "Synced"
            case .syncing:
                return "Syncing..."
            case .offline:
                return "Offline"
            }
        }
    }

    // MARK: - Dependencies

    private let syncService: SyncService

    // MARK: - Initialization

    init(syncService: SyncService) {
        self.syncService = syncService

        // Observe syncService.isSyncing changes
        observeSyncStatus()
    }

    // MARK: - Sync Status Observation

    /// Observe syncService for sync status changes
    private func observeSyncStatus() {
        // Initial sync status
        updateSyncStatus()

        // Observe isSyncing changes
        // Note: Since SyncService is @Observable, we can observe it
        // In a real implementation, we'd use proper observation
        Task {
            while !Task.isCancelled {
                await MainActor.run {
                    updateSyncStatus()
                }
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
    }

    /// Update sync status based on syncService state and network
    private func updateSyncStatus() {
        if syncService.isSyncing {
            self.syncStatus = .syncing
        } else if NetworkMonitor.shared.isConnected {
            self.syncStatus = .synced
        } else {
            self.syncStatus = .offline
        }
    }

    // MARK: - Setup

    /// Set the current user ID and load their todos
    /// - Parameter userId: The current user's ID
    func setCurrentUser(userId: String) {
        self.currentUserId = userId
        Task {
            await loadTodos()
        }
    }

    // MARK: - CRUD Operations (Local-First via SyncService)

    /// Load todos with Local-First strategy
    /// - Returns immediately from local storage, syncs in background
    func loadTodos() async {
        guard let userId = currentUserId else {
            await MainActor.run {
                self.error = .notAuthenticated
            }
            return
        }

        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }

        do {
            // SyncService.fetchTodos returns local data immediately
            let fetchedTodos = try await syncService.fetchTodos(userId: userId)

            await MainActor.run {
                self.todos = fetchedTodos
                self.isLoading = false
            }
        } catch let error as SyncError {
            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
                self.isLoading = false
            }
        }
    }

    /// Add a new todo with optimistic write
    /// - Parameter title: The todo title
    func addTodo(title: String) async {
        guard let userId = currentUserId else {
            await MainActor.run {
                self.error = .notAuthenticated
            }
            return
        }

        // Validate input
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            await MainActor.run {
                self.error = .invalidInput
            }
            return
        }

        do {
            // Create new TodoItem
            let newTodo = TodoItem(title: trimmedTitle, userId: userId)

            // SyncService saves locally first, uploads in background
            try await syncService.createTodo(newTodo)

            // Add to local state
            await MainActor.run {
                self.todos.append(newTodo)
                self.error = nil
            }
        } catch let error as SyncError {
            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
            }
        } catch {
            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
            }
        }
    }

    /// Toggle todo completion status with optimistic write
    /// - Parameter todo: The todo to toggle
    func toggleCompletion(_ todo: TodoItem) async {
        await MainActor.run {
            self.error = nil
        }

        do {
            // Toggle completion
            if todo.isCompleted {
                todo.markAsUncompleted()
            } else {
                todo.markAsCompleted()
            }

            // SyncService updates locally first, uploads in background
            try await syncService.updateTodo(todo)
        } catch let error as SyncError {
            // Revert on error
            if todo.isCompleted {
                todo.markAsUncompleted()
            } else {
                todo.markAsCompleted()
            }

            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
            }
        } catch {
            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
            }
        }
    }

    /// Delete a todo with optimistic write
    /// - Parameter todo: The todo to delete
    func deleteTodo(_ todo: TodoItem) async {
        await MainActor.run {
            self.error = nil
        }

        do {
            // SyncService deletes locally first, uploads in background
            try await syncService.deleteTodo(todo)

            // Remove from local state
            await MainActor.run {
                self.todos.removeAll { $0.id == todo.id }
            }
        } catch let error as SyncError {
            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
            }
        } catch {
            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
            }
        }
    }

    /// Update todo title with optimistic write
    /// - Parameters:
    ///   - todo: The todo to update
    ///   - newTitle: The new title
    func updateTodo(_ todo: TodoItem, title newTitle: String) async {
        // Validate input
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            await MainActor.run {
                self.error = .invalidInput
            }
            return
        }

        await MainActor.run {
            self.error = nil
        }

        // Save old title for revert
        let oldTitle = todo.title

        do {
            // Update locally first
            todo.updateTitle(trimmedTitle)

            // SyncService updates locally first, uploads in background
            try await syncService.updateTodo(todo)
        } catch let error as SyncError {
            // Revert on error
            todo.title = oldTitle
            todo.updatedAt = Date()

            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
            }
        } catch {
            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
            }
        }
    }

    /// Upload pending changes to server
    func uploadPending() async {
        guard let userId = currentUserId else {
            return
        }

        do {
            try await syncService.uploadPending(userId: userId)
        } catch {
            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Computed Properties

    /// Active todos (not completed)
    var activeTodos: [TodoItem] {
        todos.filter { !$0.isCompleted }
    }

    /// Completed todos
    var completedTodos: [TodoItem] {
        todos.filter { $0.isCompleted }
    }

    /// Count of active todos
    var activeCount: Int {
        activeTodos.count
    }

    /// Count of completed todos
    var completedCount: Int {
        completedTodos.count
    }

    /// Count of todos pending sync
    var pendingSyncCount: Int {
        guard let userId = currentUserId else { return 0 }
        return (try? syncService.countPendingSync(userId: userId)) ?? 0
    }

    // MARK: - Helpers

    /// Clear the current error
    func clearError() {
        self.error = nil
    }
}
