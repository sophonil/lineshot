import Foundation
import Combine

struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var completed: Bool

    init(id: UUID = UUID(), text: String, completed: Bool = false) {
        self.id = id
        self.text = text
        self.completed = completed
    }
}

/// Kept separately from clippings: clearing the line or expiring screenshots
/// can never remove the pinned notebook. No files enter the screenshot watcher.
@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var items: [TodoItem] = []
    @Published var notes = "" { didSet { save() } }

    private struct Document: Codable {
        var items: [TodoItem]
        var notes: String
    }
    private let defaults: UserDefaults
    private let key = "todoNotebook.v1"

    var pending: [TodoItem] { items.filter { !$0.completed } }
    var completedCount: Int { items.filter(\.completed).count }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let document = try? JSONDecoder().decode(Document.self, from: data) {
            items = document.items
            notes = document.notes
        }
    }

    @discardableResult
    func add(_ text: String) -> Bool {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }
        items.append(TodoItem(text: text))
        save()
        return true
    }

    func toggle(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].completed.toggle()
        save()
    }

    func update(_ id: UUID, text: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].text = text
        save()
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func clearCompleted() {
        items.removeAll(where: \.completed)
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(Document(items: items, notes: notes)) else { return }
        defaults.set(data, forKey: key)
    }
}
