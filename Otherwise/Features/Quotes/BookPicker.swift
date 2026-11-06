import SwiftUI
import SwiftData

/// Choosing a book: the ones on your shelves first (filtered as you type),
/// then, if you type, any book from Open Library.
struct BookPicker: View {
    let title: LocalizedStringKey
    /// Books that can't be chosen again (already a favourite, say).
    var excluded: Set<String> = []
    let onPick: (Book) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ShelfEntry.updatedAt, order: .reverse) private var shelf: [ShelfEntry]
    @State private var query = ""
    @State private var found: [Book] = []
    @State private var searching = false
    @FocusState private var focused: Bool

    private var trimmed: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Your books, read ones first, matching what you've typed.
    private var yours: [Book] {
        let order: [ShelfStatus: Int] = [.read: 0, .reading: 1, .didNotFinish: 2, .toRead: 3]
        let books = shelf
            .sorted { (order[$0.status] ?? 9) < (order[$1.status] ?? 9) }
            .map(\.book)
            .filter { !excluded.contains($0.id) }
        guard !trimmed.isEmpty else { return books }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) || ($0.author?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack {
                Text(title)
                    .dsDisplay(DS.Typography.heading)
                Spacer()
                CircleButton(systemImage: "xmark", label: "Close") { dismiss() }
            }
            SearchField(prompt: "Your books, or any book", text: $query, focus: $focused)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if !yours.isEmpty {
                        Eyebrow("On your shelves")
                            .padding(.top, DS.Space.xs)
                        ForEach(yours) { book in row(book) }
                    }
                    if !trimmed.isEmpty {
                        Eyebrow("Everywhere")
                            .padding(.top, DS.Space.l)
                        if searching && found.isEmpty {
                            ProgressView().tint(DS.Colors.ink).padding(.vertical, DS.Space.l)
                        }
                        ForEach(found.filter { book in !yours.contains { $0.id == book.id } }) { book in row(book) }
                    } else if yours.isEmpty {
                        Hint("type a title or an author to find any book")
                            .padding(.top, DS.Space.s)
                    }
                }
                .padding(.bottom, DS.Space.xxl)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
        }
        .padding(.horizontal, DS.Space.screen)
        .padding(.top, DS.Space.l)
        .task(id: trimmed) { await search() }
        .dsScreen()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DS.Colors.canvas)
        .dsColorScheme()
    }

    private func row(_ book: Book) -> some View {
        VStack(spacing: 0) {
            Button {
                onPick(Catalog.entry(for: book)?.book ?? book)
                dismiss()
            } label: {
                BookRow(book: book)
            }
            .buttonStyle(PressableButtonStyle())
            Hairline()
        }
    }

    private func search() async {
        guard !trimmed.isEmpty else {
            found = []
            return
        }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        searching = true
        defer { searching = false }
        if let books = try? await OpenLibrary.search(trimmed), !Task.isCancelled {
            found = books
        }
    }
}
