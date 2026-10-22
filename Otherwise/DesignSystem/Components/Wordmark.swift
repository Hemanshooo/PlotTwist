import SwiftUI

/// The Plot Twist wordmark: the name set plainly in Instrument Serif, with a
/// garland grown around it, after Type Garden. Two vines wind through the
/// words, passing in front of some letters and behind others, curling at
/// their ends; leaves along them; and roses before Plot, over the T, in a
/// pair after Twist and one below.
///
/// When it first appears the garland grows: the vines draw themselves, the
/// leaves unfurl as they pass, and the roses open last. Tapping it grows it again.
struct Wordmark: View {
    @State private var growth: Double = 0
    @State private var plays = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        WordmarkGarland(progress: growth)
            .frame(width: WordmarkGarland.size.width, height: WordmarkGarland.size.height)
            .contentShape(Rectangle())
            .onTapGesture(perform: replay)
            .sensoryFeedback(.impact(weight: .light), trigger: plays)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Plot Twist")
            .accessibilityAddTraits(.isHeader)
            .onAppear {
                guard growth == 0 else { return }
                if reduceMotion {
                    growth = 1
                } else {
                    withAnimation(.easeInOut(duration: 1.6).delay(0.25)) { growth = 1 }
                }
            }
    }

    private func replay() {
        guard !reduceMotion else { return }
        plays += 1
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { growth = 0 }
        withAnimation(.easeInOut(duration: 1.4)) { growth = 1 }
    }
}

/// The words and their garland, drawn from `progress` (0…1).
///
/// Everything is laid out in ems of the type size, from where the words start
/// (x) and their baseline (y, negative is up): "Plot Twist" runs 0 → 3.35 em.
struct WordmarkGarland: View, Animatable {
    var progress: Double
    var em: CGFloat = DS.Size.wordmark

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// Room around the words for the garland, in ems.
    private static let margin = (left: 0.8, right: 0.64, top: 1.2, bottom: 0.52)
    private static let words: CGFloat = 3.35

    static var size: CGSize { size(for: DS.Size.wordmark) }

    static func size(for em: CGFloat) -> CGSize {
        CGSize(
            width: (margin.left + words + margin.right) * em,
            height: (margin.top + margin.bottom) * em
        )
    }

    /// The upper vine: from a curl before Plot, through the P, over the T,
    /// dipping through the w and rising over the end of Twist.
    private static let upper = points([
        (-0.46, -0.02), (-0.18, 0.12), (0.1, -0.12), (0.42, -0.58), (0.8, -0.9), (1.18, -0.72), (1.5, -0.98),
        (1.9, -0.9), (2.2, -0.5), (2.56, -0.2), (2.92, -0.46), (3.26, -0.82), (3.6, -0.7), (3.82, -0.4),
    ])
    /// The lower vine, wandering along under the words.
    private static let lower = points([
        (0.0, 0.32), (0.4, 0.1), (0.8, 0.24), (1.2, -0.12), (1.6, 0.18), (2.0, 0.24), (2.4, -0.04), (2.8, 0.26), (3.2, 0.18), (3.56, 0.34),
    ])
    /// Stretches of each vine (as fractions of its length) that pass in front of the letters.
    private static let upperFront: [(Double, Double)] = [(0.14, 0.26), (0.5, 0.6), (0.74, 0.84)]
    private static let lowerFront: [(Double, Double)] = [(0.0, 0.16), (0.34, 0.5), (0.7, 0.86)]
    /// Roses: where (ems), how wide (ems), seed, and when each opens.
    private static let roses: [(x: CGFloat, y: CGFloat, width: CGFloat, seed: Int, opens: Double)] = [
        (-0.4, -0.42, 0.64, 1, 0.42), (1.6, -0.96, 0.56, 3, 0.56),
        (3.62, -0.8, 0.54, 5, 0.66), (3.66, -0.22, 0.44, 6, 0.72), (2.62, 0.32, 0.34, 4, 0.62),
    ]

