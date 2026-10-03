import SwiftUI

/// A book picked from the stack.
struct PulledBook: Identifiable, Equatable {
    let book: Book
    /// How far you've read it; nil if it isn't on your shelf.
    let progress: Double?
    /// Its cover's frame in the stack, in global coordinates (untilted).
    let source: CGRect
    /// How far it lay back there, in degrees about its top edge.
    var sourceTilt: Double = 0
    var id: String { book.id }
}

/// Taking a book out and opening it, in three movements:
/// 1. it slides up out of the stack and stands up in your hands,
/// 2. you set it down and its cover swings open on the spine,
/// 3. its first page comes up to fill the screen: title, blurb, your
///    bookmark, and "Open the book".
/// Closing it plays the same movements in reverse, back into its place.
struct BookPullOut: View {
    let pulled: PulledBook
    let onOpen: () -> Void
    let onPutBack: () -> Void

    private enum Stage { case inStack, slidOut, inHand, spread, open }

    @State private var stage: Stage = .inStack
    /// Lying back (negative) … upright (0).
    @State private var tilt: Double
    /// 0 = closed … 180 = the cover lying open to the left of the page.
    @State private var cover: Double = 0
    /// 0 = a book-sized first page … 1 = the page fills the screen.
    @State private var unfold: Double = 0
    @State private var drag: CGFloat = 0
    @State private var blurb: String?
    @State private var isClosing = false
    @State private var visible: Double = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(pulled: PulledBook, onOpen: @escaping () -> Void, onPutBack: @escaping () -> Void) {
        self.pulled = pulled
        self.onOpen = onOpen
        self.onPutBack = onPutBack
        _tilt = State(initialValue: pulled.sourceTilt)
    }

    var body: some View {
        // The outer reader respects the safe area, so it can report the insets
        // (used only for padding). The inner one fills the whole screen.
        GeometryReader { outer in
            let insets = outer.safeAreaInsets
            GeometryReader { proxy in
                let screen = proxy.size
                let origin = proxy.frame(in: .global).origin
                let rect = frame(for: stage, screen: screen, origin: origin)
                let pull = min(drag / 420, 1)

                ZStack {
                    // The room dims as the book comes out.
                    DS.Colors.canvas
                        .opacity(dim * (1 - pull * 0.7))

                    OpeningBook(
                        book: pulled.book,
                        size: rect.size,
                        cover: cover,
                        unfold: unfold,
                        blurb: blurb,
                        progress: pulled.progress,
                        insets: insets,
                        screen: screen,
                        onOpen: onOpen,
                        onClose: putBack
                    )
                    // Same hinge and lens as the stack, so the first frame matches exactly.
                    .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: DS.Depth.stack)
                    .scaleEffect(1 - pull * 0.22)
                    .position(x: rect.midX, y: rect.midY + drag)
                    .gesture(dismissDrag)
                }
            }
            .ignoresSafeArea()
        }
        .opacity(visible)
        .task { await takeOut() }
        .task { await loadBlurb() }
        .sensoryFeedback(.impact(weight: .light), trigger: cover > 90)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { putBack() }
    }

    private var dim: Double {
        switch stage {
        case .inStack: 0
        case .slidOut: 0.5
        case .inHand, .spread, .open: 0.96
        }
    }

    // MARK: Geometry

    /// The first page's frame at each stage, in full-screen space. The cover
    /// is hinged to its leading edge.
    private func frame(for stage: Stage, screen size: CGSize, origin: CGPoint) -> CGRect {
        let hero = DS.Size.coverHero
        let lift = -DS.Space.l
        switch stage {
        case .inStack:
            return pulled.source.offsetBy(dx: -origin.x, dy: -origin.y)
        case .slidOut:
            // Drawn up and out of the stack, like a record from a crate.
            return pulled.source.offsetBy(dx: -origin.x, dy: -origin.y - pulled.source.height * 0.32)
        case .inHand:
            return CGRect(
                x: (size.width - hero.width) / 2,
                y: (size.height - hero.height) / 2 + lift,
                width: hero.width,
                height: hero.height
            )
        case .spread:
            // Set down a little further away, with the spine at the centre so
            // the open spread fits the screen.
            let page = CGSize(width: hero.width * DS.Size.spreadScale, height: hero.height * DS.Size.spreadScale)
            return CGRect(
                x: size.width / 2,
                y: (size.height - page.height) / 2 + lift,
                width: page.width,
                height: page.height
            )
        case .open:
            return CGRect(origin: .zero, size: size)
        }
    }

    // MARK: Choreography

    private func takeOut() async {
        if reduceMotion {
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) {
                stage = .open
                tilt = 0
                cover = 180
                unfold = 1
                visible = 0
            }
            withAnimation(DS.Motion.standard) { visible = 1 }
            return
        }
        // One frame with the book exactly where it was, so the move starts from there.
        try? await Task.sleep(for: .milliseconds(20))
        withAnimation(DS.Motion.slide) {
            stage = .slidOut
            tilt = pulled.sourceTilt * 0.7
        }
        try? await Task.sleep(for: .milliseconds(220))
        withAnimation(DS.Motion.pullOut) {
            stage = .inHand
            tilt = 0
        }
        try? await Task.sleep(for: .milliseconds(520))
        withAnimation(DS.Motion.coverOpen) {
            stage = .spread
            cover = 180
        }
        try? await Task.sleep(for: .milliseconds(700))
        withAnimation(DS.Motion.unfold) {
            stage = .open
            unfold = 1
        }
    }

    private func putBack() {
        guard !isClosing else { return }
        isClosing = true
        if reduceMotion {
            withAnimation(DS.Motion.standard) { visible = 0 } completion: { onPutBack() }
            return
        }
        Task {
            withAnimation(DS.Motion.unfold) {
                stage = .spread
                unfold = 0
                drag = 0
            }
            try? await Task.sleep(for: .milliseconds(320))
            withAnimation(DS.Motion.coverClose) {
                stage = .inHand
                cover = 0
            }
            try? await Task.sleep(for: .milliseconds(560))
            withAnimation(DS.Motion.pullOut) {
                stage = .slidOut
                tilt = pulled.sourceTilt * 0.7
            }
            try? await Task.sleep(for: .milliseconds(340))
            withAnimation(DS.Motion.slide) {
                stage = .inStack
                tilt = pulled.sourceTilt
            } completion: {
                onPutBack()
            }
        }
    }

    /// Pull the page down to close the book and put it back.
    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard stage == .open, !isClosing else { return }
                drag = max(0, value.translation.height)
            }
            .onEnded { value in
                guard stage == .open, !isClosing else { return }
                if value.translation.height > 140 || value.predictedEndTranslation.height > 420 {
                    putBack()
                } else {
                    withAnimation(DS.Motion.standard) { drag = 0 }
                }
            }
    }

    private func loadBlurb() async {
        if let premise = Catalog.entry(for: pulled.book)?.map.premise {
            blurb = premise
            return
        }
        let summary = try? await OpenLibrary.details(for: pulled.book).summary
        let text = summary.map { $0.count > 280 ? String($0.prefix(277)) + "…" : $0 }
        withAnimation(DS.Motion.reveal) {
            blurb = text ?? String(localized: "Change one moment in this book, and read how the story would have gone.")
        }
    }
}

