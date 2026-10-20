import SwiftUI
import SwiftData

/// The alternate version as a book: its cover swings open when the first
/// words arrive, then you turn pages as the story is written.
struct StoryView: View {
    private enum Source {
        case request(StoryRequest)
        case saved(Version)
    }

    private let source: Source

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var model: ReaderModel
    @State private var attempt = 0
    @State private var coverAngle: Double = 0
    @State private var coverGone = false
    @State private var showBook = false

    init(request: StoryRequest) {
        source = .request(request)
        _model = State(initialValue: ReaderModel(request: request))
    }

    init(version: Version) {
        source = .saved(version)
        _model = State(initialValue: ReaderModel(version: version))
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if model.phase == .finished {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: model.shareText) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showBook) { BookView(book: model.book) }
            .task(id: attempt) { await write() }
            .onChange(of: model.hasOpening) { _, hasOpening in
                if hasOpening { openCover() }
            }
            .sensoryFeedback(.success, trigger: model.isSaved)
            .background(DS.Colors.page.ignoresSafeArea())
            .tint(model.edition.ink)
    }

    // MARK: Content

    @ViewBuilder private var content: some View {
        switch model.phase {
        case .unavailable(let notice):
            MessageView(
                symbol: notice.symbol,
                title: LocalizedStringKey(notice.title),
                message: LocalizedStringKey(notice.message)
            )
        case .failed(let notice) where !model.hasOpening:
            MessageView(
                symbol: notice.symbol,
                title: LocalizedStringKey(notice.title),
                message: LocalizedStringKey(notice.message)
            ) {
                SecondaryButton("Try again", systemImage: "arrow.clockwise") { retry() }
            }
        default:
            book
        }
    }

    private var book: some View {
        ZStack {
            PageCurlReader(pageCount: { model.pages.count }) { index in
                AnyView(
                    ReaderPageView(model: model, index: index, onChangeAnother: changeAnother, onRetry: retry)
                )
            }
            .ignoresSafeArea(edges: .bottom)
            // The saved ribbon drops from the top of the book once the story is kept.
            .overlay(alignment: .topTrailing) {
                BookmarkRibbon(color: model.edition.ink, isPlaced: model.isSaved, width: 16, length: 44)
                    .frame(height: 44, alignment: .top)
                    .clipped()
                    .padding(.trailing, DS.Space.l)
                    .allowsHitTesting(false)
            }

            if !coverGone {
                OpeningCover(angle: coverAngle, book: model.book, isWriting: model.phase == .writing)
                    .ignoresSafeArea()
                    .allowsHitTesting(coverAngle == 0)
                    .transition(.opacity)
            }
        }
    }

    // MARK: Actions

    private func openCover() {
        guard !coverGone, coverAngle == 0 else { return }
        if reduceMotion {
            withAnimation(DS.Motion.standard) { coverGone = true }
            return
        }
        withAnimation(DS.Motion.coverOpen) {
            coverAngle = 180
        } completion: {
            coverGone = true
        }
    }

    private func changeAnother() {
        switch source {
        case .request: dismiss()
        case .saved: showBook = true
        }
    }

    private func retry() {
        model.phase = .writing
        model.story = Story()
        coverAngle = 0
        coverGone = false
        attempt += 1
    }

    // MARK: Writing

    private func write() async {
        switch source {
        case .saved(let version):
            guard !model.hasOpening else { return }
            model.story = version.story
            model.phase = .finished
            try? await Task.sleep(for: .milliseconds(500))
            openCover()
            try? await Task.sleep(for: .milliseconds(900))
            model.isSaved = true

        case .request(let request):
            // Coming back to this screen must not rewrite a finished story.
            guard model.phase != .finished else { return }
            if let notice = StoryEngine.unavailableNotice {
                model.phase = .unavailable(notice)
                return
            }
            model.phase = .writing
            do {
                for try await partial in StoryEngine.write(request) {
                    model.story = partial
                }
                guard !Task.isCancelled else { return }
                if model.story.chapters.isEmpty {
                    model.phase = .failed(StoryEngine.Notice(
                        symbol: "book.closed",
                        title: "The pages came out blank",
                        message: "Apple Intelligence didn’t write this one. Try again, or pick a different change."
                    ))
                    return
                }
                if model.story.title.isEmpty {
                    // The model sometimes skips the title line; borrow the first chapter's heading.
                    let heading = model.story.chapters.first?.heading ?? ""
                    model.story.title = heading.isEmpty ? String(localized: "A Plot Twist Edition") : heading
                }
                withAnimation(DS.Motion.standard) { model.phase = .finished }
                save(request)
            } catch {
                guard !Task.isCancelled else { return }
                print("[PlotTwist] Story failed: \(String(reflecting: error))")
                // If the model ran out of room near the end, keep what it wrote.
                if model.story.chapters.count >= 3 {
                    if model.story.title.isEmpty { model.story.title = String(localized: "A Plot Twist Edition") }
                    withAnimation(DS.Motion.standard) { model.phase = .finished }
                    save(request)
                    return
                }
                withAnimation(DS.Motion.standard) {
                    model.phase = .failed(StoryEngine.notice(for: error))
                }
            }
        }
    }

    private func save(_ request: StoryRequest) {
        guard !model.isSaved else { return }
        modelContext.insert(Version(request: request, story: model.story))
        try? modelContext.save()
        model.isSaved = true
        AccessibilityNotification.Announcement("Saved to your versions").post()
    }
}

