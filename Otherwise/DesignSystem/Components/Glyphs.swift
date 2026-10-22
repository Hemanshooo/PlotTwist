import SwiftUI

/// Plot Twist's own icons, drawn in the garden's hand on a 24-point grid.
/// Each is part book, part plant: the book parts take the ink, stems and
/// leaves the stem colour, roses and ribbons the bloom. Unselected, an icon
/// is drawn in one quiet colour; selected, it takes its full colours and its
/// flower opens.
enum Glyph: String, CaseIterable, Hashable {
    /// Books lying in a stack, a sprout growing from the top one: the whole library.
    case library
    /// A book with a ribbon hanging from it: the books you're reading or have read.
    case read
    /// One stem forking in two, a leaf on one branch and a rose on the other: the stories you've twisted.
    case twisted
}

/// The colours one icon is drawn in.
private struct GlyphInk {
    var book: Color
    var garden: GardenInk
}

/// A glyph, drawn. `open` (0…1) is how far its flower has opened.
struct GlyphView: View, Animatable {
    let glyph: Glyph
    var isSelected = false
    var size: CGFloat = DS.Size.navIcon
    var open: Double = 1

    var animatableData: Double {
        get { open }
        set { open = newValue }
    }

    var body: some View {
        let ground = isSelected ? DS.Colors.raised : DS.Colors.canvas
        let ink = isSelected
            ? GlyphInk(book: DS.Colors.ink, garden: GardenInk(stem: DS.Colors.stem, bloom: DS.Colors.bloom, petal: DS.Colors.petal, ground: ground))
            : GlyphInk(book: DS.Colors.inkTertiary, garden: .mono(DS.Colors.inkTertiary, ground: ground))
        Canvas { context, canvas in
            let rect = CGRect(origin: .zero, size: canvas)
            switch glyph {
            case .library: Self.drawLibrary(in: context, rect: rect, ink: ink, open: open)
            case .read: Self.drawRead(in: context, rect: rect, ink: ink, open: open)
            case .twisted: TwistDrawing.draw(in: context, rect: rect, ink: ink.garden, open: 0.55 + 0.45 * open, stemWidth: 1.6)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    // MARK: Drawings

    private static func drawLibrary(in context: GraphicsContext, rect: CGRect, ink: GlyphInk, open: Double) {
        let u = rect.width / 24
        func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: rect.minX + x * u, y: rect.minY + y * u, width: w * u, height: h * u)
        }
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * u, y: rect.minY + y * u) }
        // Three books lying in a stack, each with a band near either end.
        var books = Path()
        for slab in [r(2, 17, 19.5, 4.4), r(4, 11.8, 16.5, 4.4), r(2.6, 6.6, 15, 4.4)] {
            books.addRoundedRect(in: slab, cornerSize: CGSize(width: 1.1 * u, height: 1.1 * u))
            books.addRect(CGRect(x: slab.minX + 1.7 * u, y: slab.minY + 1 * u, width: 0.9 * u, height: slab.height - 2 * u))
            books.addRect(CGRect(x: slab.maxX - 2.6 * u, y: slab.minY + 1 * u, width: 0.9 * u, height: slab.height - 2 * u))
        }
        context.fill(books, with: .color(ink.book), style: FillStyle(eoFill: true))
        // A sprout from the top book, its bud opening when selected.
        var sprout = Path()
        sprout.move(to: p(15.4, 6.6))
        sprout.addCurve(to: p(19.6, 2.4), control1: p(15.6, 4.2), control2: p(18, 4.2))
        context.stroke(sprout, with: .color(ink.garden.stem), style: StrokeStyle(lineWidth: 1.4 * u, lineCap: .round))
        context.drawLeaf(at: p(16.2, 4.6), angle: .degrees(-158), length: 4.6 * u, ink: ink.garden, vein: false)
        context.drawRose(at: p(20.2, 2.6), size: (3.6 + 1.6 * open) * u, seed: 2, ink: ink.garden)
    }

    private static func drawRead(in context: GraphicsContext, rect: CGRect, ink: GlyphInk, open: Double) {
        let u = rect.width / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * u, y: rect.minY + y * u) }
        // A book standing up, its spine on the left.
        var book = Path()
        let cover = CGRect(x: rect.minX + 5 * u, y: rect.minY + 2 * u, width: 14 * u, height: 18 * u)
        book.addRoundedRect(in: cover, cornerSize: CGSize(width: 1.6 * u, height: 1.6 * u))
        book.addRect(CGRect(x: cover.minX + 2.2 * u, y: cover.minY, width: 0.9 * u, height: cover.height))
        context.fill(book, with: .color(ink.book), style: FillStyle(eoFill: true))
        // A ribbon falling from the top of the book and out past its foot.
        let drop = 3.2 + 2.4 * open
        var ribbon = Path()
        let left = 12.4 * u, right = 15.6 * u
        ribbon.move(to: CGPoint(x: rect.minX + left, y: rect.minY + 2 * u))
        ribbon.addLine(to: CGPoint(x: rect.minX + right, y: rect.minY + 2 * u))
        ribbon.addLine(to: CGPoint(x: rect.minX + right, y: rect.minY + (19 + drop) * u))
        ribbon.addLine(to: CGPoint(x: rect.minX + (left + right) / 2, y: rect.minY + (17.4 + drop) * u))
        ribbon.addLine(to: CGPoint(x: rect.minX + left, y: rect.minY + (19 + drop) * u))
        ribbon.closeSubpath()
        context.fill(ribbon, with: .color(ink.garden.bloom))
        // A leaf pressed between the pages, peeking out of the top.
        context.drawLeaf(at: p(9.4, 2.4), angle: .degrees(-62), length: 4.4 * u, ink: ink.garden, vein: false)
    }
}

/// Icons in an outlined capsule, one of them selected, like Type Garden's
/// Type | Poster toggle. The pill slides between them and the selected
/// icon's flower opens.
struct GlyphSwitcher<ID: Hashable>: View {
    struct Item: Identifiable {
        let id: ID
        let glyph: Glyph
        let label: LocalizedStringKey
    }

    let items: [Item]
    @Binding var selection: ID

    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let isSelected = item.id == selection
                Button {
                    withAnimation(DS.Motion.select) { selection = item.id }
                } label: {
                    GlyphView(glyph: item.glyph, isSelected: isSelected, open: isSelected ? 1 : 0)
                        .animation(DS.Motion.bloom(), value: isSelected)
                        .frame(width: DS.Size.navItem + DS.Space.xxs, height: DS.Size.navItem - 4)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(DS.Colors.raised)
                                    .overlay { Capsule().strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline) }
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(item.label)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(3)
        .background(DS.Colors.canvas, in: Capsule())
        .overlay { Capsule().strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline) }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview {
    @Previewable @State var selection = Glyph.library
    VStack(spacing: DS.Space.xl) {
        HStack(spacing: DS.Space.l) {
            ForEach(Glyph.allCases, id: \.self) { glyph in
                VStack(spacing: DS.Space.s) {
                    GlyphView(glyph: glyph, isSelected: true, size: 72)
                    GlyphView(glyph: glyph, size: 24)
                }
            }
        }
        GlyphSwitcher(
            items: Glyph.allCases.map { GlyphSwitcher<Glyph>.Item(id: $0, glyph: $0, label: LocalizedStringKey($0.rawValue)) },
            selection: $selection
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Colors.canvas)
}
