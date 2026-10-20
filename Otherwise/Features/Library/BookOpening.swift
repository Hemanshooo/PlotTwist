import SwiftUI

/// A book taken from the stack.
struct PulledBook: Identifiable, Equatable {
    let book: Book
    /// How far you've read it; nil if it isn't on your shelf.
    let progress: Double?
    /// Exactly how it lay in the stack.
    let pose: SlabPose
    var id: String { book.id }
}

/// Taking a book from the stack and opening it, as one continuous motion
/// driven by a single progress value:
///
/// 1. **Lift** — the book rises out of the stack toward you, stands up and
///    turns upright in your hands (its spine swinging out of sight).
/// 2. **Open** — the cover swings open on the spine.
/// 3. **Unfold** — the first page comes up to fill the screen, and becomes
///    the book's own screen.
///
/// Because every frame is computed from that one value, the book can't
/// come apart or jump between steps; and nothing waits on a timer.
struct BookOpening: View {
    let pulled: PulledBook
    /// Called once the page fills the screen: show the book's screen beneath.
    let onOpened: () -> Void
    /// Called once the opening has faded away over the book's screen.
    let onFinished: () -> Void

    @State private var progress: Double = 0
    @State private var handedOver = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            OpeningBook(
                pulled: pulled,
                progress: progress,
                screen: proxy.size,
                origin: proxy.frame(in: .global).origin
            )
        }
        .ignoresSafeArea()
        .opacity(handedOver ? 0 : 1)
        .allowsHitTesting(!handedOver)
        .onAppear(perform: open)
        .sensoryFeedback(.impact(weight: .light), trigger: progress >= OpeningBook.liftEnd)
        .accessibilityHidden(true)
    }

    private func open() {
        if reduceMotion {
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) { progress = 1 }
            onOpened()
            withAnimation(DS.Motion.standard) { handedOver = true } completion: { onFinished() }
            return
        }
        withAnimation(DS.Motion.openBook) {
            progress = 1
        } completion: {
            onOpened()
            withAnimation(DS.Motion.handOver) { handedOver = true } completion: { onFinished() }
        }
    }
}

// MARK: - The animated book

/// Draws the book at any point of the opening, from `progress` alone.
private struct OpeningBook: View, Animatable {
    let pulled: PulledBook
    var progress: Double
    let screen: CGSize
    let origin: CGPoint

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    // The phases, as fractions of the whole motion. Lift must finish before
    // the cover starts to swing: that's the moment the drawing switches from
    // the lying slab to the upright book, and both are identical then.
    static let liftEnd = 0.40
    static let openStart = 0.40
    static let openEnd = 0.78
    static let unfoldStart = 0.60

    private var book: Book { pulled.book }
    private var edition: Edition { Edition.of(book) }
    private var length: CGFloat { pulled.pose.length }
    private var depth: CGFloat { Slab.depth(for: length) }
    private var spine: CGFloat { DS.Size.slabSpine }

    /// The size of the upright cover in your hands.
    private var heroScale: CGFloat {
        let fitHeight = min(DS.Size.coverHero.height * 1.08, screen.height * 0.5)
        return fitHeight / length
    }

    var body: some View {
        let lift = Ease.outCubic(phase(0, Self.liftEnd))
        let open = Ease.inOutSine(phase(Self.openStart, Self.openEnd))
        let unfold = Ease.inOutCubic(phase(Self.unfoldStart, 1))

        ZStack(alignment: .topLeading) {
            // The room fills with the book's light as it comes toward you.
            AmbientBackground(tint: edition.glow, strength: lift)
                .opacity(min(1, lift * 1.15))

            if progress < Self.liftEnd {
                lifting(lift)
            } else {
                opening(open: open, unfold: unfold)
            }
        }
        .frame(width: screen.width, height: screen.height)
    }

    private func phase(_ start: Double, _ end: Double) -> Double {
        min(max((progress - start) / (end - start), 0), 1)
    }

    // MARK: Lift

