import SwiftUI

/// Plot Twist's own icons, drawn on a 24-point grid so they share one weight
/// and one corner radius. Each is a filled shape, so it can take the opal
/// gradient when selected.
enum Glyph: String, CaseIterable, Hashable {
    /// Books standing on a shelf, one leaning: the whole library.
    case library
    /// A ribbon bookmark: the books you're reading or have read.
    case read
    /// One path forking into two: the stories you've twisted.
    case twisted

    var shape: AnyShape {
        switch self {
        case .library: AnyShape(LibraryGlyphShape())
        case .read: AnyShape(ReadGlyphShape())
        case .twisted: AnyShape(TwistGlyphShape())
        }
    }
}

/// Maps the 24-point design grid onto any rect.
private struct Grid24 {
    let rect: CGRect
    var unit: CGFloat { min(rect.width, rect.height) / 24 }
    var origin: CGPoint {
        CGPoint(x: rect.midX - unit * 12, y: rect.midY - unit * 12)
    }

    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + x * unit, y: origin.y + y * unit)
    }

    func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: origin.x + x * unit, y: origin.y + y * unit, width: w * unit, height: h * unit)
    }
}

/// Three spines with their bands cut out, the third leaning on the second.
struct LibraryGlyphShape: Shape {
    func path(in rect: CGRect) -> Path {
        let g = Grid24(rect: rect)
        var path = Path()

        func spine(_ x: CGFloat, _ top: CGFloat, _ width: CGFloat) -> Path {
            var spine = Path(roundedRect: g.r(x, top, width, 20.5 - top), cornerRadius: 1.3 * g.unit)
            // Two bands stamped across each spine.
            let bandHeight: CGFloat = 1.1
            for y in [top + 2.6, 20.5 - 3.7] {
                spine.addRect(g.r(x + 0.9, y, width - 1.8, bandHeight))
            }
            return spine
        }

        path.addPath(spine(2.5, 3.5, 4.6))
        path.addPath(spine(8.4, 6, 4.6))
        // The leaning book, tipped to the right on its bottom-right corner.
        let pivot = g.p(18.8, 20.5)
        let lean = CGAffineTransform(translationX: pivot.x, y: pivot.y)
            .rotated(by: 0.26)
            .translatedBy(x: -pivot.x, y: -pivot.y)
        path.addPath(spine(14.6, 5, 4.2), transform: lean)
        return path
    }
}

/// A satin bookmark with a swallow-tail end.
struct ReadGlyphShape: Shape {
    func path(in rect: CGRect) -> Path {
        let g = Grid24(rect: rect)
        var path = Path()
        let radius: CGFloat = 2.2
        path.move(to: g.p(6, 3 + radius))
        path.addArc(center: g.p(6 + radius, 3 + radius), radius: radius * g.unit, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.addLine(to: g.p(18 - radius, 3))
        path.addArc(center: g.p(18 - radius, 3 + radius), radius: radius * g.unit, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: g.p(18, 21))
        path.addLine(to: g.p(12, 15.6))
        path.addLine(to: g.p(6, 21))
        path.closeSubpath()
        return path
    }
}

/// A trunk that forks into two branches, each ending in a bead.
struct TwistGlyphShape: Shape {
    func path(in rect: CGRect) -> Path {
        let g = Grid24(rect: rect)
        var line = Path()
        line.move(to: g.p(12, 20))
        line.addLine(to: g.p(12, 14))
        line.addCurve(to: g.p(6, 6.4), control1: g.p(12, 10.5), control2: g.p(6, 10.2))
        line.move(to: g.p(12, 14))
        line.addCurve(to: g.p(18, 6.4), control1: g.p(12, 10.5), control2: g.p(18, 10.2))
        var path = line.strokedPath(StrokeStyle(lineWidth: 2.1 * g.unit, lineCap: .round, lineJoin: .round))
        let bead: CGFloat = 2.6
        for (x, y) in [(6.0, 4.6), (18.0, 4.6)] {
            path.addEllipse(in: g.r(x - bead, y - bead, bead * 2, bead * 2))
        }
        path.addEllipse(in: g.r(12 - 1.9, 20.4 - 1.9, 3.8, 3.8))
        return path
    }
}

/// A glyph, filled. Selected glyphs take the opal gradient and glow.
struct GlyphView: View {
    let glyph: Glyph
    var isSelected = false
    var size: CGFloat = DS.Size.navGlyph

    var body: some View {
        glyph.shape
            .fill(
                isSelected ? AnyShapeStyle(DS.Gradients.opal) : AnyShapeStyle(DS.Colors.inkSecondary),
                style: FillStyle(eoFill: true)
            )
            .frame(width: size, height: size)
            .dsGlow(DS.Colors.accentDeep, radius: 10, strength: isSelected ? 0.55 : 0)
            .accessibilityHidden(true)
    }
}

/// Icons in a glass capsule, one of them selected, like Opal's tab bar.
/// The lit pill slides between them.
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
        HStack(spacing: 2) {
            ForEach(items) { item in
                let isSelected = item.id == selection
                Button {
                    withAnimation(DS.Motion.select) { selection = item.id }
                } label: {
                    GlyphView(glyph: item.glyph, isSelected: isSelected)
                        .frame(width: DS.Size.navItem + DS.Space.xs, height: DS.Size.navItem)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.white.opacity(0.11))
                                    .overlay { Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: DS.Size.hairline) }
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
        .background(DS.Colors.surface.opacity(0.85), in: Capsule())
        .overlay { Capsule().strokeBorder(DS.Gradients.glassEdge, lineWidth: DS.Size.hairline) }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview {
    @Previewable @State var selection = Glyph.library
    VStack(spacing: DS.Space.xl) {
        HStack(spacing: DS.Space.l) {
            ForEach(Glyph.allCases, id: \.self) { glyph in
                VStack(spacing: DS.Space.s) {
                    GlyphView(glyph: glyph, isSelected: true, size: 48)
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
    .dsScreen()
}
