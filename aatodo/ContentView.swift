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
                Text("Project structure ready!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("aatodo")
        }
    }
}

// Placeholder TodoItem model - will be implemented in aatodo-83o.1
@Model
final class TodoItem {
    var id: String
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var userId: String
    var needsSync: Bool

    init(title: String, userId: String) {
        self.id = UUID().uuidString
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.userId = userId
        self.needsSync = true
    }
}
