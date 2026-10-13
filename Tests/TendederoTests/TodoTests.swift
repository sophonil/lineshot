import AppKit
import XCTest
@testable import Tendedero

final class TodoTests: XCTestCase {
    func testAddsTasksAndRestoresNotesAndStableIDs() async {
        await MainActor.run {
            let suite = "TodoTests.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let store = TodoStore(defaults: defaults)
            XCTAssertFalse(store.add(" \n\t"))
            XCTAssertTrue(store.add("  完成设计 🧺  "))
            store.notes = "灵感\n  保留缩进与换行\n"
            let restored = TodoStore(defaults: defaults)
            XCTAssertEqual(restored.items, store.items)
            XCTAssertEqual(restored.items.first?.text, "完成设计 🧺")
            XCTAssertEqual(restored.notes, store.notes)
            XCTAssertEqual(restored.pending.count, 1)
        }
    }

    func testCompletionEditingAndRemovalPersistWithoutAffectingNotes() async {
        await MainActor.run {
            let suite = "TodoTests.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let store = TodoStore(defaults: defaults)
            store.add("First"); store.add("Second")
            store.notes = "Keep this note"
            let first = store.items[0].id, second = store.items[1].id
            store.toggle(first)
            XCTAssertEqual(store.completedCount, 1)
            XCTAssertEqual(TodoStore(defaults: defaults).completedCount, 1)
            store.toggle(first)
            XCTAssertEqual(store.pending.count, 2)
            store.update(second, text: "Updated\n第二行")
            store.toggle(first)
            store.clearCompleted()
            let restored = TodoStore(defaults: defaults)
            XCTAssertEqual(restored.items.map(\.id), [second])
            XCTAssertEqual(restored.items.first?.text, "Updated\n第二行")
            XCTAssertEqual(restored.notes, "Keep this note")
            restored.remove(second)
            XCTAssertTrue(TodoStore(defaults: defaults).items.isEmpty)
            XCTAssertEqual(TodoStore(defaults: defaults).notes, "Keep this note")
        }
    }

    func testClearingClippingsDoesNotClearNotebook() async throws {
        let suite = "TodoTests.\(UUID().uuidString)"
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: folder)
        }
        let (store, line) = try await MainActor.run {
            let defaults = UserDefaults(suiteName: suite)!
            let store = TodoStore(defaults: defaults)
            store.add("Pinned forever")
            store.notes = "Independent notes"
            let line = Line(defaults: defaults)
            line.hang(try TextClipping.save("A temporary clipping", in: folder), quietly: true)
            line.clear()
            return (store, line)
        }
        try await Task.sleep(nanoseconds: 150_000_000)
        await MainActor.run {
            let defaults = UserDefaults(suiteName: suite)!
            XCTAssertEqual(line.liveCount, 0)
            XCTAssertEqual(TodoStore(defaults: defaults).items, store.items)
            XCTAssertEqual(TodoStore(defaults: defaults).notes, store.notes)
            XCTAssertEqual(store.pending.count, 1)
        }
    }

    func testNotebookMigrationRunsOnceWithoutOverwritingCurrentNotes() async {
        await MainActor.run {
            let oldName = "LegacyNotebookTests.\(UUID().uuidString)"
            let newName = "NewNotebookTests.\(UUID().uuidString)"
            let old = UserDefaults(suiteName: oldName)!
            let new = UserDefaults(suiteName: newName)!
            defer {
                old.removePersistentDomain(forName: oldName)
                new.removePersistentDomain(forName: newName)
            }
            let original = TodoStore(defaults: old)
            original.add("Keep my tasks")
            original.notes = "My notes"
            old.set(true, forKey: "inboxEnabled")
            NotebookMigration.run(defaults: new, legacy: old)
            XCTAssertEqual(TodoStore(defaults: new).items, original.items)
            XCTAssertEqual(TodoStore(defaults: new).notes, "My notes")
            XCTAssertNil(new.object(forKey: "inboxEnabled"))
            new.removeObject(forKey: "todoNotebook.v1")
            NotebookMigration.run(defaults: new, legacy: old)
            XCTAssertTrue(TodoStore(defaults: new).items.isEmpty)
            new.removeObject(forKey: "importedLegacyNotebook.v1")
            TodoStore(defaults: new).notes = "Already using Lineshot"
            NotebookMigration.run(defaults: new, legacy: old)
            XCTAssertEqual(TodoStore(defaults: new).notes, "Already using Lineshot")
            XCTAssertEqual(TodoStore(defaults: old).notes, "My notes")
        }
    }

    func testEditorCanAcceptKeyboardFocus() async {
        await MainActor.run {
            let suite = "TodoTests.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let editor = TodoEditor(store: TodoStore(defaults: defaults))
            XCTAssertTrue(editor.window?.canBecomeKey == true)
            XCTAssertTrue(editor.window?.canBecomeMain == true)
            XCTAssertNotNil(editor.window?.contentView)
            editor.close()
        }
    }

    func testCenteredGroupAndPinnedFirstSlotAtEverySize() async {
        await MainActor.run {
            let previous = UserDefaults.standard.object(forKey: "lineSize")
            defer {
                if let previous { UserDefaults.standard.set(previous, forKey: "lineSize") }
                else { UserDefaults.standard.removeObject(forKey: "lineSize") }
            }
            for size in Layout.Size.allCases {
                Layout.size = size
                for width: CGFloat in [640, 800, 1440, 2560] {
                    let fits = Layout.clippingCapacity(width: width)
                    XCTAssertEqual(Layout.todoX(count: 0, width: width, visible: fits), width / 2)
                    var previousLeft = width / 2
                    for count in 1...fits {
                        let left = Layout.todoX(count: count, width: width, visible: fits)
                        let right = Layout.x(index: count - 1, count: count, width: width, visible: fits, scroll: 0)
                        XCTAssertEqual((left + right) / 2, width / 2, accuracy: 0.001)
                        XCTAssertEqual(previousLeft - left, Layout.spacing / 2, accuracy: 0.001)
                        previousLeft = left
                    }
                    for count in [1, fits, 25, 100] {
                        let todo = Layout.todoX(count: count, width: width, visible: fits)
                        let start = Layout.clippingsStart(count: count, width: width, visible: fits)
                        XCTAssertGreaterThanOrEqual(todo - Layout.cardWidth / 2, 24)
                        XCTAssertGreaterThan(start, todo + Layout.cardWidth / 2)
                        let overflow = max(0, count - fits)
                        let firstVisible = Layout.x(index: overflow, count: count, width: width, visible: fits, scroll: 0)
                        XCTAssertGreaterThan(firstVisible - Layout.cardWidth / 2, start)
                        let oldest = Layout.x(index: 0, count: count, width: width, visible: fits,
                                              scroll: CGFloat(overflow) * Layout.spacing)
                        XCTAssertEqual(oldest, firstVisible, accuracy: 0.001)
                        let newest = Layout.x(index: count - 1, count: count, width: width, visible: fits, scroll: 0)
                        XCTAssertEqual((todo + newest) / 2, width / 2, accuracy: 0.001)
                        XCTAssertLessThanOrEqual(newest + Layout.cardWidth / 2, width - 24)
                        for scroll in [-100.0, 0, Double(overflow) * Double(Layout.spacing), 1e6] {
                            let first = Layout.x(index: 0, count: count, width: width, visible: fits, scroll: scroll)
                            XCTAssertLessThanOrEqual(first, firstVisible)
                        }
                    }
                }
            }
        }
    }
}
