import AppKit
import SwiftUI

/// The line itself never takes keyboard focus. Editing happens in a small
/// key-capable window so typing, input methods and ordinary shortcuts work.
@MainActor
final class TodoEditor: NSWindowController {
    init(store: TodoStore) {
        let panel = TodoEditorPanel(contentRect: NSRect(x: 0, y: 0, width: 390, height: 520),
                                    styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        panel.title = L("To-do list")
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.minSize = NSSize(width: 340, height: 380)
        panel.contentView = NSHostingView(rootView: TodoEditorView(store: store))
        super.init(window: panel)
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(on screen: NSScreen?, clippingCount: Int, visibleCount: Int) {
        guard let window else { return }
        if !window.isVisible, let frame = (screen ?? NSScreen.main)?.visibleFrame {
            let x = min(max(frame.minX + Layout.todoX(count: clippingCount, width: frame.width, visible: visibleCount) - window.frame.width / 2, frame.minX + 12),
                        frame.maxX - window.frame.width - 12)
            let y = max(frame.minY + 12, frame.maxY - Layout.panelHeight - window.frame.height + 30)
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

private final class TodoEditorPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override func cancelOperation(_ sender: Any?) { close() }

    /// Accessory apps have no Edit menu to dispatch these key equivalents.
    /// SwiftUI fields use an NSTextView field editor; notes use NSTextView too.
    /// Keep dispatch local to the focused text editor so other windows and
    /// shortcut recording are unaffected.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown, let text = firstResponder as? NSTextView else {
            return super.performKeyEquivalent(with: event)
        }
        let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let key = event.charactersIgnoringModifiers?.lowercased()
        if modifiers == .command {
            switch key {
            case "v" where text.isEditable: text.paste(nil)
            case "x" where text.isEditable: text.cut(nil)
            case "c" where text.isSelectable: text.copy(nil)
            case "a" where text.isSelectable: text.selectAll(nil)
            case "z" where text.isEditable:
                if let undo = text.undoManager, undo.canUndo { undo.undo() }
            default: return super.performKeyEquivalent(with: event)
            }
            return true
        }
        if modifiers == [.command, .shift], key == "z", text.isEditable {
            if let undo = text.undoManager, undo.canRedo { undo.redo() }
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

struct TodoEditorView: View {
    @ObservedObject var store: TodoStore
    @State private var draft = ""
    @FocusState private var adding: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(L("To-do list")).font(.system(size: 22, weight: .semibold, design: .rounded))
                Spacer()
                Text(String(format: L("%d remaining"), store.pending.count))
                    .font(.callout).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                TextField(L("Add a to-do…"), text: $draft)
                    .textFieldStyle(.plain).focused($adding).onSubmit(add)
                    .accessibilityLabel(L("Add a to-do…"))
                Button(action: add) { Image(systemName: "plus.circle.fill").font(.title2) }
                    .buttonStyle(.plain).accessibilityLabel(L("Add to-do"))
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(11)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 12))

            ScrollView {
                LazyVStack(spacing: 0) {
                    if store.items.isEmpty {
                        Text(L("One small thing at a time."))
                            .foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 110)
                    }
                    ForEach(store.items) { item in
                        HStack(alignment: .top, spacing: 9) {
                            Button { store.toggle(item.id) } label: {
                                Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 17))
                                    .foregroundStyle(item.completed ? Color.secondary : Color.primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item.completed ? L("Mark incomplete") : L("Mark complete"))
                            TextField(L("To-do"), text: Binding(
                                get: { store.items.first(where: { $0.id == item.id })?.text ?? "" },
                                set: { store.update(item.id, text: $0) }), axis: .vertical)
                                .textFieldStyle(.plain)
                                .strikethrough(item.completed)
                                .foregroundStyle(item.completed ? .secondary : .primary)
                            Button { store.remove(item.id) } label: {
                                Image(systemName: "xmark").font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain).accessibilityLabel(L("Delete to-do"))
                        }
                        .padding(.vertical, 10).padding(.horizontal, 4)
                        Divider()
                    }
                }
            }
            .frame(minHeight: 90, maxHeight: .infinity)

            HStack {
                Text(L("Notes")).font(.system(.callout, design: .rounded, weight: .semibold))
                Spacer()
                Button(L("Clear completed")) { store.clearCompleted() }
                    .font(.caption).buttonStyle(.plain).foregroundStyle(.secondary)
                    .disabled(store.completedCount == 0)
            }
            TextEditor(text: $store.notes)
                .font(.body).scrollContentBackground(.hidden)
                .padding(8).frame(height: 90)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel(L("Notes"))
        }
        .padding(20)
        .background(.regularMaterial)
        .onAppear { adding = true }
    }

    private func add() {
        if store.add(draft) { draft = "" }
        adding = true
    }
}
