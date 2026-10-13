import SwiftUI

enum Layout {
    /// How big the photos hang, from Size in the menu bar. The clip, the rope
    /// and the glass frame keep their size; the photos and the room they take
    /// grow or shrink. Medium is the original size.
    enum Size: String, CaseIterable {
        case small, medium, large

        var scale: CGFloat {
            switch self {
            case .small: 0.8
            case .medium: 1
            case .large: 1.35
            }
        }
    }

    static var size: Size {
        get { Size(rawValue: UserDefaults.standard.string(forKey: "lineSize") ?? "") ?? .medium }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "lineSize") }
    }

    static var photoMaxHeight: CGFloat { (104 * size.scale).rounded() }
    static var cardWidth: CGFloat { (150 * size.scale).rounded() }
    static var spacing: CGFloat { cardWidth + 24 }
    static var panelHeight: CGFloat { photoMaxHeight + 106 }
    static let ropeTop: CGFloat = 10
    static let pinAbove: CGFloat = 9.5

    /// The rope hangs as a parabola from edge to edge of the screen.
    static func sag(width: CGFloat) -> CGFloat { min(30, width * 0.018) }

    static func ropeY(x: CGFloat, width: CGFloat) -> CGFloat {
        guard width > 0 else { return ropeTop }
        let f = x / width
        return ropeTop + 4 * sag(width: width) * f * (1 - f)
    }

    /// Center the notebook and the visible clippings as one group. The
    /// notebook keeps the first slot when older clippings are scrolled in.
    static func todoX(count: Int, width: CGFloat, visible: Int) -> CGFloat {
        let shown = min(max(0, count), max(1, visible))
        return width / 2 - CGFloat(shown) * spacing / 2
    }

    static func clippingsStart(count: Int, width: CGFloat, visible: Int) -> CGFloat {
        todoX(count: count, width: width, visible: visible) + spacing / 2
    }

    static func clippingCapacity(width: CGFloat) -> Int {
        // Leave a 24-point margin at either edge, including the notebook.
        max(1, min(12, Int(max(0, width - 48 - cardWidth) / spacing)))
    }

    static func x(index: Int, count: Int, width: CGFloat, visible: Int, scroll: CGFloat) -> CGFloat {
        let overflow = max(0, count - max(1, visible))
        let offset = min(max(0, scroll), CGFloat(overflow) * spacing)
        return todoX(count: count, width: width, visible: visible)
            + CGFloat(index - overflow + 1) * spacing + offset
    }

}

struct LineView: View {
    @ObservedObject var line: Line
    @ObservedObject var todos: TodoStore
    var onOpenTodos: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .topLeading) {
                Rope(width: width)

                ZStack(alignment: .topLeading) {
                    ForEach(Array(line.items.enumerated()), id: \.element.id) { index, item in
                        let x = Layout.x(index: index, count: line.items.count, width: width,
                                         visible: line.visibleCount, scroll: line.scroll)
                        let ropeY = Layout.ropeY(x: x, width: width)
                        PeggedView(item: item, line: line)
                            .frame(width: Layout.cardWidth, height: Layout.panelHeight - ropeY, alignment: .top)
                            // Photos scrolled towards an edge fade out before they reach it.
                            .opacity(min(1, max(0, min(x, width - x) / 90)))
                            .position(x: x, y: ropeY - Layout.pinAbove + (Layout.panelHeight - ropeY) / 2)
                    }
                }
                .frame(width: width, height: geo.size.height, alignment: .topLeading)
                .mask(alignment: .topLeading) {
                    Rectangle()
                        .frame(width: max(0, width - Layout.clippingsStart(count: line.items.count, width: width, visible: line.visibleCount)), height: geo.size.height)
                        .offset(x: Layout.clippingsStart(count: line.items.count, width: width, visible: line.visibleCount))
                }

                let todoX = Layout.todoX(count: line.items.count, width: width, visible: line.visibleCount)
                let todoY = Layout.ropeY(x: todoX, width: width)
                TodoCardView(store: todos, gust: line.gust, onOpen: onOpenTodos)
                    .frame(width: Layout.cardWidth, height: Layout.panelHeight - todoY, alignment: .top)
                    .position(x: todoX, y: todoY - Layout.pinAbove + (Layout.panelHeight - todoY) / 2)
            }
            .animation(.spring(response: 0.55, dampingFraction: 0.78), value: line.items.map(\.id))
            .animation(.easeInOut(duration: 0.3), value: line.items.isEmpty)
            // Tucked away, the whole line waits above the top edge and slides
            // out from under the menu bar, the way an auto-hiding Dock does.
            .offset(y: line.revealed ? 0 : -(Layout.panelHeight + 12))
            .animation(line.revealed ? .spring(response: 0.42, dampingFraction: 0.82)
                                     : .easeIn(duration: 0.22), value: line.revealed)
        }
        .onPreferenceChange(HitRectsKey.self) { rects in
            line.hitRects = rects
        }
    }
}

/// A thin, neutral line: a mid gray core with a faint highlight and a soft
/// shadow, so it reads on light and dark backgrounds alike. It fades out at
/// both ends so it seems to come from beyond the screen.
struct Rope: View {
    let width: CGFloat

    private var path: Path {
        Path { p in
            let top = Layout.ropeTop
            p.move(to: CGPoint(x: -20, y: top))
            p.addQuadCurve(
                to: CGPoint(x: width + 20, y: top),
                control: CGPoint(x: width / 2, y: top + 2 * Layout.sag(width: width)))
        }
    }

    var body: some View {
        ZStack {
            path.stroke(Color.black.opacity(0.22), lineWidth: 1.4).offset(y: 1.2).blur(radius: 1.2)
            path.stroke(Color(white: 0.55), lineWidth: 1.2)
            path.stroke(Color.white.opacity(0.45), lineWidth: 0.4).offset(y: -0.35)
        }
        .mask(
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.08),
                .init(color: .black, location: 0.92),
                .init(color: .clear, location: 1),
            ], startPoint: .leading, endPoint: .trailing)
        )
        .allowsHitTesting(false)
    }
}

struct HitRectsKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}
