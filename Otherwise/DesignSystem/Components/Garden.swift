import SwiftUI

/// The garden that grows through Plot Twist: stems and leaves in the
/// palette's `stem` colour, roses and buds in its `bloom`, with `petal` lines
/// drawn on each rose. Flat, two colours, a little hand-drawn, after Type Garden.
///
/// Every drawing takes a `progress` (0…1) and is `Animatable`, so it can
/// grow: stems draw themselves, leaves unfurl as the stem passes them, and
/// roses open last. Wrap one in `Growing` to grow it when it first appears.

// MARK: - Seeded randomness

/// Stable pseudo-random numbers, so each rose is its own but never changes.
struct Seeded {
    private var state: UInt64

    init(_ seed: Int) {
        state = (UInt64(truncatingIfNeeded: seed) &+ 0x9E37_79B9_7F4A_7C15) &* 0xBF58_476D_1CE4_E5B9 | 1
    }

    mutating func next() -> Double {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return Double((state &* 2_685_821_657_736_338_717) >> 11) / Double(UInt64(1) << 53)
    }
}

// MARK: - Shapes

/// The paths every drawing is made from.
enum Botany {
    /// A rose seen three-quarters on: a wide head with a scalloped edge,
    /// tipped a little one way or the other.
    static func roseHead(center c: CGPoint, radius r: CGFloat, seed: Int) -> Path {
        let tilt = roseTilt(seed)
        let a = r, b = r * 0.8
        let bumps = 9.0
        let phase = Double(seed) * 0.7
        var path = Path()
        let steps = 72
        for i in 0..<steps {
            let theta = Double(i) / Double(steps) * 2 * .pi
            let scallop = abs(sin(theta * bumps / 2 + phase))
            let k = 0.94 + 0.1 * scallop + 0.04 * sin(theta * 2 + Double(seed))
            let point = turned(CGPoint(x: cos(theta) * a * k, y: sin(theta) * b * k), by: tilt, about: c)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    /// The lines drawn on a rose: a loose spiral at its heart, and two wavy
    /// petal edges across the lower part of the head.
    static func roseLines(center c: CGPoint, radius r: CGFloat, seed: Int) -> Path {
        var rng = Seeded(seed &+ 101)
        let tilt = roseTilt(seed)
        let w = r * 2, a = r, b = r * 0.8
        var path = Path()
        let heart = CGPoint(x: w * 0.06 * (rng.next() - 0.5), y: -b * 0.18)
        let start = rng.next() * 2 * .pi
        let steps = 52
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let angle = start + t * 2.2 * 2 * .pi
            let radius = w * (0.02 + 0.27 * t)
            let point = turned(CGPoint(x: heart.x + cos(angle) * radius, y: heart.y + sin(angle) * radius * 0.7), by: tilt, about: c)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        for (y, span, waves) in [(b * 0.5, 0.66, 3.0), (b * 0.78, 0.4, 2.0)] {
            let samples = Int(waves) * 12
            for i in 0...samples {
                let t = Double(i) / Double(samples)
                let x = -a * span + 2 * a * span * t
                let point = turned(CGPoint(x: x, y: y - abs(sin(t * waves * .pi)) * w * 0.07), by: tilt, about: c)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
        }
        return path
    }

    /// Each rose leans its own way, by a seeded few degrees.
    private static func roseTilt(_ seed: Int) -> Double {
        var rng = Seeded(seed &+ 57)
        return (rng.next() - 0.5) * 0.45
    }

    private static func turned(_ p: CGPoint, by angle: Double, about c: CGPoint) -> CGPoint {
        CGPoint(x: c.x + p.x * cos(angle) - p.y * sin(angle), y: c.y + p.x * sin(angle) + p.y * cos(angle))
    }

    /// A pointed leaf growing from `base` at `angle`, `length` long.
    static func leaf(base: CGPoint, angle: Angle, length: CGFloat, width: CGFloat? = nil) -> Path {
        let w = width ?? length * 0.44
        var path = Path()
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: length, y: 0), control: CGPoint(x: length * 0.36, y: -w))
        path.addQuadCurve(to: .zero, control: CGPoint(x: length * 0.64, y: w * 0.8))
        path.closeSubpath()
        return path.applying(placing(base, angle))
    }

    /// The vein down the middle of a leaf, cut in the ground colour.
    static func leafVein(base: CGPoint, angle: Angle, length: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: length * 0.18, y: 0))
        path.addQuadCurve(to: CGPoint(x: length * 0.78, y: -length * 0.03), control: CGPoint(x: length * 0.5, y: length * 0.04))
        return path.applying(placing(base, angle))
    }

    /// A closed bud: a teardrop whose tip points along `angle`, from `base`.
    static func bud(base: CGPoint, angle: Angle, length: CGFloat) -> Path {
        let w = length * 0.66
        var path = Path()
        path.move(to: CGPoint(x: length, y: 0))
        path.addCurve(
            to: CGPoint(x: 0, y: 0),
            control1: CGPoint(x: length * 0.55, y: -w * 0.7),
            control2: CGPoint(x: -length * 0.05, y: -w * 0.62)
        )
        path.addCurve(
            to: CGPoint(x: length, y: 0),
            control1: CGPoint(x: -length * 0.05, y: w * 0.62),
            control2: CGPoint(x: length * 0.55, y: w * 0.7)
        )
        path.closeSubpath()
        return path.applying(placing(base, angle))
    }

    /// A tendril: a stroke leaving `start` along `angle` and curling in on
    /// itself, clockwise (as seen on screen) or not.
    static func tendril(start: CGPoint, angle: Angle, radius: CGFloat, turns: Double = 1.25, clockwise: Bool = true) -> Path {
        var path = Path()
        let flip: CGFloat = clockwise ? 1 : -1
        let total = turns * 2 * .pi
        let steps = 36
        for i in 0...steps {
            let theta = Double(i) / Double(steps) * total
            let r = radius * (1 - 0.72 * theta / total)
            // Around a centre `radius` to one side of the start, closing in.
            let point = CGPoint(x: r * sin(theta), y: flip * (radius - r * cos(theta)))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path.applying(placing(start, angle))
    }

    /// A stem through `points`, smoothed.
    static func stem(through points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        guard points.count > 2 else {
            if let last = points.last { path.addLine(to: last) }
            return path
        }
        for i in 0..<(points.count - 1) {
            let p0 = points[max(i - 1, 0)], p1 = points[i], p2 = points[i + 1], p3 = points[min(i + 2, points.count - 1)]
            path.addCurve(
                to: p2,
                control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            )
        }
        return path
    }

    private static func placing(_ point: CGPoint, _ angle: Angle) -> CGAffineTransform {
        CGAffineTransform(translationX: point.x, y: point.y).rotated(by: angle.radians)
    }
}

