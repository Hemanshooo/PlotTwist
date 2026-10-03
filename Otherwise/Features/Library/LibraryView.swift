import SwiftUI
import SwiftData

/// Home: a deep stack of books to pick from, switchable between the whole
/// library and the books you've read. Your twisted books sit behind
/// "Twisted"; searching any book replaces the stack with results.
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShelfEntry.updatedAt, order: .reverse) private var shelf: [ShelfEntry]
    @Query(sort: \Version.createdAt, order: .reverse) private var versions: [Version]

    @State private var query = ""
    @State private var search: SearchState = .idle
    @State private var attempt = 0
    @State private var path = NavigationPath()
    /// The book currently picked up from the stack, if any.
    @State private var pulled: PulledBook?
    @AppStorage("home.collection") private var collection: Collection = .library
    @State private var showVersions = false
    @State private var pendingVersion: Version?
    /// The book being held in the stack, whose manage sheet is open.
    @State private var managing: StackItem?
    /// More books from Open Library, loaded as you scroll the library.
    @State private var feed = LibraryFeed()

    enum Collection: String, CaseIterable {
        case library, read

        var title: LocalizedStringKey {
            switch self {
            case .library: "Library"
            case .read: "Read"
            }
        }

        /// One line of guidance under the app's name.
        var guidance: LocalizedStringKey {
            switch self {
            case .library: "Pick a book to change its story."
            case .read: "Pick a book you’ve read to change its story."
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
                        // The name sits small at the top left, level with the options;
                        // the centred inline title is left empty.
                        ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1) }
                        ToolbarItem(placement: .topBarLeading) {
                            Text("Plot Twist")
                                .font(DS.Typography.masthead)
                                .tracking(DS.Tracking.masthead)
                                .textCase(.uppercase)
                                .foregroundStyle(DS.Colors.ink)
                                .fixedSize()
                                .accessibilityAddTraits(.isHeader)
                        }
                        .sharedBackgroundVisibility(.hidden)
                        if trimmedQuery.isEmpty || !versions.isEmpty {
                            ToolbarItem(placement: .topBarTrailing) { navOptions }
                                // Set straight on the paper, like a running head: no pill.
                                .sharedBackgroundVisibility(.hidden)
                        }
                    }
                    .sheet(item: $managing) { BookActionsSheet(book: $0.book) }
                    .sheet(isPresented: $showVersions, onDismiss: {
                        if let pendingVersion {
                            path.append(pendingVersion)
                            self.pendingVersion = nil
                        }
                    }) {
                        VersionsSheet { pendingVersion = $0 }
                    }
                    .dsScreen()
            }
            .tint(DS.Colors.accent)

            if let pulled {
                BookPullOut(
                    pulled: pulled,
                    onOpen: { open(pulled.book) },
                    onPutBack: putBack
                )
                .transition(.asymmetric(insertion: .identity, removal: .opacity))
                .zIndex(1)
            }
        }
    }

    // MARK: Picking books

    private func open(_ book: Book) {
        path.append(book)
        withAnimation(DS.Motion.standard) { pulled = nil }
    }

    /// The book is back in its place: the others fade back in around it.
    private func putBack() {
        withAnimation(DS.Motion.standard) { pulled = nil }
    }

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

    private var home: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The masthead's second line, under the name: small tracked
            // capitals, then a hairline rule across the page.
            VStack(alignment: .leading, spacing: DS.Space.s) {
                Text(collection.guidance)
                    .font(DS.Typography.subtitle)
                    .tracking(DS.Tracking.eyebrow)
                    .textCase(.uppercase)
                    .foregroundStyle(DS.Colors.inkSecondary)
                    .contentTransition(.opacity)
                Rectangle()
                    .fill(DS.Colors.hairline)
                    .frame(height: DS.Size.hairline)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.bottom, DS.Space.m)

            ZStack {
                switch collection {
                case .library:
                    stack(libraryItems, endless: true)
                case .read:
                    if readItems.isEmpty {
                        MessageView(
                            symbol: "books.vertical",
                            title: "Nothing read yet",
                            message: "Open any book in the library and say how far you’ve read. It will appear here."
                        ) {
                            SecondaryButton("Browse the library", systemImage: "books.vertical") {
                                withAnimation(DS.Motion.standard) { collection = .library }
                            }
                        }
                    } else {
                        stack(readItems)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sensoryFeedback(.selection, trigger: collection)
        // The first page of the endless library loads right away, so the
        // stack never seems to stop at the classics.
        .task { if feed.books.isEmpty { await feed.loadMore() } }
    }

    /// LIBRARY  READ  TWISTED, in small tracked capitals at the top right.
    /// The collection you're in is set in the accent; the rest in grey.
    private var navOptions: some View {
        HStack(spacing: DS.Space.m) {
            if trimmedQuery.isEmpty {
                ForEach(Collection.allCases, id: \.self) { item in
                    let isSelected = collection == item
                    navOption(item.title, color: isSelected ? DS.Colors.accent : DS.Colors.inkSecondary) {
                        withAnimation(DS.Motion.standard) { collection = item }
                    }
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            if !versions.isEmpty {
                navOption("Twisted", color: DS.Colors.inkSecondary) { showVersions = true }
                    .accessibilityLabel("Your twisted books")
            }
        }
    }

    private func navOption(_ title: LocalizedStringKey, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DS.Typography.eyebrow)
                .tracking(DS.Tracking.eyebrow)
                .textCase(.uppercase)
                .foregroundStyle(color)
                .frame(minHeight: DS.Size.touch)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func stack(_ items: [StackItem], endless: Bool = false) -> some View {
        let loadMore: (() -> Void)? = endless ? { Task { await feed.loadMore() } } : nil
        return BookStack(
            items: items,
            pickedID: pulled?.book.id,
            onPick: { item, frame, tilt in
                pulled = PulledBook(
                    book: item.book,
                    progress: item.progress,
                    source: frame,
                    sourceTilt: tilt
                )
            },
            onHold: { item in managing = item },
            onNearEnd: loadMore,
            isLoadingMore: feed.isLoading,
            loadFailed: feed.failed
        )
        .id(collection)
        .transition(.opacity.combined(with: .offset(y: DS.Space.xl)))
    }

    private func resultList(_ books: [Book]) -> some View {
        List(books) { book in
            NavigationLink(value: book) {
                BookRow(book: book)
            }
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

/// Your saved versions, each marked with its book's ribbon. Tap one to read
/// it; hold one to read or remove it. "Clear all" empties the section.
private struct VersionsSheet: View {
    let onPick: (Version) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Version.createdAt, order: .reverse) private var versions: [Version]
    /// The story being held, whose manage sheet is open.
    @State private var managing: Version?
    @State private var confirmClear = false
    @State private var holds = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Space.s) {
                    ForEach(versions) { version in
                        VersionCard(version: version)
                            .onTapGesture {
                                onPick(version)
                                dismiss()
                            }
                            .onLongPressGesture(minimumDuration: 0.45) {
                                holds += 1
                                managing = version
                            }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityAction(named: "Manage story") { managing = version }
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.vertical, DS.Space.s)
            }
            .navigationTitle("Twisted books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear all", role: .destructive) { confirmClear = true }
                        .tint(DS.Colors.accent)
                }
            }
            .dsScreen()
            .sensoryFeedback(.impact(weight: .medium), trigger: holds)
            .sheet(item: $managing) { version in
                VersionActionsSheet(version: version) {
                    managing = nil
                    onPick(version)
                    dismiss()
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
        .presentationDetents([.medium, .large])
        .presentationBackground(DS.Colors.canvas)
        // Nothing left to show: close the section.
        .onChange(of: versions.isEmpty) { _, isEmpty in
            if isEmpty { dismiss() }
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
