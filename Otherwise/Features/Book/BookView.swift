import SwiftUI
import SwiftData

/// One book: its cover on a band of its own cloth, how far you've read,
/// and the story map you change it from.
struct BookView: View {
    let book: Book
    private let edition: Edition

    @Environment(\.modelContext) private var modelContext
    @Query private var shelfEntries: [ShelfEntry]

    @State private var map: MapState = .loading
    @State private var sessionProgress: ReadingProgress?
    @State private var editingProgress = false
    @State private var revealAll = false
    @State private var confirmReveal = false
    @State private var choice: MomentChoice?
    @State private var pendingRequest: StoryRequest?
    @State private var request: StoryRequest?

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
        self.edition = Edition.of(canonical)
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
            VStack(spacing: DS.Space.xl) {
                header
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    progressSection
                    if progress != nil, !editingProgress {
                        mapSection
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, DS.Space.screen)
                .frame(maxWidth: DS.Space.readingWidth)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, DS.Space.xxl)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $choice, onDismiss: {
            if let pendingRequest {
                request = pendingRequest
                self.pendingRequest = nil
            }
        }) { choice in
            MomentSheet(book: book, edition: edition, map: currentMap, moment: choice.moment) { newRequest in
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
        .animation(DS.Motion.standard, value: editingProgress)
        .animation(DS.Motion.standard, value: progress)
        .dsScreen()
        .tint(edition.ink)
    }

    // MARK: Header

    /// The cover stands on a band of its own patterned cloth, which fades into the page.
    private var header: some View {
        VStack(spacing: DS.Space.l) {
            FlippableCover(book: book, blurb: blurb)
                .padding(.top, DS.Space.s)
            VStack(spacing: DS.Space.xxs) {
                Text(book.title)
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Colors.ink)
                if let byline = book.byline {
                    Text(byline)
                        .font(DS.Typography.meta)
                        .foregroundStyle(DS.Colors.inkSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, DS.Space.screen)
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            // Larger tiles and a softer stamp than the cover, so the book stands out from its band.
            EditionPattern(edition: edition, tile: 34, intensity: 0.28)
                .frame(height: DS.Size.coverLarge.height + 260)
                .mask(
                    LinearGradient(
                        stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.55), .init(color: .clear, location: 1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: -200)
                .accessibilityHidden(true)
        }
    }

    /// The map to change from; a bare one when none could be drawn, so off-map changes still work.
    private var currentMap: StoryMap {
        if case .ready(let storyMap) = map { return storyMap }
        return StoryMap(premise: blurb, moments: [], isCurated: false)
    }

    private var blurb: String {
        if case .ready(let storyMap) = map { return storyMap.premise }
        return [book.title, book.byline].compactMap { $0 }.joined(separator: "\n")
    }

    // MARK: Progress

    @ViewBuilder private var progressSection: some View {
        if progress == nil || editingProgress {
            ReadingProgressCard(edition: edition, initial: progress) { newProgress in
                save(newProgress)
                editingProgress = false
            }
            .transition(.opacity)
        } else if let progress {
            ReadingProgressChip(edition: edition, progress: progress) {
                editingProgress = true
            }
            .frame(maxWidth: .infinity)
        }
    }

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
                Eyebrow("Story map", color: edition.ink)
                WritingIndicator(label: "Drawing the story map")
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
                edition: edition,
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

#Preview {
    NavigationStack {
        BookView(book: Catalog.entries[1].book)
    }
    .modelContainer(for: [Version.self, ShelfEntry.self], inMemory: true)
}