// MARK: - Drawing

/// The garden's colours, read once in a view's body and handed to its Canvas.
struct GardenInk {
    var stem: Color
    var bloom: Color
    var petal: Color
    /// The ground, for veins cut into leaves.
    var ground: Color

    static var current: GardenInk {
        GardenInk(stem: DS.Colors.stem, bloom: DS.Colors.bloom, petal: DS.Colors.petal, ground: DS.Colors.canvas)
    }

    /// One colour for everything: an unselected icon.
    static func mono(_ color: Color, ground: Color) -> GardenInk {
        GardenInk(stem: color, bloom: color, petal: ground, ground: ground)
    }
}

extension GraphicsContext {
    /// A rose `size` wide at `center`, opened `open` (0…1).
    func drawRose(at center: CGPoint, size: CGFloat, seed: Int, ink: GardenInk, open: Double = 1) {
        guard open > 0.01 else { return }
        let radius = size / 2 * open
        fill(Botany.roseHead(center: center, radius: radius, seed: seed), with: .color(ink.bloom))
        stroke(
            Botany.roseLines(center: center, radius: radius, seed: seed),
            with: .color(ink.petal),
            style: StrokeStyle(lineWidth: max(0.6, size * 0.04 * open), lineCap: .round, lineJoin: .round)
        )
    }

    /// A leaf `length` long, unfurled `open` (0…1).
    func drawLeaf(at base: CGPoint, angle: Angle, length: CGFloat, ink: GardenInk, open: Double = 1, vein: Bool = true) {
        guard open > 0.01 else { return }
        let grown = length * open
        fill(Botany.leaf(base: base, angle: angle, length: grown), with: .color(ink.stem))
        if vein, grown > 6 {
            stroke(Botany.leafVein(base: base, angle: angle, length: grown), with: .color(ink.ground), lineWidth: max(0.6, grown * 0.045))
        }
    }

