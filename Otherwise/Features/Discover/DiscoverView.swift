import SwiftUI
import SwiftData

/// Finding books: a search field over a stack to browse. The stack starts
/// with the classics that have hand-drawn story maps, then runs on through
/// Open Library as you scroll. Typing replaces it with results.
struct DiscoverView: View {
    let pickedID: String?
    @Binding var isTyping: Bool
    let onPick: (StackItem, SlabPose) -> Void

    @Query private var shelf: [ShelfEntry]
    @State private var query = ""
    @State private var search: SearchState = .idle
    @State private var attempt = 0
    @State private var feed = LibraryFeed()
    @State private var managing: StackItem?
    @FocusState private var focused: Bool

    private enum SearchState: Equatable {
        case idle, loading, results([Book]), failed
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchField(prompt: "Titles, authors", text: $query, focus: $focused)
                .padding(.horizontal, DS.Space.screen)
                .padding(.top, DS.Space.xs)
                .padding(.bottom, DS.Space.s)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            RootToolbar {
                if focused || !query.isEmpty {
                    Button("Cancel") {
                        query = ""
                        focused = false
                    }
                    .font(DS.Typography.label)
                    .foregroundStyle(DS.Colors.ink)
                }
            }
        }
        .task(id: "\(trimmedQuery)#\(attempt)") { await runSearch() }
        .task { if feed.books.isEmpty { await feed.loadMore() } }
        .onChange(of: focused) { _, isFocused in isTyping = isFocused }
        .sheet(item: $managing) { BookActionsSheet(book: $0.book) }
        .dsScreen()
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Content

    @ViewBuilder private var content: some View {
        if trimmedQuery.isEmpty {
            BookStack(
                items: browseItems,
                pickedID: pickedID,
                onPick: { item, pose in
                    focused = false
                    onPick(item, pose)
                },
                onHold: { managing = $0 },
                onNearEnd: { Task { await feed.loadMore() } },
                isLoadingMore: feed.isLoading,
                loadFailed: feed.failed,
                intro: (
                    title: "Begin with a classic",
                    detail: "Twelve with hand-drawn maps of their turning points, then thousands more as you scroll."
                )
            )
        } else {
            switch search {
            case .idle, .loading:
                ProgressView()
                    .tint(DS.Colors.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .results(let books) where books.isEmpty:
                MessageView(
                    title: "No books found",
                    message: "Check the spelling, or try the author’s name."
                )
            case .results(let books):
                results(books)
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

    /// The classics, then Open Library's endless run, minus anything already shown.
    private var browseItems: [StackItem] {
        let progress = Dictionary(shelf.map { ($0.bookID, $0.progress) }, uniquingKeysWith: { first, _ in first })
        let classics = Catalog.entries.map { StackItem(book: $0.book, progress: progress[$0.book.id]) }
        let shown = Set(classics.map(\.id))
        let more = feed.books
            .filter { !shown.contains($0.id) }
            .map { StackItem(book: $0, progress: progress[$0.id]) }
        return classics + more
    }

    private func results(_ books: [Book]) -> some View {
        let statuses = Dictionary(shelf.map { ($0.bookID, $0.status) }, uniquingKeysWith: { first, _ in first })
        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(books) { book in
                    NavigationLink(value: book) {
                        BookRow(book: book, status: statuses[book.id])
                    }
                    .buttonStyle(PressableButtonStyle())
                    Hairline()
                }
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.bottom, DS.Space.xxl)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
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

#Preview {
    @Previewable @State var typing = false
    NavigationStack {
        DiscoverView(pickedID: nil, isTyping: $typing, onPick: { _, _ in })
    }
    .modelContainer(Store.preview())
    .dsColorScheme()
}
