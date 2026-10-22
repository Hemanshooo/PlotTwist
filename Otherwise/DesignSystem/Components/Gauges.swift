import SwiftUI

// MARK: - Reading vine

/// How far you've read, as a vine growing across the screen: a dotted path
/// for the whole book, the stem grown along it as far as you've read, leaves
/// unfurling as it passes, a bud at its tip while you're partway, and a rose
/// once you've finished.
struct VineGauge: View, Animatable {
    /// 0…1.
    var value: Double
    /// Whether you've finished: the tip opens into a rose.
    var isFinished: Bool

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    private static let leaves: [Double] = [0.07, 0.17, 0.27, 0.37, 0.47, 0.57, 0.67, 0.77, 0.87]

    var body: some View {
        let ink = GardenInk.current
        let track = DS.Colors.inkTertiary
        Canvas { context, size in
            let inset: CGFloat = 14
            let span = size.width - inset * 2
            let mid = size.height / 2
            let amplitude = size.height * 0.08
            func point(_ t: Double) -> CGPoint {
                CGPoint(x: inset + span * t, y: mid + sin(t * .pi * 5) * amplitude)
            }
            let samples = stride(from: 0.0, through: 1.0, by: 0.025).map(point)
            let path = Botany.stem(through: samples)
            // The whole book, still to grow.
            context.stroke(path, with: .color(track), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [1, 5]))
            let grown = min(max(value, 0), 1)
            context.drawStem(path, ink: ink, width: DS.Size.stem + 0.2, progress: grown)
            // Leaves, alternately above and below, as the stem passes.
            for (i, t) in Self.leaves.enumerated() where t < grown {
                let up = i.isMultiple(of: 2)
                context.drawLeaf(
                    at: point(t),
                    angle: .degrees(up ? -132 : 132),
                    length: size.height * 0.3,
                    ink: ink,
                    open: Ease.opening(grown, start: t, span: 0.08)
                )
            }
            // The tip.
            let tip = point(grown)
            if isFinished {
                context.drawRose(at: tip, size: size.height * 0.5, seed: 4, ink: ink, open: Ease.opening(grown, start: 0.9, span: 0.1))
            } else if grown > 0.02 {
                let ahead = point(min(grown + 0.01, 1))
                let angle = Angle.radians(atan2(ahead.y - tip.y, ahead.x - tip.x))
                context.drawBud(at: tip, angle: angle, length: size.height * 0.3, ink: ink)
            } else {
                context.fill(Path(ellipseIn: CGRect(x: tip.x - 3, y: tip.y - 3, width: 6, height: 6)), with: .color(ink.stem))
            }
        }
        .frame(height: DS.Size.gaugeHeight)
        .accessibilityHidden(true)
    }
}

// MARK: - Choice pills

/// Options in an outlined capsule, the chosen one in a solid ink pill that
/// slides between them, like Type Garden's Type | Poster toggle.
struct ChoicePills<ID: Hashable>: View {
    struct Option: Identifiable {
        let id: ID
        let title: LocalizedStringKey
    }

    let options: [Option]
    let selection: ID?
    let onSelect: (ID) -> Void

    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                let isSelected = option.id == selection
                Button {
                    onSelect(option.id)
                } label: {
                    Text(option.title)
                        .font(DS.Typography.label)
                        .foregroundStyle(isSelected ? DS.Colors.onInk : DS.Colors.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: DS.Size.pill)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(DS.Colors.ink)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(3)
        .overlay { Capsule().strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline) }
        .animation(DS.Motion.select, value: selection)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

// MARK: - Branches

/// A row hanging off a stem on the left, joined to it by a branch: the
/// alternatives that grow from a moment. The chosen branch flowers; the
/// others carry a leaf. Stack rows with no spacing; each row pads its own
/// bottom so the stem runs unbroken.
struct BranchRow<Content: View>: View {
    let isLast: Bool
    var isLit = false
    var seed = 0
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.leading, DS.Size.vineGutter)
            .padding(.bottom, isLast ? 0 : DS.Space.s)
            .background(alignment: .topLeading) {
                BranchDrawing(isLast: isLast, bloom: isLit ? 1 : 0, gap: isLast ? 0 : DS.Space.s, seed: seed)
                    .animation(DS.Motion.bloom(), value: isLit)
            }
    }
}

private struct BranchDrawing: View, Animatable {
    let isLast: Bool
    var bloom: Double
    let gap: CGFloat
    let seed: Int

    var animatableData: Double {
        get { bloom }
        set { bloom = newValue }
    }

    var body: some View {
        let ink = GardenInk.current
        Canvas { context, size in
            let rowHeight = size.height - gap
            let mid = rowHeight / 2
            let trunk: CGFloat = 7
            // The stem, down past this row unless it's the last.
            var stem = Path()
            stem.move(to: CGPoint(x: trunk, y: 0))
            stem.addLine(to: CGPoint(x: trunk, y: isLast ? mid - 12 : size.height))
            context.drawStem(stem, ink: ink, width: 1.4)
            // The branch, curving out to the row.
            let end = CGPoint(x: DS.Size.vineGutter - 11, y: mid)
            var branch = Path()
            branch.move(to: CGPoint(x: trunk, y: mid - 14))
            branch.addQuadCurve(to: end, control: CGPoint(x: trunk, y: mid))
            context.drawStem(branch, ink: ink, width: 1.4)
            // A leaf on every branch; a rose opens on the chosen one.
            context.drawLeaf(at: CGPoint(x: trunk + 3, y: mid - 7), angle: .degrees(-62), length: 9, ink: ink, open: 1 - bloom * 0.4, vein: false)
            context.drawRose(at: end, size: 17, seed: seed, ink: ink, open: bloom)
            if bloom < 0.99 {
                context.fill(
                    Path(ellipseIn: CGRect(x: end.x - 2.5, y: end.y - 2.5, width: 5, height: 5)),
                    with: .color(ink.stem.opacity(1 - bloom))
                )
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    @Previewable @State var choice = 1
    @Previewable @State var value = 0.4
    ScrollView {
        VStack(spacing: DS.Space.l) {
            VineGauge(value: value, isFinished: value >= 1)
                .onTapGesture { withAnimation(.easeInOut(duration: 1.2)) { value = value >= 1 ? 0.2 : 1 } }
            ChoicePills(
                options: [.init(id: 0, title: "Finished"), .init(id: 1, title: "Partway"), .init(id: 2, title: "Not yet")],
                selection: choice
            ) { choice = $0 }
            VStack(spacing: 0) {
                BranchRow(isLast: false, isLit: choice == 0) { ChoiceRow(text: "Darcy never writes the letter", isSelected: choice == 0) { choice = 0 } }
                BranchRow(isLast: true, isLit: choice == 1) { ChoiceRow(text: "Lydia is found first", isSelected: choice == 1) { choice = 1 } }
            }
        }
        .padding(DS.Space.screen)
    }
    .dsScreen()
}