    /// A closed bud with two sepals, its tip along `angle`.
    func drawBud(at base: CGPoint, angle: Angle, length: CGFloat, ink: GardenInk, open: Double = 1) {
        guard open > 0.01 else { return }
        let grown = length * open
        fill(Botany.bud(base: base, angle: angle, length: grown), with: .color(ink.bloom))
        for side in [-1.0, 1.0] {
            fill(
                Botany.leaf(base: base, angle: angle + .degrees(side * 32), length: grown * 0.62, width: grown * 0.22),
                with: .color(ink.stem)
            )
        }
    }

    /// A stem stroke, drawn up to `progress` of its length.
    func drawStem(_ path: Path, ink: GardenInk, width: CGFloat = DS.Size.stem, progress: Double = 1) {
        guard progress > 0.001 else { return }
        stroke(
            progress >= 0.999 ? path : path.trimmedPath(from: 0, to: progress),
            with: .color(ink.stem),
            style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
        )
    }
}

extension Ease {
    /// Overshoots a little, then settles: leaves and roses opening.
    static func outBack(_ x: Double) -> Double {
        let c1 = 1.70158, c3 = c1 + 1
        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
    }

    /// How open something is that starts opening at `start` and takes `span` of the growth.
    static func opening(_ progress: Double, start: Double, span: Double = 0.22) -> Double {
        let t = min(max((progress - start) / span, 0), 1)
        return t <= 0 ? 0 : outBack(t)
    }
}

// MARK: - Growing

/// Grows its drawing once, when it first appears: `progress` runs 0 → 1.
/// Under Reduce Motion the drawing appears fully grown.
struct Growing<Content: View>: View {
    var delay: Double = 0
    var animation: Animation = DS.Motion.grow
    @ViewBuilder let content: (Double) -> Content

    @State private var progress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content(progress)
            .onAppear {
                guard progress < 1 else { return }
                if reduceMotion {
                    progress = 1
                } else {
                    withAnimation(animation.delay(delay)) { progress = 1 }
                }
            }
    }
}

// MARK: - Rose and bud

/// A single rose.
struct Rose: View, Animatable {
    var size: CGFloat = DS.Size.rose
    var seed = 0
    /// 0…1: how open it is.
    var open: Double = 1

    var animatableData: Double {
        get { open }
        set { open = newValue }
    }

    var body: some View {
        let ink = GardenInk.current
        Canvas { context, canvas in
            context.drawRose(at: CGPoint(x: canvas.width / 2, y: canvas.height / 2), size: size, seed: seed, ink: ink, open: open)
        }
        .frame(width: size * 1.1, height: size * 1.1)
        .accessibilityHidden(true)
    }
}

/// A closed bud on a short stalk, pointing up.
struct Bud: View, Animatable {
    var size: CGFloat = DS.Size.rose
    var open: Double = 1
    /// Drawn in one colour (sealed things).
    var muted = false

    var animatableData: Double {
        get { open }
        set { open = newValue }
    }

