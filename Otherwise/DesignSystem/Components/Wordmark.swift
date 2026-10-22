import SwiftUI

/// The Plot Twist wordmark, as on the app icon: Plot upright, and Twist
/// hanging upside down from the same line, its T tucked under the P, so the
/// words turn back on themselves the way a plot does. A vine grows along the
/// line between them, curling at one end and blooming into a rose at the other.
///
/// When it first appears, Twist turns over into place and the vine grows.
/// Tapping it spins Twist round once more and regrows the vine.
struct Wordmark: View {
    /// Twist's turn, in degrees: 180 once it's in place; each replay adds a full turn.
    @State private var turn: Double = 0
    @State private var growth: Double = 0
    @State private var plays = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far Twist's T reaches in under the P.
    private let tuck: CGFloat = 7

    var body: some View {
        VStack(alignment: .hinge, spacing: -11) {
            Text("Plot")
                .alignmentGuide(.hinge) { $0[.leading] }
            Text("Twist")
                .rotationEffect(.degrees(turn))
                .alignmentGuide(.hinge) { $0[.trailing] - tuck }
        }
        .font(DS.Typography.wordmark)
        .foregroundStyle(DS.Colors.ink)
        .lineLimit(1)
        .fixedSize()
        .padding(.trailing, 14)
        .padding(.leading, 6)
        .overlay { WordmarkVine(progress: growth) }
        .contentShape(Rectangle())
        .onTapGesture(perform: replay)
        .sensoryFeedback(.impact(weight: .light), trigger: plays)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Plot Twist")
        .accessibilityAddTraits(.isHeader)
        .onAppear {
            guard turn == 0 else { return }
            play()
        }
    }

    private func play() {
        if reduceMotion {
            turn = 180
            growth = 1
            return
        }
        withAnimation(DS.Motion.twist.delay(0.3)) { turn = 180 }
        withAnimation(.easeInOut(duration: 1.3).delay(0.55)) { growth = 1 }
    }

    private func replay() {
        guard !reduceMotion else { return }
        plays += 1
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { growth = 0 }
        withAnimation(DS.Motion.twist) { turn += 360 }
        withAnimation(.easeInOut(duration: 1.2).delay(0.35)) { growth = 1 }
    }
}

/// The vine along the line between Plot and Twist.
private struct WordmarkVine: View, Animatable {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let ink = GardenInk.current
        Canvas { context, size in
            let line = size.height * 0.5
            let start = CGPoint(x: 5, y: line + 1)
            let end = CGPoint(x: size.width - 8, y: line - 1)
            let points = (0...10).map { i -> CGPoint in
                let t = Double(i) / 10
                return CGPoint(
                    x: start.x + (end.x - start.x) * t,
                    y: start.y + (end.y - start.y) * t + sin(t * .pi * 3) * 1.8
                )
            }
            let grow = min(progress / 0.75, 1)
            context.drawStem(Botany.stem(through: points), ink: ink, width: 1.4, progress: grow)
            // A curl where the vine starts.
            context.drawStem(
                Botany.tendril(start: start, angle: .degrees(180), radius: 3.6, clockwise: false),
                ink: ink,
                width: 1.2,
                progress: min(progress / 0.2, 1)
            )
            // Leaves, one above the line and one below.
            context.drawLeaf(at: points[3], angle: .degrees(-128), length: 9.5, ink: ink, open: Ease.opening(progress, start: 0.25), vein: false)
            context.drawLeaf(at: points[6], angle: .degrees(48), length: 9, ink: ink, open: Ease.opening(progress, start: 0.45), vein: false)
            // The rose at the end.
            context.drawRose(at: CGPoint(x: end.x + 1, y: end.y), size: 14, seed: 8, ink: ink, open: Ease.opening(progress, start: 0.68, span: 0.32))
        }
        .allowsHitTesting(false)
    }
}

extension HorizontalAlignment {
    /// The line where Plot starts and Twist (upside down) ends.
    fileprivate enum Hinge: AlignmentID {
        static func defaultValue(in dimensions: ViewDimensions) -> CGFloat { dimensions[.leading] }
    }

    fileprivate static let hinge = HorizontalAlignment(Hinge.self)
}

#Preview {
    Wordmark()
        .scaleEffect(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Colors.canvas)
}
