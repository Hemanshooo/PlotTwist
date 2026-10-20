import SwiftUI

// MARK: - Arc gauge

/// A wide arc that fills with light, with a big light numeral inside.
/// Opal scores your day with one; Plot Twist shows how far you've read.
struct ArcGauge<Center: View>: View {
    /// 0…1.
    let value: Double
    var colors: [Color] = DS.Gradients.twilightColors
    var diameter: CGFloat = DS.Size.gauge
    @ViewBuilder let center: Center

    /// The arc runs 220° around, open at the bottom.
    private let sweep: Double = 220
    private let start: Double = 160

    var body: some View {
        let fraction = sweep / 360
        let gradient = AngularGradient(
            colors: colors,
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(sweep)
        )
        let line = DS.Size.gaugeLine
        ZStack {
            // The track.
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(start))
            // Light spilling from the filled part.
            Circle()
                .trim(from: 0, to: fraction * clamped)
                .stroke(gradient, style: StrokeStyle(lineWidth: line * 2.4, lineCap: .round))
                .rotationEffect(.degrees(start))
                .blur(radius: 12)
                .opacity(0.55)
            // The filled part.
            Circle()
                .trim(from: 0, to: fraction * clamped)
                .stroke(gradient, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(start))
            // A bead of light at the end.
            if clamped > 0.001 {
                Circle()
                    .fill(Color.white)
                    .frame(width: line * 0.9, height: line * 0.9)
                    .offset(endOffset)
                    .dsGlow(.white, radius: 6, strength: 0.8)
            }
            center
                .offset(y: diameter * 0.03)
        }
        .frame(width: diameter, height: diameter)
        // The open bottom of the circle isn't drawn, so don't reserve it.
        .frame(height: diameter * 0.78, alignment: .top)
    }

    private var clamped: Double { min(max(value, 0), 1) }

    private var endOffset: CGSize {
        let angle = (start + sweep * clamped) * .pi / 180
        let radius = diameter / 2
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }
}

// MARK: - Pills

/// A capsule choice that lights up when selected: Opal's score pills, used
/// here for "Finished · Partway · Not yet".
struct GlowPill: View {
    let title: LocalizedStringKey
    let systemImage: String
    let isSelected: Bool
    var colors: [Color] = DS.Gradients.twilightColors
    let action: () -> Void

