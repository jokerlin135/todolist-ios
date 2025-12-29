//
//  TodoViewModel.swift
//  aatodo
//
//  Todo view model with basic state management
//  Issue: aatodo-444.2
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

/// Todo view model using @Observable
/// - Manages todo list state
/// - Handles CRUD operations via SupabaseService
/// - Direct Supabase calls (no sync layer yet)
@Observable
final class TodoViewModel {
    // MARK: - Published Properties

    /// All todos for the current user
    var todos: [TodoItem] = []

    /// Loading state indicator
    var isLoading: Bool = false

    /// Error message
    var error: TodoError?

    /// Current user ID
    private var currentUserId: String?

    // MARK: - Dependencies

    private let supabaseService: SupabaseService
    private let modelContext: ModelContext

    // MARK: - Initialization

    init(
        supabaseService: SupabaseService = SupabaseService.shared,
        modelContext: ModelContext
    ) {
        self.supabaseService = supabaseService
        self.modelContext = modelContext
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

    // MARK: - CRUD Operations

    /// Load todos from Supabase
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
            // Fetch from Supabase
            let supabaseTodos = try await supabaseService.fetchTodos(userId: userId)

            // Convert to TodoItem and save to SwiftData
            await MainActor.run {
                // Clear existing todos from context
                let descriptor = FetchDescriptor<TodoItem>()
                let existingTodos = (try? modelContext.fetch(descriptor)) ?? []
                for todo in existingTodos {
                    modelContext.delete(todo)
                }

                // Insert new todos
                self.todos = []
                for supabaseTodo in supabaseTodos {
                    let todoItem = TodoItem(from: supabaseTodo)
                    modelContext.insert(todoItem)
                    self.todos.append(todoItem)
                }

                try? modelContext.save()
                self.isLoading = false
            }
        } catch let error as SupabaseError {
            await MainActor.run {
                self.error = .networkError(error.localizedDescription)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
                self.isLoading = false
            }
        }
    }

    /// Add a new todo
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

        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }

        do {
            // Create new TodoItem
            let newTodo = TodoItem(title: trimmedTitle, userId: userId)

            // Send to Supabase
            try await supabaseService.createTodo(newTodo)

            // Add to local state and SwiftData
            await MainActor.run {
                modelContext.insert(newTodo)
                self.todos.append(newTodo)
                try? modelContext.save()
                self.isLoading = false
            }
        } catch let error as SupabaseError {
            await MainActor.run {
                self.error = .networkError(error.localizedDescription)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
                self.isLoading = false
            }
        }
    }

    /// Toggle todo completion status
    /// - Parameter todo: The todo to toggle
    func toggleCompletion(_ todo: TodoItem) async {
        await MainActor.run {
            self.error = nil
        }

        do {
            // Toggle locally first for optimistic UI
            let newCompletedState = !todo.isCompleted
            if newCompletedState {
                todo.markAsCompleted()
            } else {
                todo.markAsUncompleted()
            }

            // Update in Supabase
            try await supabaseService.updateTodo(todo)

            // Save to SwiftData
            await MainActor.run {
                try? modelContext.save()
            }
        } catch let error as SupabaseError {
            // Revert on error
            if todo.isCompleted {
                todo.markAsUncompleted()
            } else {
                todo.markAsCompleted()
            }

            await MainActor.run {
                self.error = .networkError(error.localizedDescription)
            }
        } catch {
            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
            }
        }
    }

    /// Delete a todo
    /// - Parameter todo: The todo to delete
    func deleteTodo(_ todo: TodoItem) async {
        await MainActor.run {
            self.error = nil
        }

        do {
            // Delete from Supabase
            try await supabaseService.deleteTodo(todoId: todo.id)

            // Remove from local state and SwiftData
            await MainActor.run {
                modelContext.delete(todo)
                self.todos.removeAll { $0.id == todo.id }
                try? modelContext.save()
            }
        } catch let error as SupabaseError {
            await MainActor.run {
                self.error = .networkError(error.localizedDescription)
            }
        } catch {
            await MainActor.run {
                self.error = .operationFailed(error.localizedDescription)
            }
        }
    }

    /// Update todo title
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
            // Update locally first for optimistic UI
            todo.updateTitle(trimmedTitle)

            // Update in Supabase
            try await supabaseService.updateTodo(todo)

            // Save to SwiftData
            await MainActor.run {
                try? modelContext.save()
            }
        } catch let error as SupabaseError {
            // Revert on error
            todo.title = oldTitle
            todo.updatedAt = Date()

            await MainActor.run {
                self.error = .networkError(error.localizedDescription)
            }
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

    // MARK: - Helpers

    /// Clear the current error
    func clearError() {
        self.error = nil
    }
}
