import SwiftUI
import SwiftData

/// A book's page: its title page, then your copy (shelf, progress, rating,
/// heart, and logging a read), your diary entries and quotes from it, its
/// "What if" map, and a little about it.
///
/// Opening a book from a stack ends on this screen: the first page grows to
/// fill the screen, becomes this background, and the content arrives.
struct BookView: View {
    let book: Book

    @Environment(\.modelContext) private var modelContext
    @Query private var shelfEntries: [ShelfEntry]
    @Query private var diary: [DiaryEntry]
    @Query private var quotes: [Quote]

    @State private var map: MapState = .loading
    @State private var details: OpenLibrary.Details?
    @State private var revealAll = false
    @State private var confirmReveal = false
    @State private var choice: MomentChoice?
    @State private var pendingRequest: StoryRequest?
    @State private var request: StoryRequest?
    @State private var logging = false
    @State private var keepingQuote = false
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
        _diary = Query(filter: #Predicate<DiaryEntry> { $0.bookID == id }, sort: \DiaryEntry.readOn, order: .reverse)
        _quotes = Query(filter: #Predicate<Quote> { $0.bookID == id }, sort: \Quote.createdAt, order: .reverse)
        if let curated = Catalog.entry(for: canonical)?.map {
            _map = State(initialValue: .ready(curated))
        }
    }

    private var entry: ShelfEntry? { shelfEntries.first }

    /// How much of the map to show.
    private var progress: ReadingProgress { entry?.reading ?? .notStarted }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Space.xxl) {
                titlePage
                    .arriving(arrived, order: 0)
                ShelfCard(book: book, entry: entry, diary: diary) { logging = true }
                    .arriving(arrived, order: 1)
                if !diary.isEmpty {
                    diarySection
                        .transition(.opacity)
                }
                quotesSection
                    .arriving(arrived, order: 2)
                mapSection
                    .arriving(arrived, order: 3)
                if let about = details?.summary, !about.isEmpty {
                    aboutSection(about)
                        .transition(.opacity)
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
        .sheet(isPresented: $logging) {
            LogSheet(book: book, rating: entry?.rating ?? 0, liked: entry?.liked ?? false)
        }
        .sheet(isPresented: $keepingQuote) {
            QuoteEditor(book: book)
        }
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
        .task { await load() }
        .onAppear {
            guard !arrived else { return }
            if reduceMotion { arrived = true } else { withAnimation { arrived = true } }
        }
        .onChange(of: progress) { _, _ in revealAll = false }
        .animation(DS.Motion.standard, value: diary.count)
        .animation(DS.Motion.standard, value: details?.summary)
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

    /// The catalogue's spoiler-free premise, or the first sentences of Open Library's description.
    private var premise: String? {
        if case .ready(let storyMap) = map, storyMap.isCurated { return storyMap.premise }
        return nil
    }

    // MARK: Diary

    private var diarySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("Your diary", hint: diary.count == 1 ? String(localized: "1 reading") : String(localized: "\(diary.count) readings"))
            ForEach(diary) { item in
                NavigationLink(value: item) {
                    BookDiaryRow(entry: item)
                }
                .buttonStyle(PressableButtonStyle())
                Hairline()
            }
        }
    }

    // MARK: Quotes

    private var quotesSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionHeader("Quotes", hint: quotes.isEmpty ? String(localized: "none kept yet") : "\(quotes.count)")
            ForEach(quotes) { quote in
                NavigationLink(value: quote) {
                    QuoteSnippet(quote: quote)
                }
                .buttonStyle(PressableButtonStyle())
            }
            DashedButton("Keep a line from this book", systemImage: "plus") { keepingQuote = true }
        }
    }

    // MARK: What if

    @ViewBuilder private var mapSection: some View {
        switch map {
        case .loading:
            VStack(alignment: .leading, spacing: DS.Space.s) {
                SectionHeader("What if")
                WritingIndicator(label: "drawing the story map")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .unavailable(let notice):
            VStack(alignment: .leading, spacing: DS.Space.s) {
                SectionHeader("What if")
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
                threshold: progress.threshold,
                revealAll: revealAll,
                onSelect: { choice = MomentChoice(moment: $0) },
                onReveal: { confirmReveal = true },
                onFreeChange: { choice = MomentChoice(moment: nil) }
            )
        }
    }

    /// The map to change from; a bare one when none could be drawn, so off-map changes still work.
    private var currentMap: StoryMap {
        if case .ready(let storyMap) = map { return storyMap }
        let blurb = [book.title, book.byline].compactMap { $0 }.joined(separator: "\n")
        return StoryMap(premise: blurb, moments: [], isCurated: false)
    }

    // MARK: About

    private func aboutSection(_ about: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionHeader("About the book", hint: "open library")
            Text(about)
                .font(DS.Typography.blurb)
                .foregroundStyle(DS.Colors.inkSecondary)
                .lineSpacing(DS.Leading.relaxed)
                .lineLimit(12)
                .fixedSize(horizontal: false, vertical: true)
            if let subjects = details?.subjects, !subjects.isEmpty {
                Text(subjects.prefix(5).joined(separator: " · ").lowercased())
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.inkTertiary)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Loading

    private func load() async {
        if details == nil, !book.id.hasPrefix("catalog/") {
            details = try? await OpenLibrary.details(for: book)
        }
        await loadMap()
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
        do {
            let generated = try await StoryEngine.storyMap(for: book, context: details?.modelContext)
            withAnimation(DS.Motion.standard) { map = .ready(generated) }
        } catch {
            guard !Task.isCancelled else { return }
            print("[Endpaper] Map failed: \(String(reflecting: error))")
            map = .unavailable(StoryEngine.Notice(
                symbol: "map",
                title: "Couldn’t draw a map for this book",
                message: "Try one of the classics, or describe your own change."
            ))
        }
    }
}

// MARK: - Rows

/// One reading of this book: the date, the roses, the heart, a line of the review.
private struct BookDiaryRow: View {
    let entry: DiaryEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Space.m) {
            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                HStack(spacing: DS.Space.xs) {
                    Text(entry.readOn.formatted(.dateTime.day().month(.wide).year()))
                        .font(DS.Typography.label)
                        .foregroundStyle(DS.Colors.ink)
                    if entry.isReread {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DS.Colors.inkTertiary)
                            .accessibilityLabel("Reread")
                    }
                }
                if entry.hasReview {
                    Text(entry.hasSpoilers ? String(localized: "Review hidden: contains spoilers") : entry.review)
                        .font(entry.hasSpoilers ? DS.Typography.caption : DS.Typography.quoteSmall)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if entry.rating > 0 { RoseRating(value: entry.rating) }
            if entry.liked { HeartMark() }
        }
        .padding(.vertical, DS.Space.s)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A button drawn as a dashed outline: an invitation to add something.
struct DashedButton: View {
    let title: LocalizedStringKey
    var systemImage: String = "plus"
    let action: () -> Void

    init(_ title: LocalizedStringKey, systemImage: String = "plus", action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Space.s) {
                Text(title)
                    .font(DS.Typography.label)
                    .foregroundStyle(DS.Colors.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DS.Colors.ink)
            }
            .padding(DS.Space.m)
            .frame(minHeight: DS.Size.touch)
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.s, style: .continuous)
                    .strokeBorder(DS.Colors.inkTertiary, style: StrokeStyle(lineWidth: DS.Size.hairline, dash: [4, 4]))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
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
            .endpaperDestinations()
    }
    .modelContainer(Store.preview())
    .dsColorScheme()
}
