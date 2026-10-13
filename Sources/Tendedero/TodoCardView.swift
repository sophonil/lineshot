import SwiftUI

/// A permanent first peg. Its own identity is only used for hit testing;
/// it is never part of Line.items, so it cannot be scrolled or discarded.
struct TodoCardView: View {
    static let hitID = UUID(uuidString: "DF860842-E663-41DC-96BA-4ED33E17A7CE")!
    @ObservedObject var store: TodoStore
    let gust: Int
    let onOpen: () -> Void
    @State private var hovering = false
    @State private var swing: Double = 0

    var body: some View {
        VStack(spacing: -12) {
            Clothespin().zIndex(1)
            paper
                .frame(width: Layout.cardWidth - 14, height: Layout.photoMaxHeight)
                .background(Color(red: 0.985, green: 0.98, blue: 0.955))
                .clipShape(RoundedRectangle(cornerRadius: Frame.radius - Frame.inset, style: .continuous))
                .padding(Frame.inset)
                .glassFrame(cornerRadius: Frame.radius)
                .shadow(color: .black.opacity(hovering ? 0.26 : 0.18), radius: hovering ? 14 : 10, y: hovering ? 8 : 5)
                .scaleEffect(hovering ? 1.035 : 1, anchor: .top)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hovering)
                .overlay(TodoCardClick(onOpen: onOpen))
                .onHover { hovering = $0 }
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: HitRectsKey.self,
                                           value: [Self.hitID: geometry.frame(in: .global)])
                })
        }
        .rotationEffect(.degrees(-1 + swing), anchor: .top)
        .onChange(of: gust) { _, _ in
            withAnimation(.easeOut(duration: 0.3)) { swing = 2 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.interpolatingSpring(stiffness: 38, damping: 2.4)) { swing = 0 }
            }
        }
    }

    private var paper: some View {
        let scale = Layout.size.scale
        return VStack(alignment: .leading, spacing: 6 * scale) {
            HStack(spacing: 4) {
                Image(systemName: "checklist")
                Text(L("To-do list")).fontWeight(.semibold)
                Spacer(minLength: 0)
                Text("\(store.pending.count)").monospacedDigit().foregroundStyle(.secondary)
            }
            .font(.system(size: 10 * scale))
            Rectangle().fill(Color.black.opacity(0.10)).frame(height: 0.5)
            if store.pending.isEmpty {
                Text(store.items.isEmpty ? L("Click to add a to-do") : L("All done"))
                    .font(.system(size: 10 * scale))
                    .foregroundStyle(Color.black.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
                if !store.notes.isEmpty {
                    Text(store.notes).font(.system(size: 9 * scale)).lineLimit(2)
                }
            } else {
                ForEach(store.pending.prefix(3)) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 5 * scale) {
                        Image(systemName: "circle").font(.system(size: 8 * scale)).foregroundStyle(Color.black.opacity(0.35))
                        Text(item.text).font(.system(size: 10 * scale)).lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10 * scale)
        .foregroundStyle(Color(white: 0.2))
    }
}

private struct TodoCardClick: NSViewRepresentable {
    let onOpen: () -> Void
    func makeNSView(context: Context) -> TodoClickView {
        let view = TodoClickView()
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.button)
        view.setAccessibilityLabel(L("Open to-do list"))
        return view
    }
    func updateNSView(_ view: TodoClickView, context: Context) {
        view.onOpen = onOpen
        view.toolTip = L("Open to-do list")
    }
}

private final class TodoClickView: NSView {
    var onOpen: () -> Void = {}
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {}
    override func mouseUp(with event: NSEvent) {
        if bounds.contains(convert(event.locationInWindow, from: nil)) { onOpen() }
    }
    override func accessibilityPerformPress() -> Bool { onOpen(); return true }
}
