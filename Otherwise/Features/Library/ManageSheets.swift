import SwiftUI
import SwiftData

// MARK: - A book in the stack

/// Opened by holding a book in the stack: take it off your Read list, and
/// remove any versions you've written of it.
struct BookActionsSheet: View {
    let book: Book

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var entries: [ShelfEntry]
    @Query(sort: \Version.createdAt, order: .reverse) private var allVersions: [Version]
    @State private var pendingRemoval: Version?
    @State private var changes = 0

    init(book: Book) {
        self.book = book
        let id = book.id
        _entries = Query(filter: #Predicate<ShelfEntry> { $0.bookID == id })
    }

    private var entry: ShelfEntry? { entries.first }
    private var versions: [Version] { allVersions.filter { $0.bookID == book.id } }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            SheetHeader(book: book, title: Text(book.title), detail: book.byline.map { Text($0) }, onClose: { dismiss() })

            if entry == nil && versions.isEmpty {
                Text("Nothing to remove yet. Say how far you’ve read this book, or write a version of it, and you can manage it here.")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let entry {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Eyebrow("Reading")
                    ActionRow(
                        Text("Remove from Read"),
                        systemImage: "bookmark.slash",
                        detail: Text(readingDetail(entry))
                    ) {
                        withAnimation(DS.Motion.standard) { modelContext.delete(entry) }
                        changes += 1
                    }
                }
                .transition(.opacity)
            }

            if !versions.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Eyebrow("Twisted versions")
                    ForEach(versions) { version in
                        ActionRow(
                            versionTitle(version),
                            systemImage: "trash",
                            detail: versionDetail(version),
                            isDestructive: true
                        ) {
                            pendingRemoval = version
                        }
                        .transition(.opacity)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Space.screen)
        .padding(.top, DS.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsScreen()
        .sensoryFeedback(.success, trigger: changes)
        .confirmRemoval(of: $pendingRemoval) { version in
            withAnimation(DS.Motion.standard) { modelContext.delete(version) }
            changes += 1
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DS.Colors.canvas)
    }

    /// A version's name; one saved without a title goes by its change.
    private func versionTitle(_ version: Version) -> Text {
        Text(version.title.isEmpty ? version.change : version.title)
    }

    /// Your change, or, when that's already the name, the day it was written.
    private func versionDetail(_ version: Version) -> Text {
        version.title.isEmpty
            ? Text("Written \(version.createdAt.formatted(date: .abbreviated, time: .omitted))")
            : Text("“\(version.change)”")
    }

    private func readingDetail(_ entry: ShelfEntry) -> LocalizedStringKey {
        if entry.isFinished { return "Marked as finished. Its turning points seal again." }
        return "About \(Int((entry.progress * 10).rounded()) * 10)% through. Later turning points seal again."
    }
}

// MARK: - A story in Twisted

/// Opened by holding a story in Twisted: read it, or remove it. The list
/// that opened it does the removing, once this sheet has closed.
struct VersionActionsSheet: View {
    let version: Version
    let onRead: () -> Void
    let onRemove: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pendingRemoval: Version?

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            SheetHeader(
                book: version.book,
                title: Text(version.title.isEmpty ? version.change : version.title),
                detail: Text("after \(version.bookTitle)"),
                onClose: { dismiss() }
            )
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                ActionRow(Text("Read this story"), systemImage: "book", detail: Text("“\(version.change)”"), action: onRead)
                ActionRow(
                    Text("Remove from Twisted"),
                    systemImage: "trash",
                    detail: Text("Deletes this story. The book stays in your library."),
                    isDestructive: true
                ) {
                    pendingRemoval = version
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Space.screen)
        .padding(.top, DS.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsScreen()
        .confirmRemoval(of: $pendingRemoval) { _ in onRemove() }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(DS.Colors.canvas)
    }
}

// MARK: - Shared

/// The top of a manage sheet: the book's cover, a title, a line of detail, and close.
private struct SheetHeader: View {
    let book: Book
    let title: Text
    let detail: Text?
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: DS.Space.s) {
            BookCover(book: book, size: .small)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                title
                    .font(DS.Typography.heading)
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(2)
                if let detail {
                    detail
                        .font(DS.Typography.meta)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(DS.Typography.emphasis)
                    .frame(width: DS.Size.touch, height: DS.Size.touch)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .foregroundStyle(DS.Colors.ink)
            .accessibilityLabel("Close")
        }
    }
}

extension View {
    /// Asks once before a version is deleted, since it can't be undone.
    func confirmRemoval(of version: Binding<Version?>, perform: @escaping (Version) -> Void) -> some View {
        confirmationDialog(
            "Remove this version?",
            isPresented: Binding(get: { version.wrappedValue != nil }, set: { if !$0 { version.wrappedValue = nil } }),
            titleVisibility: .visible,
            presenting: version.wrappedValue
        ) { item in
            Button("Remove", role: .destructive) { perform(item) }
            Button("Keep", role: .cancel) {}
        } message: { _ in
            Text("The story will be deleted from Twisted. This can’t be undone.")
        }
    }
}