    var body: some View {
        let ink = GardenInk.current
        let words = Text(verbatim: "Plot Twist")
            .font(DS.Typography.wordmark(em))
            .foregroundStyle(DS.Colors.ink)
        Canvas { context, _ in
            let em = self.em
            let m = Self.margin
            func at(_ p: CGPoint) -> CGPoint { CGPoint(x: (m.left + p.x) * em, y: (m.top + p.y) * em) }
            let upper = Botany.stem(through: Self.upper.map(at))
            let lower = Botany.stem(through: Self.lower.map(at))
            let grown = min(progress / 0.72, 1)
            let stem = max(1.2, em * 0.04)

            // Behind the words: both vines whole, as far as they've grown.
            context.drawStem(upper, ink: ink, width: stem, progress: grown)
            context.drawStem(lower, ink: ink, width: stem * 0.9, progress: grown)

            // The words.
            let resolved = context.resolve(words)
            let measured = resolved.measure(in: CGSize(width: 1000, height: 1000))
            let baseline = resolved.firstBaseline(in: measured)
            context.draw(resolved, at: CGPoint(x: m.left * em, y: m.top * em - baseline), anchor: .topLeading)

            // In front: the stretches that cross over letters.
            for (path, fronts, width) in [(upper, Self.upperFront, stem), (lower, Self.lowerFront, stem * 0.9)] {
                for (from, to) in fronts where grown > from {
                    context.stroke(
                        path.trimmedPath(from: from, to: min(to, grown)),
                        with: .color(ink.stem),
                        style: StrokeStyle(lineWidth: width, lineCap: .round)
                    )
                }
            }

            // Curls at the vines' ends, once they've reached them.
            let curl = Ease.opening(progress, start: 0.6, span: 0.3)
            if curl > 0 {
                let curls: [(CGPoint, Angle, Bool, CGFloat)] = [
                    (Self.upper[0], .degrees(171), false, 0.11), (Self.upper[Self.upper.count - 1], .degrees(72), true, 0.11),
                    (Self.lower[0], .degrees(126), false, 0.08), (Self.lower[Self.lower.count - 1], .degrees(-17), true, 0.09),
                ]
                for (start, angle, clockwise, radius) in curls {
                    context.drawStem(
                        Botany.tendril(start: at(start), angle: angle, radius: radius * em, clockwise: clockwise),
                        ink: ink,
                        width: stem * 0.9,
                        progress: min(curl, 1)
                    )
                }
            }

            // Leaves, unfurling as the vines pass them.
            for (path, stops, size, side) in [
                (upper, [0.06, 0.16, 0.27, 0.38, 0.49, 0.6, 0.71, 0.82, 0.92], 0.32, 1.0),
                (lower, [0.12, 0.3, 0.5, 0.68, 0.86], 0.28, -1.0),
            ] {
                for (i, t) in stops.enumerated() {
                    let (point, direction) = Self.pointAndDirection(on: path, at: t)
                    let flip = i.isMultiple(of: 2) ? side : -side
                    context.drawLeaf(
                        at: point,
                        angle: direction + .degrees(flip * 48),
                        length: em * size * (0.85 + 0.3 * Double((i * 37) % 7) / 7),
                        ink: ink,
                        open: Ease.opening(progress, start: t * 0.72, span: 0.14),
                        vein: em > 30
                    )
                }
            }

            // Roses, last.
            for rose in Self.roses {
                context.drawRose(
                    at: at(CGPoint(x: rose.x, y: rose.y)),
                    size: rose.width * em,
                    seed: rose.seed,
                    ink: ink,
                    open: Ease.opening(progress, start: rose.opens, span: 0.3)
                )
            }
        }
        .accessibilityHidden(true)
    }

    private static func points(_ values: [(Double, Double)]) -> [CGPoint] {
        values.map { CGPoint(x: $0.0, y: $0.1) }
    }

    private static func pointAndDirection(on path: Path, at t: Double) -> (CGPoint, Angle) {
        let here = path.trimmedPath(from: 0, to: max(t, 0.002)).currentPoint ?? .zero
        let before = path.trimmedPath(from: 0, to: max(t - 0.01, 0.001)).currentPoint ?? here
        return (here, .radians(atan2(here.y - before.y, here.x - before.x)))
    }
}

#Preview {
    VStack(spacing: DS.Space.xl) {
        Wordmark()
        Growing { WordmarkGarland(progress: $0, em: 64) }
            .frame(width: WordmarkGarland.size(for: 64).width, height: WordmarkGarland.size(for: 64).height)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Colors.canvas)
}
