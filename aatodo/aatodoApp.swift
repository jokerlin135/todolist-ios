//
//  aatodoApp.swift
//  aatodo
//
//  Main app entry point with auth routing
//  Issue: aatodo-83o.4
//

import SwiftUI
import SwiftData

@main
struct aatodoApp: App {
    // MARK: - SwiftData ModelContainer

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([TodoItem.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Enable File Protection on database file
            // This encrypts the database when device is locked
            if let url = modelConfiguration.url {
                let attributes = [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
                try FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
            }

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Auth State

    @State private var authViewModel: AuthViewModel?

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            Group {
                if let authViewModel = authViewModel {
                    // Route based on authentication state
                    switch authViewModel.authState {
                    case .authenticated:
                        // User is logged in - show main app
                        MainTabView(authViewModel: authViewModel)
                            .environment(authViewModel)
                    case .unauthenticated, .unknown:
                        // User is not logged in - show auth flow
                        AuthView(viewModel: authViewModel)
                    case .loading:
                        // Showing initial loading state
                        LoadingView()
                    case .error(let message):
                        // Show error state
                        ErrorView(message: message) {
                            // Retry action
                            Task {
                                await authViewModel.checkSession()
                            }
                        }
                    }
                } else {
                    // AuthViewModel not yet initialized
                    ProgressView("Loading...")
                }
            }
            .task {
                // Start network monitoring
                NetworkMonitor.shared.start()

                // Initialize AuthViewModel and check session on app launch
                if authViewModel == nil {
                    let modelContext = sharedModelContainer.mainContext
                    authViewModel = AuthViewModel(
                        keychainService: KeychainService.shared,
                        modelContext: modelContext
                    )
                }

                // Check for existing session
                await authViewModel?.checkSession()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Loading...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)

                VStack(spacing: 8) {
                    Text("Something went wrong")
                        .font(.headline)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button("Retry") {
                    retry()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
