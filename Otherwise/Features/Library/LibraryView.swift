import SwiftUI
import SwiftData

/// Home: a deep stack of books to pick from, switchable (with the icons at
/// the top right) between the whole library, the books you've read, and the
/// stories you've twisted. Searching any book replaces the stack with results.
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShelfEntry.updatedAt, order: .reverse) private var shelf: [ShelfEntry]
    @Query(sort: \Version.createdAt, order: .reverse) private var versions: [Version]

    @State private var query = ""
    @State private var search: SearchState = .idle
    @State private var attempt = 0
    @State private var path = NavigationPath()
    /// The book being taken from the stack and opened, if any.
    @State private var pulled: PulledBook?
    @AppStorage("home.collection") private var collection: Collection = .library
    /// The book being held in the stack, whose manage sheet is open.
    @State private var managing: StackItem?
    /// More books from Open Library, loaded as you scroll the library.
    @State private var feed = LibraryFeed()

    enum Collection: String, CaseIterable, Hashable {
        case library, read, twisted

        var glyph: Glyph {
            switch self {
            case .library: .library
            case .read: .read
            case .twisted: .twisted
            }
        }

        var label: LocalizedStringKey {
            switch self {
            case .library: "Library"
            case .read: "Read"
            case .twisted: "Twisted"
            }
        }

    }

    private enum SearchState: Equatable {
        case idle, loading, results([Book]), failed
    }

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                content
                    .navigationTitle("Plot Twist")
                    .navigationBarTitleDisplayMode(.inline)
                    .searchable(text: $query, prompt: "Search any book")
                    .autocorrectionDisabled()
                    .task(id: "\(trimmedQuery)#\(attempt)") { await runSearch() }
                    .navigationDestination(for: Book.self) { BookView(book: $0) }
                    .navigationDestination(for: Version.self) { StoryView(version: $0) }
                    .toolbar {
                        // The wordmark sits at the top left, level with the icons.
                        // The centred inline title is left empty.
                        ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1) }
                        ToolbarItem(placement: .topBarLeading) { masthead }
                            .sharedBackgroundVisibility(.hidden)
                        if trimmedQuery.isEmpty {
                            ToolbarItem(placement: .topBarTrailing) {
                                GlyphSwitcher(
                                    items: Collection.allCases.map { GlyphSwitcher<Collection>.Item(id: $0, glyph: $0.glyph, label: $0.label) },
                                    selection: $collection
                                )
                            }
                            .sharedBackgroundVisibility(.hidden)
                        }
                    }
                    .sheet(item: $managing) { BookActionsSheet(book: $0.book) }
                    .dsScreen()
            }
            .tint(DS.Colors.accent)

            if let pulled {
                BookOpening(pulled: pulled) {
                    // The page fills the screen: put the book's screen beneath it, without a slide.
                    var instant = Transaction()
                    instant.disablesAnimations = true
                    withTransaction(instant) { path.append(pulled.book) }
                } onFinished: {
                    self.pulled = nil
                }
                .zIndex(1)
            }
        }
        .dsDarkOnly()
    }

    // MARK: Books

    /// Every book you can pick: the mapped classics, then any others on your shelf.
    private var libraryItems: [StackItem] {
        let progress = Dictionary(shelf.map { ($0.bookID, $0.progress) }, uniquingKeysWith: { first, _ in first })
        let classics = Catalog.entries.map { StackItem(book: $0.book, progress: progress[$0.book.id]) }
        let others = shelf
            .filter { entry in !Catalog.entries.contains { $0.book.id == entry.bookID } }
            .map { StackItem(book: $0.book, progress: $0.progress) }
        // Then the endless part, minus anything already on your shelf.
        let shown = Set((classics + others).map(\.id))
        let more = feed.books
            .filter { !shown.contains($0.id) }
            .map { StackItem(book: $0, progress: progress[$0.id]) }
        return classics + others + more
    }

    /// Books you've finished or started, most recent first.
    private var readItems: [StackItem] {
        shelf.map { StackItem(book: $0.book, progress: $0.progress) }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Content

    @ViewBuilder private var content: some View {
        if trimmedQuery.isEmpty {
            home
        } else {
            switch search {
            case .idle, .loading:
                ProgressView()
                    .tint(DS.Colors.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .results(let books) where books.isEmpty:
                MessageView(
                    symbol: "magnifyingglass",
                    title: "No books found",
                    message: "Check the spelling, or try the author’s name."
                )
            case .results(let books):
                resultList(books)
            case .failed:
                MessageView(
                    symbol: "wifi.slash",
                    title: "Can’t reach the library",
                    message: "Searching for books needs an internet connection."
                ) {
                    SecondaryButton("Try again", systemImage: "arrow.clockwise") { attempt += 1 }
                }
            }
        }
    }

    /// The wordmark at the top left, level with the icons: PLOT upright,
    /// TWIST upside down beneath it, as on the app icon.
    private var masthead: some View {
        Wordmark()
    }

    private var home: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                switch collection {
                case .library:
                    stack(libraryItems, endless: true)
                case .read:
                    if readItems.isEmpty {
                        MessageView(
                            symbol: "bookmark",
                            title: "Nothing read yet",
                            message: "Open any book in the library and say how far you’ve read. It will appear here."
                        ) {
                            SecondaryButton("Browse the library") {
                                withAnimation(DS.Motion.select) { collection = .library }
                            }
                        }
                        .transition(.opacity)
                    } else {
                        stack(readItems)
                    }
                case .twisted:
                    TwistedList { path.append($0) }
                        .transition(.opacity.combined(with: .offset(y: DS.Space.l)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(DS.Motion.standard, value: collection)
        }
        // The first page of the endless library loads right away, so the
        // stack never seems to stop at the classics.
        .task { if feed.books.isEmpty { await feed.loadMore() } }
    }

    private func stack(_ items: [StackItem], endless: Bool = false) -> some View {
        let loadMore: (() -> Void)? = endless ? { Task { await feed.loadMore() } } : nil
        return BookStack(
            items: items,
            pickedID: pulled?.book.id,
            onPick: { item, pose in
                // One book at a time, and only from the library itself.
                guard pulled == nil, path.isEmpty else { return }
                pulled = PulledBook(book: item.book, progress: item.progress, pose: pose)
            },
            onHold: { item in managing = item },
            onNearEnd: loadMore,
            isLoadingMore: feed.isLoading,
            loadFailed: feed.failed
        )
        .id(collection)
        .transition(.opacity.combined(with: .offset(y: DS.Space.l)))
    }

    private func resultList(_ books: [Book]) -> some View {
        List(books) { book in
            Button {
                path.append(book)
            } label: {
                BookRow(book: book)
            }
            .buttonStyle(PressableButtonStyle())
            .dsListRow()
        }
        .dsList()
    }

    // MARK: Search

    private func runSearch() async {
        let text = trimmedQuery
        guard !text.isEmpty else {
            search = .idle
            return
        }
        // Debounce typing; the task is cancelled when the query changes.
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        if case .results = search {} else { search = .loading }
        do {
            let books = try await OpenLibrary.search(text)
            guard !Task.isCancelled else { return }
            withAnimation(DS.Motion.standard) { search = .results(rankMapped(books)) }
        } catch {
            guard !Task.isCancelled else { return }
            search = .failed
        }
    }

    /// Books with a hand-checked story map float to the top, once each
    /// (search returns many editions of the same classic).
    private func rankMapped(_ books: [Book]) -> [Book] {
        var mapped: [Book] = []
        var rest: [Book] = []
        for book in books {
            if let entry = Catalog.entry(for: book) {
                if !mapped.contains(where: { $0.id == entry.book.id }) { mapped.append(entry.book) }
            } else {
                rest.append(book)
            }
        }
        return mapped + rest
    }
}

// MARK: - Twisted

/// Your twisted stories, newest first. Tap one to read it; hold one to read
/// or remove it. "Clear all" sits at the end.
private struct TwistedList: View {
    let onOpen: (Version) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Version.createdAt, order: .reverse) private var versions: [Version]
    /// The story being held, whose manage sheet is open.
    @State private var managing: Version?
    @State private var confirmClear = false
    @State private var holds = 0

    var body: some View {
        Group {
            if versions.isEmpty {
                MessageView(
                    symbol: "arrow.triangle.branch",
                    title: "No twisted stories yet",
                    message: "Open a book, pick a moment, and change what happens. Your versions are kept here."
                )
            } else {
                ScrollView {
                    VStack(spacing: DS.Space.s) {
                        ForEach(versions) { version in
                            VersionCard(version: version)
                                .onTapGesture { onOpen(version) }
                                .onLongPressGesture(minimumDuration: 0.45) {
                                    holds += 1
                                    managing = version
                                }
                                .accessibilityAddTraits(.isButton)
                                .accessibilityAction(named: "Manage story") { managing = version }
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        }
                        Button("Clear all", role: .destructive) { confirmClear = true }
                            .font(DS.Typography.label)
                            .foregroundStyle(DS.Colors.caution)
                            .frame(minHeight: DS.Size.touch)
                            .padding(.top, DS.Space.s)
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.vertical, DS.Space.s)
                    // Clear of the search field floating at the bottom.
                    .padding(.bottom, DS.Space.xxl * 2)
                }
                .scrollIndicators(.hidden)
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: holds)
        .sheet(item: $managing) { version in
            VersionActionsSheet(version: version) {
                managing = nil
                onOpen(version)
            } onRemove: {
                managing = nil
                remove([version])
            }
        }
        .confirmationDialog(
            "Clear all twisted stories?",
            isPresented: $confirmClear,
            titleVisibility: .visible
        ) {
            Button("Clear all", role: .destructive) { remove(versions) }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("All \(versions.count) stories will be deleted. Your books stay in your library. This can’t be undone.")
        }
    }

    /// Deletes once any sheet showing these stories has had time to close.
    private func remove(_ items: [Version]) {
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(DS.Motion.standard) {
                for item in items { modelContext.delete(item) }
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [Version.self, ShelfEntry.self], inMemory: true)
}
