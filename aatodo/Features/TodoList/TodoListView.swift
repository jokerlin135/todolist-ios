//
//  TodoListView.swift
//  aatodo
//
//  Todo list view with CRUD operations
//  Issue: aatodo-444.3
//

import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TodoViewModel
    @State private var showingAddTodo = false
    @State private var showingError = false
    @State private var editingTodo: TodoItem?

    init(viewModel: TodoViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.todos.isEmpty {
                emptyStateView
            } else {
                todoList
            }
        }
        .navigationTitle("Todos")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                addButton
            }
        }
        .sheet(isPresented: $showingAddTodo) {
            AddTodoSheet(viewModel: viewModel)
        }
        .sheet(item: $editingTodo) { todo in
            EditTodoSheet(todo: todo, viewModel: viewModel)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Unknown error")
        }
        .onAppear {
            // Load todos when view appears
            if let userId = viewModel.currentUserId {
                // Already loaded
            } else {
                // Need to set user first - this would come from AuthViewModel
                // For now, we'll rely on the MainTabView to set this up
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Loading todos...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Todos", systemImage: "checkmark.circle")
        } description: {
            Text("Tap + to create your first todo")
        } actions: {
            Button("Create Todo") {
                showingAddTodo = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Todo List

    private var todoList: some View {
        List {
            ForEach(viewModel.todos) { todo in
                Button {
                    editingTodo = todo
                } label: {
                    TodoRowView(
                        todo: todo,
                        onToggle: {
                            Task {
                                await viewModel.toggleCompletion(todo)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteTodo(todo)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadTodos()
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showingAddTodo = true
        } label: {
            Image(systemName: "plus")
        }
    }
}

// MARK: - Todo Row View

struct TodoRowView: View {
    let todo: TodoItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button {
                onToggle()
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(todo.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)

            // Title with strikethrough when completed
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.body)
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)

                Text(todo.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Add Todo Sheet

struct AddTodoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TodoViewModel
    @State private var title = ""
    @State private var isSaving = false

    init(viewModel: TodoViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Todo title", text: $title)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("Title")
                } footer: {
                    Text("Enter a title for your new todo")
                        .font(.caption)
                }
            }
            .navigationTitle("New Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTodo()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }

    private func saveTodo() {
        isSaving = true

        Task {
            await viewModel.addTodo(title: title)

            await MainActor.run {
                if viewModel.error == nil {
                    dismiss()
                }
                isSaving = false
            }
        }
    }
}

// MARK: - Edit Todo Sheet

struct EditTodoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var todo: TodoItem
    @State private var viewModel: TodoViewModel
    @State private var title = ""
    @State private var isSaving = false

    init(todo: TodoItem, viewModel: TodoViewModel) {
        self._todo = State(initialValue: todo)
        self._viewModel = State(initialValue: viewModel)
        self._title = State(initialValue: todo.title)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Todo title", text: $title)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("Title")
                } footer: {
                    Text("Update the todo title")
                        .font(.caption)
                }

                Section {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(todo.isCompleted ? "Completed" : "Active")
                            .foregroundStyle(.secondary)
                    }

                    Button(todo.isCompleted ? "Mark as Active" : "Mark as Completed") {
                        Task {
                            await viewModel.toggleCompletion(todo)
                        }
                    }
                }
            }
            .navigationTitle("Edit Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTodo()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }

    private func saveTodo() {
        isSaving = true

        Task {
            await viewModel.updateTodo(todo, title: title)

            await MainActor.run {
                if viewModel.error == nil {
                    dismiss()
                }
                isSaving = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TodoItem.self, configurations: config)
    let modelContext = container.mainContext

    // Add sample data
    let todo1 = TodoItem(title: "Buy groceries", userId: "preview-user")
    let todo2 = TodoItem(title: "Walk the dog", userId: "preview-user")
    todo2.markAsCompleted()

    modelContext.insert(todo1)
    modelContext.insert(todo2)

    let viewModel = TodoViewModel(modelContext: modelContext)
    viewModel.todos = [todo1, todo2]
    viewModel.currentUserId = "preview-user"

    return NavigationStack {
        TodoListView(viewModel: viewModel)
    }
    .modelContainer(container)
}
