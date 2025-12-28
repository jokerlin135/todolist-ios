//
//  LoginView.swift
//  aatodo
//
//  Login view with email/password and Google OAuth
//  Issue: aatodo-83o.3
//

import SwiftUI

struct LoginView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AuthViewModel

    // MARK: - State

    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    @State private var showingAlert = false

    // MARK: - Initialization

    init(viewModel: AuthViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // Logo/Title
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        Text("aatodo")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Form
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundStyle(.secondary)

                                TextField("Enter your email", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                Image(systemName: "lock")
                                    .foregroundStyle(.secondary)

                                SecureField("Enter your password", text: $password)

                                Spacer()
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Sign In button
                    Button(action: signInWithEmail) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(email.isEmpty || password.isEmpty ? .gray : .blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)

                    // Divider
                    HStack {
                        VStack { Divider() }

                        Text("or continue with")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VStack { Divider() }
                    }
                    .padding(.horizontal)

                    // Google Sign-In button
                    Button(action: signInWithGoogle) {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.title3)

                            Text("Sign in with Google")
                                .fontWeight(.medium)

                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .foregroundStyle(.black)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .disabled(viewModel.isLoading)

                    // Register link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Sign Up") {
                            showingRegister = true
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Authentication Error"),
                    message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: viewModel.authState) { _, newState in
                if case .authenticated = newState {
                    dismiss()
                }
            }
            .navigationDestination(isPresented: $showingRegister) {
                RegisterView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Actions

    private func signInWithEmail() {
        Task {
            await viewModel.signInWithEmail(email: email, password: password)
            if case .error = viewModel.authState {
                showingAlert = true
            }
        }
    }

    private func signInWithGoogle() {
        Task {
            await viewModel.signInWithGoogle()
            if case .error = viewModel.authState {
                showingAlert = true
            }
        }
    }
}

#Preview {
    let config = SupabaseConfig(
        supabaseURL: "https://test.supabase.co",
        supabaseKey: "test-key"
    )
    let keychain = KeychainService.shared
    let modelContext = try! ModelContainer(for: TodoItem.self).mainContext
    let viewModel = AuthViewModel(keychainService: keychain, modelContext: modelContext)

    return LoginView(viewModel: viewModel)
}
