//
//  AuthViewModel.swift
//  aatodo
//
//  Authentication view model with session lifecycle
//  Issue: aatodo-83o.2
//

import Foundation
import SwiftData
import Observation

// TODO: Uncomment after adding Supabase package
// import Supabase
// import Auth

/// Authentication state
enum AuthState {
    case unknown
    case authenticated
    case unauthenticated
    case loading
    case error(String)
}

/// Authentication view model using @Observable
/// - Manages authentication state and session lifecycle
/// - Handles cold start session check
/// - Handles token refresh with error recovery
@Observable
final class AuthViewModel {
    // MARK: - Published Properties

    /// Current authentication state
    var authState: AuthState = .unknown

    /// Loading state indicator
    var isLoading: Bool = false

    /// Current authenticated user
    var currentUser: UserInfo?

    /// Error message
    var errorMessage: String?

    // MARK: - Dependencies

    private let keychainService: KeychainService
    private let modelContext: ModelContext

    // TODO: Uncomment after adding Supabase package
    // private let supabaseService: SupabaseService

    // MARK: - Initialization

    init(
        keychainService: KeychainService = KeychainService.shared,
        modelContext: ModelContext
    ) {
        self.keychainService = keychainService
        self.modelContext = modelContext
        // TODO: Uncomment after adding Supabase package
        // self.supabaseService = SupabaseService.shared
    }

    // MARK: - Session Lifecycle

    /// Check for existing session on app launch (Cold Start)
    /// Flow: Check Keychain → if exists, validate → if expired, attempt refresh
    func checkSession() async {
        await MainActor.run {
            authState = .loading
            isLoading = true
        }

        do {
            // Check if we have a stored access token
            if let accessToken = try await keychainService.getToken(forKey: KeychainService.TokenKey.accessToken) {
                // TODO: Validate token with Supabase
                // For now, assume valid if present
                await MainActor.run {
                    authState = .authenticated
                    isLoading = false
                }
            } else {
                // No token found, check if we have refresh token
                if let refreshToken = try await keychainService.getToken(forKey: KeychainService.TokenKey.refreshToken) {
                    // Attempt to refresh using refresh token
                    do {
                        // TODO: Call Supabase refresh endpoint
                        // For now, just mark as unauthenticated
                        await MainActor.run {
                            authState = .unauthenticated
                            isLoading = false
                        }
                    } catch {
                        // Refresh token invalid or revoked
                        await handleTokenRefreshError(error)
                    }
                } else {
                    // No tokens at all
                    await MainActor.run {
                        authState = .unauthenticated
                        isLoading = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                authState = .unauthenticated
                isLoading = false
            }
        }
    }

    // MARK: - Sign In Methods

    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    func signInWithEmail(email: String, password: String) async {
        await MainActor.run {
            authState = .loading
            isLoading = true
            errorMessage = nil
        }

        do {
            // TODO: Implement Supabase auth sign in
            // let session = try await supabaseService.client.auth.signIn(email: email, password: password)

            // Mock implementation for now
            await MainActor.run {
                authState = .authenticated
                isLoading = false
            }
        } catch {
            await MainActor.run {
                authState = .error(error.localizedDescription)
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Sign up with email and password
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    func signUpWithEmail(email: String, password: String) async {
        await MainActor.run {
            authState = .loading
            isLoading = true
            errorMessage = nil
        }

        do {
            // TODO: Implement Supabase auth sign up
            // let session = try await supabaseService.client.auth.signUp(email: email, password: password)

            // Mock implementation for now
            await MainActor.run {
                authState = .authenticated
                isLoading = false
            }
        } catch {
            await MainActor.run {
                authState = .error(error.localizedDescription)
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Sign in with Google OAuth
    func signInWithGoogle() async {
        await MainActor.run {
            authState = .loading
            isLoading = true
            errorMessage = nil
        }

        do {
            // TODO: Implement Google OAuth flow
            // This requires setting up Google Sign-In SDK
            // and handling the OAuth callback

            // Mock implementation for now
            await MainActor.run {
                authState = .authenticated
                isLoading = false
            }
        } catch {
            await MainActor.run {
                authState = .error(error.localizedDescription)
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Sign Out

    /// Sign out and cleanup
    /// Flow: Call Supabase logout → Clear Keychain → Delete user's local todos
    func signOut() async {
        await MainActor.run {
            isLoading = true
        }

        do {
            // TODO: Call Supabase logout
            // try await supabaseService.client.auth.signOut()

            // Clear tokens from Keychain
            try await keychainService.deleteToken(forKey: KeychainService.TokenKey.accessToken)
            try await keychainService.deleteToken(forKey: KeychainService.TokenKey.refreshToken)
            try await keychainService.deleteToken(forKey: KeychainService.TokenKey.userId)
            try await keychainService.deleteToken(forKey: KeychainService.TokenKey.userEmail)

            // Delete user's local todos (SwiftData)
            await deleteUserLocalTodos()

            await MainActor.run {
                authState = .unauthenticated
                currentUser = nil
                isLoading = false
            }
        } catch {
            await MainActor.run {
                authState = .error(error.localizedDescription)
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Private Methods

    /// Handle token refresh error
    /// Force logout if refresh token is revoked or invalid
    private func handleTokenRefreshError(_ error: Error) async {
        // Clear invalid tokens
        try? await keychainService.deleteToken(forKey: KeychainService.TokenKey.accessToken)
        try? await keychainService.deleteToken(forKey: KeychainService.TokenKey.refreshToken)

        await MainActor.run {
            authState = .unauthenticated
            isLoading = false
            currentUser = nil
            errorMessage = "Session expired. Please sign in again."
        }
    }

    /// Delete user's local todos from SwiftData
    private func deleteUserLocalTodos() async {
        do {
            // TODO: Delete all TodoItems for current user
            // let descriptor = FetchDescriptor<TodoItem>(
            //     predicate: #Predicate { $0.userId == currentUserId }
            // )
            // let userTodos = try modelContext.fetch(descriptor)
            // for todo in userTodos {
            //     modelContext.delete(todo)
            // }
            // try modelContext.save()
        } catch {
            print("Error deleting local todos: \(error)")
        }
    }
}

// MARK: - User Info

/// User information structure
struct UserInfo {
    let id: String
    let email: String
    let name: String?

    init(id: String, email: String, name: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
    }
}
