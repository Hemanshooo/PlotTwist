import SwiftUI
import SwiftData

/// Inside a book: its title page, how far you've read (a vine), and the
/// story map you change it from.
///
/// Opening a book from the stack ends on this screen: the first page grows
/// to fill the screen, becomes this background, and the content arrives.
struct BookView: View {
    let book: Book

    @Environment(\.modelContext) private var modelContext
    @Query private var shelfEntries: [ShelfEntry]

    @State private var map: MapState = .loading
    @State private var sessionProgress: ReadingProgress?
    @State private var revealAll = false
    @State private var confirmReveal = false
    @State private var choice: MomentChoice?
    @State private var pendingRequest: StoryRequest?
    @State private var request: StoryRequest?
    @State private var arrived = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum MapState: Equatable {
        case loading
        case ready(StoryMap)
        case unavailable(StoryEngine.Notice)
    }

    init(book: Book) {
        // A search result for a mapped classic becomes the catalogue's copy,
        // so the shelf and the map always agree on which book this is.
        let canonical = Catalog.entry(for: book)?.book ?? book
        self.book = canonical
        let id = canonical.id
        _shelfEntries = Query(filter: #Predicate<ShelfEntry> { $0.bookID == id })
        if let curated = Catalog.entry(for: canonical)?.map {
            _map = State(initialValue: .ready(curated))
        }
    }

    private var progress: ReadingProgress? {
        if let entry = shelfEntries.first { return ReadingProgress(fraction: entry.progress) }
        return sessionProgress
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Space.xxl) {
                titlePage
                    .arriving(arrived, order: 0)
                ReadingGauge(progress: progress, onChange: save)
                    .arriving(arrived, order: 1)
                if progress != nil {
                    mapSection
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, DS.Space.screen)
            .frame(maxWidth: DS.Space.readingWidth)
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Space.l)
            .padding(.bottom, DS.Space.xxl)
        }
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $choice, onDismiss: {
            if let pendingRequest {
                request = pendingRequest
                self.pendingRequest = nil
            }
        }) { choice in
            MomentSheet(book: book, map: currentMap, moment: choice.moment) { newRequest in
                pendingRequest = newRequest
            }
        }
        .navigationDestination(item: $request) { StoryView(request: $0) }
        .confirmationDialog("Show the whole story map?", isPresented: $confirmReveal, titleVisibility: .visible) {
            Button("Show spoilers") {
                withAnimation(DS.Motion.standard) { revealAll = true }
            }
        } message: {
            Text("This reveals what happens later in the book.")
        }
        .task { await loadMap() }
        .onAppear {
            guard !arrived else { return }
            if reduceMotion { arrived = true } else { withAnimation { arrived = true } }
        }
        .animation(DS.Motion.standard, value: progress)
        .dsScreen()
    }

    // MARK: Title page

    /// The book's title page: what you see once the cover's open.
    private var titlePage: some View {
        VStack(spacing: DS.Space.m) {
            if let byline = book.byline {
                Text(byline)
                    .font(DS.Typography.meta)
                    .foregroundStyle(DS.Colors.inkSecondary)
            }
            Text(book.title)
                .dsDisplay()
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
            Growing(delay: 0.3) { Flourish(width: 136, progress: $0) }
            if let premise {
                Text(premise)
                    .font(DS.Typography.quote)
                    .foregroundStyle(DS.Colors.inkSecondary)
                    .lineSpacing(DS.Leading.relaxed)
                    .multilineTextAlignment(.center)
                    .padding(.top, DS.Space.xs)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DS.Space.xs)
        .animation(DS.Motion.reveal, value: premise)
    }

    private var premise: String? {
        if case .ready(let storyMap) = map { return storyMap.premise }
        return nil
    }

    /// The map to change from; a bare one when none could be drawn, so off-map changes still work.
    private var currentMap: StoryMap {
        if case .ready(let storyMap) = map { return storyMap }
        let blurb = [book.title, book.byline].compactMap { $0 }.joined(separator: "\n")
        return StoryMap(premise: blurb, moments: [], isCurated: false)
    }

    // MARK: Progress

    private func save(_ newProgress: ReadingProgress) {
        if let entry = shelfEntries.first {
            if case .notStarted = newProgress {
                modelContext.delete(entry)
            } else {
                entry.progress = newProgress.fraction
                entry.updatedAt = .now
            }
        } else if newProgress != .notStarted {
            modelContext.insert(ShelfEntry(book: book, progress: newProgress.fraction))
        }
        try? modelContext.save()
        sessionProgress = newProgress
        revealAll = false
    }

    // MARK: Map

    @ViewBuilder private var mapSection: some View {
        switch map {
        case .loading:
            VStack(alignment: .leading, spacing: DS.Space.s) {
                Eyebrow("Story map")
                WritingIndicator(label: "drawing the story map")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .unavailable(let notice):
            VStack(alignment: .leading, spacing: DS.Space.s) {
                InlineNotice(symbol: notice.symbol, title: notice.title, message: notice.message)
                if StoryEngine.unavailableNotice == nil {
                    SecondaryButton("Change something anyway", systemImage: "pencil.line") {
                        choice = MomentChoice(moment: nil)
                    }
                }
            }
        case .ready(let storyMap):
            StoryMapView(
                map: storyMap,
                threshold: progress?.threshold ?? 0,
                revealAll: revealAll,
                onSelect: { choice = MomentChoice(moment: $0) },
                onReveal: { confirmReveal = true },
                onFreeChange: { choice = MomentChoice(moment: nil) }
            )
        }
    }

    private func loadMap() async {
        guard case .loading = map else { return }
        if let notice = StoryEngine.unavailableNotice {
            map = .unavailable(StoryEngine.Notice(
                symbol: notice.symbol,
                title: "No story map for this book yet",
                message: "Maps for books outside the classics are drawn by Apple Intelligence. \(notice.message)"
            ))
            return
        }
        let details = try? await OpenLibrary.details(for: book)
        do {
            let generated = try await StoryEngine.storyMap(for: book, context: details?.modelContext)
            withAnimation(DS.Motion.standard) { map = .ready(generated) }
        } catch {
            guard !Task.isCancelled else { return }
            print("[PlotTwist] Map failed: \(String(reflecting: error))")
            map = .unavailable(StoryEngine.Notice(
                symbol: "map",
                title: "Couldn’t draw a map for this book",
                message: "Try one of the classics, or describe your own change."
            ))
        }
    }
}

extension View {
    /// Content arriving on a screen: it rises a little and fades in, each
    /// piece just after the one before.
    func arriving(_ arrived: Bool, order: Int) -> some View {
        self
            .opacity(arrived ? 1 : 0)
            .offset(y: arrived ? 0 : DS.Space.l)
            .animation(DS.Motion.arrive(order), value: arrived)
    }
}

#Preview {
    NavigationStack {
        BookView(book: Catalog.entries[1].book)
    }
    .modelContainer(for: [Version.self, ShelfEntry.self], inMemory: true)
    .dsColorScheme()
}
