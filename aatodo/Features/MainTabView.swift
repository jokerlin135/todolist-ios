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
    @State private var authViewModel: AuthViewModel
    @State private var todoViewModel: TodoViewModel?

    init(authViewModel: AuthViewModel) {
        self._authViewModel = State(initialValue: authViewModel)
    }

    var body: some View {
        TabView {
            // Todos Tab
            if let todoViewModel = todoViewModel {
                NavigationStack {
                    TodoListView(viewModel: todoViewModel)
                }
                .tabItem {
                    Label("Todos", systemImage: "checkmark.circle")
                }
            } else {
                ProgressView("Loading...")
                    .tabItem {
                        Label("Todos", systemImage: "checkmark.circle")
                    }
            }

            // Settings Tab
            SettingsView(authViewModel: authViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .task {
            // Initialize TodoViewModel when view appears
            if todoViewModel == nil {
                // Create SyncService first
                let syncService = SyncService.shared(modelContext: modelContext)

                // Create TodoViewModel with SyncService
                let viewModel = TodoViewModel(syncService: syncService)

                // Set current user ID if available
                if let userId = authViewModel.currentUser?.id {
                    viewModel.setCurrentUser(userId: userId)
                }

                self.todoViewModel = viewModel
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    let authViewModel: AuthViewModel

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
                            if let user = authViewModel.currentUser {
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
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

    let keychain = KeychainService.shared
    let modelContext = container.mainContext
    let authViewModel = AuthViewModel(keychainService: keychain, modelContext: modelContext)

    // Create SyncService for preview
    let syncService = SyncService.shared(modelContext: modelContext)

    // Create TodoViewModel with SyncService
    // Note: In preview, we won't set current user, so it will show empty state

    return MainTabView(authViewModel: authViewModel)
        .modelContainer(container)
}
