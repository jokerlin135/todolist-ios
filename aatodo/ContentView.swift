import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [TodoItem]

    var body: some View {
        NavigationView {
            List {
                Text("aatodo - iOS To-Do List")
                    .font(.headline)
                Text("Models created!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("aatodo")
        }
    }
}