// MARK: - Opening cover

/// A full-size clothbound cover that swings open on its hinge, showing its
/// endpaper as it turns.
private struct OpeningCover: View, Animatable {
    var angle: Double
    let book: Book
    let isWriting: Bool

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    private var edition: Edition { Edition.of(book) }

    var body: some View {
        ZStack {
            if angle < 90 {
                front
            } else {
                Endpaper(book: book)
                    .scaleEffect(x: -1, y: 1)
            }
        }
        .rotation3DEffect(.degrees(-angle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.3)
        .accessibilityElement(children: .combine)
    }

    private var front: some View {
        ZStack {
            EditionPattern(edition: edition, tile: 28, intensity: 0.6)
            VStack(spacing: DS.Space.m) {
                Text(book.title.uppercased())
                    .font(DS.Typography.stamp(26))
                    .tracking(DS.Tracking.stamp * 1.5)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                Ornament(color: edition.foilColor)
                if let author = book.author {
                    Text(author.uppercased())
                        .font(DS.Typography.stamp(13))
                        .tracking(DS.Tracking.stamp)
                }
                Text("A PLOT TWIST EDITION")
                    .font(DS.Typography.stamp(9))
                    .tracking(DS.Tracking.stamp * 2)
                    .opacity(0.8)
                    .padding(.top, DS.Space.xs)
            }
            .foregroundStyle(edition.foilColor)
            .padding(.vertical, DS.Space.xl)
            .padding(.horizontal, DS.Space.l)
            .frame(maxWidth: 300)
            .background(edition.clothColor)
            .overlay(Rectangle().strokeBorder(edition.foilColor, lineWidth: 1.5).padding(4))
            .overlay(Rectangle().strokeBorder(edition.foilColor.opacity(0.5), lineWidth: 0.5))
            .padding(.horizontal, DS.Space.xl)

            CoverHinge(width: 420)

            VStack {
                Spacer()
                if isWriting {
                    WritingIndicator(label: "Writing your version", color: edition.foilColor)
                        .padding(.horizontal, DS.Space.m)
                        .padding(.vertical, DS.Space.xs)
                        .background(edition.clothColor, in: Capsule())
                }
            }
            .padding(.bottom, DS.Space.xxl + DS.Space.l)
        }
    }
}