    var body: some View {
        let ink = muted ? GardenInk.mono(DS.Colors.inkTertiary, ground: DS.Colors.canvas) : .current
        Canvas { context, canvas in
            let base = CGPoint(x: canvas.width / 2, y: canvas.height * 0.82)
            context.drawBud(at: base, angle: .degrees(-90), length: size * 0.78, ink: ink, open: open)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Flourish

/// A printer's flourish grown from the garden: a short stem with a rose at
/// its heart, leaves either side and tendrils curling at both ends. Sits
/// under titles.
struct Flourish: View, Animatable {
    var width: CGFloat = 132
    var progress: Double = 1
    var seed = 3

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let ink = GardenInk.current
        let height = width * 0.2
        Canvas { context, size in
            let mid = CGPoint(x: size.width / 2, y: size.height / 2)
            let reach = size.width / 2 - height * 0.5
            // Two stems growing out from the rose, each ending in a curl.
            for side in [-1.0, 1.0] {
                let points = stride(from: 0.0, through: 1.0, by: 0.125).map { t -> CGPoint in
                    CGPoint(x: mid.x + side * reach * t, y: mid.y + sin(t * .pi * 1.6) * height * 0.16 * side)
                }
                let grow = min(progress / 0.7, 1)
                context.drawStem(Botany.stem(through: points), ink: ink, width: 1.3, progress: grow)
                if let end = points.last, grow >= 0.999 {
                    context.stroke(
                        Botany.tendril(start: end, angle: .degrees(side > 0 ? 0 : 180), radius: height * 0.22, clockwise: side > 0),
                        with: .color(ink.stem),
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
                    )
                }
                for (i, t) in [0.34, 0.66].enumerated() {
                    let base = CGPoint(x: mid.x + side * reach * t, y: mid.y + sin(t * .pi * 1.6) * height * 0.16 * side)
                    let up = i == 0
                    let angle = Angle.degrees(side > 0 ? (up ? -38 : 30) : (up ? -142 : 150))
                    context.drawLeaf(at: base, angle: angle, length: height * 0.62, ink: ink, open: Ease.opening(progress, start: 0.2 + Double(i) * 0.2), vein: false)
                }
            }
            context.drawRose(at: mid, size: height * 0.95, seed: seed, ink: ink, open: Ease.opening(progress, start: 0.6, span: 0.4))
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Sprig

/// A stem rising from the ground with leaves and a rose at its tip.
/// The illustration for empty states and the palette sheet.
struct Sprig: View, Animatable {
    var height: CGFloat = 96
    var progress: Double = 1
    var seed = 11

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let ink = GardenInk.current
        let width = height * 0.6
        Canvas { context, size in
            let bottom = CGPoint(x: size.width * 0.48, y: size.height)
            let rose = CGPoint(x: size.width * 0.56, y: height * 0.2)
            let points = (0...8).map { i -> CGPoint in
                let t = Double(i) / 8
                return CGPoint(
                    x: bottom.x + (rose.x - bottom.x) * t + sin(t * .pi * 1.4) * width * 0.12,
                    y: bottom.y + (rose.y - bottom.y) * t
                )
            }
            context.drawStem(Botany.stem(through: points), ink: ink, width: 1.8, progress: min(progress / 0.7, 1))
            let leaves: [(Int, Angle, Double)] = [(2, .degrees(-150), 0.18), (4, .degrees(-30), 0.34), (6, .degrees(-155), 0.5)]
            for (index, angle, start) in leaves {
                context.drawLeaf(at: points[index], angle: angle, length: height * 0.3, ink: ink, open: Ease.opening(progress, start: start))
            }
            context.drawStem(
                Botany.tendril(start: points[5], angle: .degrees(-10), radius: height * 0.07, clockwise: false),
                ink: ink,
                width: 1.4,
                progress: min(max((progress - 0.4) / 0.25, 0), 1)
            )
            context.drawRose(at: rose, size: height * 0.34, seed: seed, ink: ink, open: Ease.opening(progress, start: 0.62, span: 0.38))
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Twist mark

/// The mark for a twisted story: one stem forking in two, a leaf at the end
/// of one branch and a rose at the end of the other.
struct TwistDrawing {
    /// Draws into `rect` (square), the rose `open` (0…1).
    static func draw(in context: GraphicsContext, rect: CGRect, ink: GardenInk, open: Double = 1, stemWidth: CGFloat? = nil) {
        let u = rect.width / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * u, y: rect.minY + y * u) }
        var stems = Path()
        stems.move(to: p(12, 22))
        stems.addLine(to: p(12, 14.5))
        stems.addCurve(to: p(6.4, 8.2), control1: p(12, 11.5), control2: p(6.6, 11.6))
        stems.move(to: p(12, 14.5))
        stems.addCurve(to: p(17.2, 7.4), control1: p(12, 11.4), control2: p(17.2, 11.2))
        context.stroke(stems, with: .color(ink.stem), style: StrokeStyle(lineWidth: stemWidth ?? 1.7 * u, lineCap: .round, lineJoin: .round))
        context.drawLeaf(at: p(6.4, 8.2), angle: .degrees(-122), length: 7 * u, ink: ink, vein: rect.width > 26)
        context.drawRose(at: p(17.4, 5.6), size: 8.6 * u, seed: 5, ink: ink, open: open)
    }
}

/// The twist mark on its own.
struct TwistMark: View, Animatable {
    var size: CGFloat = DS.Size.twistMark
    var open: Double = 1

    var animatableData: Double {
        get { open }
        set { open = newValue }
    }

    var body: some View {
        let ink = GardenInk.current
        Canvas { context, canvas in
            TwistDrawing.draw(in: context, rect: CGRect(origin: .zero, size: canvas), ink: ink, open: open)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: DS.Space.xl) {
        HStack(spacing: DS.Space.l) {
            Rose(size: 44, seed: 1)
            Rose(size: 44, seed: 2)
            Bud(size: 44)
            Bud(size: 44, muted: true)
            TwistMark(size: 44)
        }
        Growing { Flourish(width: 180, progress: $0) }
        Growing { Sprig(height: 140, progress: $0) }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Colors.canvas)
}
