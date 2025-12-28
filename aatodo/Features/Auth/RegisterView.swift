//
//  RegisterView.swift
//  aatodo
//
//  Registration view with validation
//  Issue: aatodo-83o.3
//

import SwiftUI

struct RegisterView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AuthViewModel

    // MARK: - State

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var validationMessage = ""

    // Validation states
    private var isValidEmail: Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    private var isPasswordValid: Bool {
        password.count >= 8
    }

    private var doPasswordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    private var isValidForm: Bool {
        isValidEmail && isPasswordValid && doPasswordsMatch
    }

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

                ScrollView {
                    VStack(spacing: 24) {
                        Spacer()

                        // Logo/Title
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.blue)

                            Text("Create Account")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("Sign up to get started")
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

                                    if !email.isEmpty {
                                        Image(systemName: isValidEmail ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(isValidEmail ? .green : .red)
                                    }
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

                                    if !password.isEmpty {
                                        Image(systemName: isPasswordValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(isPasswordValid ? .green : .red)
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)

                                // Password requirement hint
                                if !password.isEmpty && !isPasswordValid {
                                    Text("Password must be at least 8 characters")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }

                            // Confirm Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                HStack {
                                    Image(systemName: "lock.shield")
                                        .foregroundStyle(.secondary)

                                    SecureField("Confirm your password", text: $confirmPassword)

                                    if !confirmPassword.isEmpty {
                                        Image(systemName: doPasswordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(doPasswordsMatch ? .green : .red)
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)

                                // Password match hint
                                if !confirmPassword.isEmpty && !doPasswordsMatch {
                                    Text("Passwords do not match")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding(.horizontal)

                        Spacer()

                        // Sign Up button
                        Button(action: signUp) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                    Image(systemName: "person.badge.plus")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValidForm ? .blue : .gray)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .disabled(!isValidForm || viewModel.isLoading)

                        // Terms
                        Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Sign In link
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Button("Sign In") {
                                dismiss()
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        }

                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Sign Up")
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
                    title: Text(validationMessage.isEmpty ? "Registration Error" : "Validation Error"),
                    message: Text(validationMessage.isEmpty ? (viewModel.errorMessage ?? "An unknown error occurred") : validationMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: viewModel.authState) { _, newState in
                if case .authenticated = newState {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Actions

    private func signUp() {
        // Validate form
        guard isValidEmail else {
            validationMessage = "Please enter a valid email address"
            showingAlert = true
            return
        }

        guard isPasswordValid else {
            validationMessage = "Password must be at least 8 characters"
            showingAlert = true
            return
        }

        guard doPasswordsMatch else {
            validationMessage = "Passwords do not match"
            showingAlert = true
            return
        }

        // Proceed with sign up
        Task {
            await viewModel.signUpWithEmail(email: email, password: password)
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

    return RegisterView(viewModel: viewModel)
}
