import SwiftUI
import SwiftData

/// Home: your books, lying in a deep stack, switchable (at the top right)
/// between what you're reading, what you want to read, and what you've read.
/// Take a book to open it; hold one to manage it.
struct ShelfView: View {
    let pickedID: String?
    let onPick: (StackItem, SlabPose) -> Void
    let onDiscover: () -> Void

    @Query(sort: \ShelfEntry.updatedAt, order: .reverse) private var shelf: [ShelfEntry]
    @AppStorage("shelf.status") private var status: ShelfStatus = .reading
    @State private var managing: StackItem?

    var body: some View {
        ZStack {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(DS.Motion.standard, value: status)
        .navigationTitle("Shelf")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            RootToolbar {
                TabSwitcher(
                    items: ShelfStatus.shelves.map { TabSwitcher<ShelfStatus>.Item(id: $0, title: $0.title) },
                    selection: $status
                )
            }
        }
        .sheet(item: $managing) { BookActionsSheet(book: $0.book) }
        .dsScreen()
    }

    private func entries(_ status: ShelfStatus) -> [ShelfEntry] {
        let matching = shelf.filter { $0.status == status }
        // What's waiting stays in the order you added it; the rest, most recent first.
        return status == .toRead ? matching.sorted { $0.addedAt > $1.addedAt } : matching
    }

    @ViewBuilder private var content: some View {
        let items = entries(status).map {
            StackItem(book: $0.book, progress: $0.status == .toRead ? nil : $0.progress)
        }
        if items.isEmpty {
            empty
                .transition(.opacity)
        } else {
            BookStack(
                items: items,
                pickedID: pickedID,
                onPick: onPick,
                onHold: { managing = $0 },
                intro: intro(count: items.count)
            )
            .id(status)
            .transition(.opacity.combined(with: .offset(y: DS.Space.l)))
        }
    }

    private func intro(count: Int) -> (title: LocalizedStringKey, detail: LocalizedStringKey) {
        switch status {
        case .reading:
            return (title: "Reading now", detail: "^[\(count) book](inflect: true) on the go. Open one to note how far you’ve got.")
        case .toRead:
            return (title: "Up next", detail: "^[\(count) book](inflect: true) waiting for you.")
        case .read, .didNotFinish:
            return (title: "Read", detail: "^[\(count) book](inflect: true). Open one for your diary entries and quotes.")
        }
    }

    @ViewBuilder private var empty: some View {
        switch status {
        case .reading:
            MessageView(
                title: "Nothing on the go",
                message: "Find a book and mark it Reading. It will wait for you here, at the top of the stack."
            ) {
                SecondaryButton("Find a book", systemImage: "magnifyingglass", action: onDiscover)
            }
        case .toRead:
            MessageView(
                title: "Nothing waiting",
                message: "Books you want to read gather here, ready for when you finish this one."
            ) {
                SecondaryButton("Find a book", systemImage: "magnifyingglass", action: onDiscover)
            }
        case .read, .didNotFinish:
            MessageView(
                title: "Nothing read yet",
                message: "Log a book you’ve finished and it goes on this shelf, and into your diary."
            ) {
                SecondaryButton("Find a book", systemImage: "magnifyingglass", action: onDiscover)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShelfView(pickedID: nil, onPick: { _, _ in }, onDiscover: {})
    }
    .modelContainer(Store.preview())
    .dsColorScheme()
}