// MARK: - The book

/// The first page with the cover hinged to its leading edge. The cover's
/// swing and the page's growth are animated together, so every in-between
/// frame is a real book.
private struct OpeningBook: View, Animatable {
    let book: Book
    /// The page's size. Animated here, with the cover's swing, so the cover
    /// and page are always drawn at exactly the same size.
    var size: CGSize
    var cover: Double
    var unfold: Double
    let blurb: String?
    let progress: Double?
    let insets: EdgeInsets
    let screen: CGSize
    let onOpen: () -> Void
    let onClose: () -> Void

    var animatableData: AnimatablePair<CGSize.AnimatableData, AnimatablePair<Double, Double>> {
        get { AnimatablePair(size.animatableData, AnimatablePair(cover, unfold)) }
        set {
            size.animatableData = newValue.first
            cover = newValue.second.first
            unfold = newValue.second.second
        }
    }

    var body: some View {
        ZStack {
            FirstPage(
                book: book,
                cover: cover,
                unfold: unfold,
                blurb: blurb,
                progress: progress,
                insets: insets,
                screen: screen,
                onOpen: onOpen,
                onClose: onClose
            )
            CoverLeaf(book: book, size: size, angle: cover)
        }
        .frame(width: size.width, height: size.height)
        // Held up in the light; the shadow fades as the page becomes the screen.
        .shadow(color: .black.opacity(0.3 * (1 - unfold)), radius: 26, x: 0, y: 20)
    }
}

/// The front cover, turning on the spine. Past halfway you see its inside: the endpaper.
private struct CoverLeaf: View {
    let book: Book
    let size: CGSize
    let angle: Double