    /// The slab, rising, standing up and turning upright, pivoting on its hinge.
    private func lifting(_ t: Double) -> some View {
        let source = CGPoint(x: pulled.pose.hinge.x - origin.x, y: pulled.pose.hinge.y - origin.y)
        let scale = 1 + (heroScale - 1) * t
        // Where the hinge ends up: just left of centre, so the upright cover is centred.
        let target = CGPoint(x: screen.width / 2 - depth * heroScale / 2, y: screen.height * 0.47)
        // A gentle arc up and toward you.
        let arc = -DS.Space.xl * sin(.pi * t)
        let hinge = CGPoint(
            x: source.x + (target.x - source.x) * t,
            y: source.y + (target.y - source.y) * t + arc
        )
        let anchor = UnitPoint(x: 0.5, y: depth / (depth + spine))

        return SlabBook(
            book: book,
            length: length,
            progress: pulled.progress,
            coverAngle: pulled.pose.coverAngle * (1 - t),
            fog: pulled.pose.fog * (1 - t)
        )
        .frame(width: length, height: depth + spine)
        .scaleEffect(scale, anchor: anchor)
        .rotationEffect(.degrees(90 * t), anchor: anchor)
        .shadow(color: .black.opacity(0.55 * t), radius: 30 * t, x: 0, y: 24 * t)
        .position(x: hinge.x, y: hinge.y + (spine - depth) / 2)
    }

    // MARK: Open and unfold

    private func opening(open: Double, unfold: Double) -> some View {
        // The upright cover, exactly where the lift left it.
        let cover = CGSize(width: depth * heroScale, height: length * heroScale)
        let start = CGRect(
            x: screen.width / 2 - cover.width / 2,
            y: screen.height * 0.47 - cover.height / 2,
            width: cover.width,
            height: cover.height
        )
        // As the cover opens, the book slides right so the spread is centred.
        let spread = start.offsetBy(dx: cover.width / 2 * open, dy: 0)
        let full = CGRect(origin: .zero, size: screen)
        let page = CGRect(
            x: spread.minX + (full.minX - spread.minX) * unfold,
            y: spread.minY + (full.minY - spread.minY) * unfold,
            width: spread.width + (full.width - spread.width) * unfold,
            height: spread.height + (full.height - spread.height) * unfold
        )

        return ZStack {
            FirstPage(book: book, unfold: unfold, cover: open)
            CoverLeaf(book: book, size: page.size, angle: 180 * open)
                .opacity(1 - Ease.inCubic(unfold))
        }
        .frame(width: page.width, height: page.height)
        .shadow(color: .black.opacity(0.55 * (1 - unfold)), radius: 30, x: 0, y: 24)
        .position(x: page.midX, y: page.midY)
    }
}

// MARK: - Cover and page

/// The front cover, turning on the spine. Past halfway you see its inside: the endpaper.
private struct CoverLeaf: View {
    let book: Book
    let size: CGSize
    let angle: Double

    var body: some View {
        let hero = DS.Size.coverHero
        ZStack {
            if angle < 90 {
                // The hero cover, scaled (uniformly, both are 2:3) to the page's size.
                BookCover(book: book, size: .hero)
                    .scaleEffect(size.height / hero.height)
                    .frame(width: size.width, height: size.height)
            } else {
                Endpaper(book: book)
                    .frame(width: size.width, height: size.height)
                    .scaleEffect(x: -1, y: 1)
            }
        }
        // It catches less light as it stands up off the page.
        .overlay { Color.black.opacity(0.2 * sin(angle * .pi / 180)).allowsHitTesting(false) }
        .rotation3DEffect(.degrees(-angle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: DS.Depth.cover)
        .allowsHitTesting(false)
    }
}

/// The first page: a half-title on dark paper. As it comes up to fill the
/// screen it becomes the black room lit by the book, the background of the
/// book's own screen.
private struct FirstPage: View {
    let book: Book
    let unfold: Double
    let cover: Double

    private var edition: Edition { Edition.of(book) }

    var body: some View {
        ZStack {
            DS.Colors.page
            AmbientBackground(tint: edition.glow)
                .opacity(unfold)
            VStack(spacing: DS.Space.xs) {
                Text(book.title)
                    .font(DS.Typography.stampDisplay(19))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.6)
                Ornament(color: edition.ink, compact: true)
                if let author = book.author {
                    Text(author)
                        .font(DS.Typography.stampItalic(11))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .foregroundStyle(edition.ink)
            .padding(DS.Space.l)
            .opacity(max(0, 1 - unfold * 3))
            // The gutter, where the page curves into the spine.
            HStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: DS.Space.l)
                Spacer(minLength: 0)
            }
            .opacity(1 - unfold)
            // In the cover's shadow until it lifts away.
            Color.black.opacity(0.35 * max(0, 1 - cover * 1.6))
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.cover * (1 - unfold), style: .continuous))
        .allowsHitTesting(false)
    }
}

// MARK: - Easing

enum Ease {
    static func outCubic(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
    static func inCubic(_ x: Double) -> Double { x * x * x }
    static func inOutCubic(_ x: Double) -> Double {
        x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
    }
    static func inOutSine(_ x: Double) -> Double { -(cos(.pi * x) - 1) / 2 }
}
