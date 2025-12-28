//
//  AuthView.swift
//  aatodo
//
//  Authentication container view
//  Issue: aatodo-83o.3
//

import SwiftUI

struct AuthView: View {
    @State private var viewModel: AuthViewModel
    @State private var showingLogin = true

    init(viewModel: AuthViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if showingLogin {
                LoginView(viewModel: viewModel)
            } else {
                RegisterView(viewModel: viewModel)
            }
        }
        .onAppear {
            // Check for existing session on appear
            Task {
                await viewModel.checkSession()
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

    return AuthView(viewModel: viewModel)
}