    var body: some View {
        let gradient = LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(DS.Typography.metaEmphasis)
                .labelStyle(.titleAndIcon)
                .foregroundStyle(isSelected ? DS.Colors.ink : DS.Colors.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: DS.Size.pill)
                .padding(.horizontal, DS.Space.xs)
                .background {
                    ZStack {
                        Capsule().fill(DS.Gradients.glass)
                        Capsule().fill(gradient).opacity(isSelected ? 0.14 : 0)
                    }
                }
                .overlay {
                    Capsule().strokeBorder(
                        isSelected ? AnyShapeStyle(gradient) : AnyShapeStyle(DS.Gradients.glassEdge),
                        lineWidth: isSelected ? 1.5 : DS.Size.hairline
                    )
                }
                .dsGlow(colors.first ?? DS.Colors.accent, radius: 14, strength: isSelected ? 0.35 : 0)
                .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .animation(DS.Motion.quick, value: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Bracket

/// One thing splitting into several, drawn like Opal's score bracket:
/// a stem from the top centre, a bar across, and a drop to each child.
/// Children are assumed to share the width equally (an `HStack` of equal widths).
struct BracketShape: Shape {
    var count: Int
    var spacing: CGFloat = DS.Space.xs
    var corner: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard count > 0 else { return path }
        let width = (rect.width - spacing * CGFloat(count - 1)) / CGFloat(count)
        let centers = (0..<count).map { rect.minX + width / 2 + CGFloat($0) * (width + spacing) }
        let bar = rect.minY + rect.height * 0.45
        // The stem.
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: bar))
        guard let first = centers.first, let last = centers.last, count > 1 else {
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            return path
        }
        // The bar, rounding down into the outer drops.
        path.move(to: CGPoint(x: first, y: rect.maxY))
        path.addLine(to: CGPoint(x: first, y: bar + corner))
        path.addQuadCurve(to: CGPoint(x: first + corner, y: bar), control: CGPoint(x: first, y: bar))
        path.addLine(to: CGPoint(x: last - corner, y: bar))
        path.addQuadCurve(to: CGPoint(x: last, y: bar + corner), control: CGPoint(x: last, y: bar))
        path.addLine(to: CGPoint(x: last, y: rect.maxY))
        // Inner drops.
        for x in centers.dropFirst().dropLast() {
            path.move(to: CGPoint(x: x, y: bar))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        return path
    }
}

// MARK: - Branches

/// A row hanging off a trunk line on the left, joined to it by a curve:
/// the alternatives that branch off a moment. Stack rows with no spacing;
/// each row pads its own bottom so the trunk runs unbroken.
struct BranchRow<Content: View>: View {
    let isLast: Bool
    var ink: Color = DS.Colors.accent
    var isLit = false
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.leading, DS.Size.branchGutter)
            .padding(.bottom, isLast ? 0 : DS.Space.s)
            .background(alignment: .topLeading) {
                GeometryReader { proxy in
                    let rowHeight = proxy.size.height - (isLast ? 0 : DS.Space.s)
                    let mid = rowHeight / 2
                    let trunk: CGFloat = DS.Size.rule / 2 + 4
                    ZStack(alignment: .topLeading) {
                        // The trunk, down to this row (and on, unless it's the last).
                        Path { path in
                            path.move(to: CGPoint(x: trunk, y: 0))
                            path.addLine(to: CGPoint(x: trunk, y: isLast ? mid - 10 : proxy.size.height))
                        }
                        .stroke(DS.Colors.inkTertiary.opacity(0.6), lineWidth: DS.Size.rule * 0.75)
                        // The branch, curving into the row.
                        Path { path in
                            path.move(to: CGPoint(x: trunk, y: mid - 12))
                            path.addQuadCurve(
                                to: CGPoint(x: DS.Size.branchGutter, y: mid),
                                control: CGPoint(x: trunk, y: mid)
                            )
                        }
                        .stroke(
                            isLit ? AnyShapeStyle(ink) : AnyShapeStyle(DS.Colors.inkTertiary.opacity(0.6)),
                            style: StrokeStyle(lineWidth: DS.Size.rule * 0.75, lineCap: .round)
                        )
                        .dsGlow(ink, radius: 6, strength: isLit ? 0.7 : 0)
                    }
                }
                .accessibilityHidden(true)
            }
    }
}

#Preview {
    @Previewable @State var choice = 1
    ScrollView {
        VStack(spacing: DS.Space.l) {
            ArcGauge(value: 0.4) {
                VStack(spacing: 0) {
                    Text("40%").font(DS.Typography.gauge).foregroundStyle(DS.Colors.accent)
                    Text("Read").font(DS.Typography.caption).foregroundStyle(DS.Colors.inkSecondary)
                }
            }
            BracketShape(count: 3)
                .stroke(DS.Colors.inkTertiary, lineWidth: 1)
                .frame(height: 24)
            HStack(spacing: DS.Space.xs) {
                GlowPill(title: "Finished", systemImage: "checkmark.seal.fill", isSelected: choice == 0) { choice = 0 }
                GlowPill(title: "Partway", systemImage: "bookmark.fill", isSelected: choice == 1) { choice = 1 }
                GlowPill(title: "Not yet", systemImage: "book.closed", isSelected: choice == 2) { choice = 2 }
            }
            VStack(spacing: 0) {
                BranchRow(isLast: false, isLit: true) { ChoiceRow(text: "Darcy never writes the letter", isSelected: true) {} }
                BranchRow(isLast: true) { ChoiceRow(text: "Lydia is found first", isSelected: false) {} }
            }
        }
        .padding(DS.Space.screen)
    }
    .dsScreen()
}