    var body: some View {
        let hero = DS.Size.coverHero
        ZStack {
            if angle < 90 {
                // The hero cover, scaled to exactly the page's size.
                BookCover(book: book, size: .hero)
                    .scaleEffect(x: size.width / hero.width, y: size.height / hero.height)
                    .frame(width: size.width, height: size.height)
            } else {
                Endpaper(book: book)
                    .frame(width: size.width, height: size.height)
                    .scaleEffect(x: -1, y: 1)
            }
        }
        // It catches less light as it stands up off the page.
        .overlay { Color.black.opacity(0.16 * sin(angle * .pi / 180)) }
        .rotation3DEffect(.degrees(-angle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.35)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The book's first page. While it's book-sized it's a half-title; as it
/// comes up to fill the screen, the full title page (laid out for the
/// screen, so nothing reflows) shows through it.
private struct FirstPage: View {
    let book: Book
    let cover: Double
    let unfold: Double
    let blurb: String?
    let progress: Double?
    let insets: EdgeInsets
    let screen: CGSize
    let onOpen: () -> Void
    let onClose: () -> Void

    private var edition: Edition { Edition.of(book) }
    private var isOpen: Bool { unfold > 0.98 }

    var body: some View {
        DS.Colors.surface
            .overlay { halfTitle.opacity(max(0, 1 - unfold * 2.5)) }
            .overlay {
                titlePage
                    .frame(width: screen.width, height: screen.height)
                    .opacity(max(0, unfold * 1.8 - 0.8))
                    .allowsHitTesting(isOpen)
            }
            // The page block's edges, and the gutter where the page meets the spine.
            .overlay(alignment: .trailing) { pageEdges.opacity(1 - unfold) }
            .overlay(alignment: .leading) {
                LinearGradient(colors: [.black.opacity(0.14), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: DS.Space.l)
                    .opacity(1 - unfold)
                    .allowsHitTesting(false)
            }
            // In the cover's shadow until it lifts away.
            .overlay {
                Color.black
                    .opacity(0.2 * max(0, 1 - cover / 110))
                    .allowsHitTesting(false)
            }
            .clipShape(Rectangle())
    }

    /// The page as you first see it inside the cover.
    private var halfTitle: some View {
        VStack(spacing: DS.Space.xs) {
            Text(book.title)
                .font(DS.Typography.stampDisplay(18))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.6)
            Ornament(color: edition.ink, compact: true)
            if let author = book.author {
                Text(author)
                    .font(DS.Typography.stampItalic(10))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .foregroundStyle(edition.ink)
        .padding(DS.Space.l)
        .accessibilityHidden(true)
    }

    private var pageEdges: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<3, id: \.self) { _ in
                Rectangle().fill(DS.Colors.hairline).frame(width: DS.Size.hairline)
            }
        }
        .padding(.vertical, DS.Space.xxs)
        .padding(.trailing, 2)
        .allowsHitTesting(false)
    }

    /// The whole title page, laid out for the screen.
    private var titlePage: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(DS.Typography.emphasis)
                        .frame(width: DS.Size.touch, height: DS.Size.touch)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .foregroundStyle(DS.Colors.ink)
                .accessibilityLabel("Close the book")
                Spacer()
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.top, insets.top + DS.Space.xs)

            Spacer(minLength: DS.Space.l)

            VStack(spacing: DS.Space.m) {
                Text(book.title)
                    .font(DS.Typography.display)
                    .foregroundStyle(edition.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                Ornament(color: edition.ink)
                if let byline = book.byline {
                    Text(byline)
                        .font(DS.Typography.meta)
                        .foregroundStyle(DS.Colors.inkSecondary)
                }
                Text(blurb ?? String(repeating: "A story you can change ", count: 4))
                    .font(DS.Typography.quote)
                    .foregroundStyle(DS.Colors.ink)
                    .lineSpacing(DS.Leading.relaxed)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .redacted(reason: blurb == nil ? .placeholder : [])
                    .padding(.top, DS.Space.s)
                if let progress {
                    Label(progressLabel(progress), systemImage: progress >= 0.999 ? "checkmark.seal.fill" : "bookmark.fill")
                        .font(DS.Typography.metaEmphasis)
                        .foregroundStyle(edition.ink)
                        .padding(.top, DS.Space.xs)
                }
            }
            .padding(.horizontal, DS.Space.xl)
            .frame(maxWidth: DS.Space.readingWidth)
            .accessibilityElement(children: .combine)

            Spacer(minLength: DS.Space.l)

            VStack(spacing: DS.Space.s) {
                PrimaryButton("Open the book", systemImage: "book", edition: edition, action: onOpen)
                Text("Swipe down to close it")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.inkTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.bottom, insets.bottom + DS.Space.m)
        }
        // Your bookmark, still in the book, drops into place once it's open.
        .overlay(alignment: .topTrailing) {
            if let progress, progress < 0.999 {
                BookmarkRibbon(color: edition.ink, isPlaced: isOpen, width: 16, length: insets.top + 56)
                    .padding(.trailing, DS.Space.xl)
                    .accessibilityHidden(true)
            }
        }
    }

    private func progressLabel(_ progress: Double) -> LocalizedStringKey {
        if progress >= 0.999 { return "You’ve finished this book" }
        return "Your bookmark: about \(Int((progress * 10).rounded()) * 10)% through"
    }
}
