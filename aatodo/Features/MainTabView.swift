//
//  MainTabView.swift
//  aatodo
//
//  Main tab view for authenticated users
//  Issue: aatodo-83o.4
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [TodoItem]

    var body: some View {
        TabView {
            // Todos Tab
            TodoListView()
                .tabItem {
                    Label("Todos", systemImage: "checkmark.circle")
                }

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Todo List View Placeholder

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [TodoItem]

    var body: some View {
        NavigationStack {
            List {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("No Todos", systemImage: "checkmark.circle")
                    } description: {
                        Text("Create your first todo to get started")
                    }
                } else {
                    ForEach(items) { item in
                        HStack {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isCompleted ? .green : .gray)
                                .onTapGesture {
                                    toggleTodo(item)
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .strikethrough(item.isCompleted)
                                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                                Text(item.updatedAt, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteTodos)
                }
            }
            .navigationTitle("Todos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // TODO: Add new todo
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func toggleTodo(_ item: TodoItem) {
        withAnimation {
            if item.isCompleted {
                item.markAsUncompleted()
            } else {
                item.markAsCompleted()
            }
        }
    }

    private func deleteTodos(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

// MARK: - Settings View Placeholder

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading) {
                            Text("Signed In")
                                .font(.subheadline)
                            Text("User ID: \(authViewModel.currentUser?.id ?? "Unknown")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task {
                            await authViewModel.signOut()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundStyle(.red)
                            Text("Sign Out")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TodoItem.self, configurations: config)

    // Add sample data
    let context = container.mainContext
    let sample = TodoItem(title: "Sample Todo", userId: "test-user")
    context.insert(sample)

    return MainTabView()
        .modelContainer(container)
}
