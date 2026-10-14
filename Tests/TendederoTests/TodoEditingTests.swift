import AppKit
import XCTest
@testable import Tendedero

final class TodoEditingTests: XCTestCase {
    func testPasteSelectCopyCutUndoAndRedoInNotebookEditors() async {
        await MainActor.run {
            for fieldEditor in [true, false] {
                let suite = "TodoEditingTests.\(UUID().uuidString)"
                let defaults = UserDefaults(suiteName: suite)!
                defer { defaults.removePersistentDomain(forName: suite) }
                let controller = TodoEditor(store: TodoStore(defaults: defaults))
                let window = controller.window!
                let text = IsolatedClipboardTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
                text.isFieldEditor = fieldEditor
                text.isRichText = false
                text.allowsUndo = true
                text.undoManager?.groupsByEvent = false
                window.contentView = text
                XCTAssertTrue(window.makeFirstResponder(text))
                defer { controller.close() }
                text.clipboardText = "粘贴中文与 emoji 🧺"
                text.undoManager?.beginUndoGrouping()
                XCTAssertTrue(window.performKeyEquivalent(with: key("v", in: window)))
                text.undoManager?.endUndoGrouping()
                XCTAssertEqual(text.string, "粘贴中文与 emoji 🧺")
                XCTAssertTrue(window.performKeyEquivalent(with: key("a", in: window)))
                XCTAssertEqual(text.selectedRange(), NSRange(location: 0, length: (text.string as NSString).length))
                XCTAssertTrue(window.performKeyEquivalent(with: key("c", in: window)))
                XCTAssertEqual(text.clipboardText, text.string)
                // Close the paste undo group before testing cut as a separate edit.
                text.breakUndoCoalescing()
                text.undoManager?.beginUndoGrouping()
                XCTAssertTrue(window.performKeyEquivalent(with: key("x", in: window)))
                XCTAssertEqual(text.string, "")
                text.undoManager?.endUndoGrouping()
                XCTAssertTrue(window.performKeyEquivalent(with: key("z", in: window)))
                XCTAssertEqual(text.string, "粘贴中文与 emoji 🧺")
                XCTAssertTrue(window.performKeyEquivalent(with: key("z", modifiers: [.command, .shift], in: window)))
                XCTAssertEqual(text.string, "")
            }
        }
    }

    func testUnmodifiedTypingAndOtherShortcutsAreNotIntercepted() async {
        await MainActor.run {
            let suite = "TodoEditingTests.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let controller = TodoEditor(store: TodoStore(defaults: defaults))
            let window = controller.window!
            let text = IsolatedClipboardTextView()
            window.contentView = text
            window.makeFirstResponder(text)
            defer { controller.close() }
            text.clipboardText = "Do not paste"
            for flags: NSEvent.ModifierFlags in [[], [.command, .option], [.command, .control], [.command, .shift]] {
                _ = window.performKeyEquivalent(with: key("v", modifiers: flags, in: window))
                XCTAssertEqual(text.string, "")
            }
            window.makeFirstResponder(window)
            XCTAssertFalse(window.performKeyEquivalent(with: key("v", in: window)))
        }
    }
}

@MainActor
private func key(_ character: String, modifiers: NSEvent.ModifierFlags = [.command], in window: NSWindow) -> NSEvent {
    NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers,
                    timestamp: 0, windowNumber: window.windowNumber, context: nil,
                    characters: character, charactersIgnoringModifiers: character,
                    isARepeat: false, keyCode: 0)!
}

/// Exercise AppKit text editing without replacing the user's general clipboard.
private final class IsolatedClipboardTextView: NSTextView {
    var clipboardText: String?
    private let edits = UndoManager()
    override var undoManager: UndoManager? { edits }
    override func paste(_ sender: Any?) {
        if let value = clipboardText { insertText(value, replacementRange: selectedRange()) }
    }
    override func copy(_ sender: Any?) { clipboardText = (string as NSString).substring(with: selectedRange()) }
    override func cut(_ sender: Any?) { copy(sender); delete(sender) }
}
