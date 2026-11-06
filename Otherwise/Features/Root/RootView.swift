import SwiftUI
import SwiftData

/// The whole app: four places and Discover, each with its own navigation,
/// kept alive while you move between them so each stays where you left it.
///
/// The tab bar floats at the foot of the main screens and steps away once you
/// open something (a book, an entry, a quote), so those have the page to themselves.
/// Taking a book from a stack is drawn over everything, tab bar included.
struct RootView: View {
    @AppStorage("root.tab") private var tab: AppTab = .shelf
    @Environment(\.modelContext) private var modelContext

    @State private var shelfPath = NavigationPath()
    @State private var discoverPath = NavigationPath()
    @State private var diaryPath = NavigationPath()
    @State private var quotesPath = NavigationPath()
    @State private var youPath = NavigationPath()

    /// The book being taken from a stack and opened, and the place it came from.
    @State private var pulled: PulledBook?
    @State private var pulledFrom: AppTab = .shelf
    @State private var isTyping = false

    var body: some View {
        ZStack {
            ZStack {
                place(.shelf) {
                    NavigationStack(path: $shelfPath) {
                        ShelfView(
                            pickedID: pulledFrom == .shelf ? pulled?.book.id : nil,
                            onPick: { pick($0, $1, from: .shelf) },
                            onDiscover: { withAnimation(DS.Motion.select) { tab = .discover } }
                        )
                        .endpaperDestinations()
                    }
                }
                place(.discover) {
                    NavigationStack(path: $discoverPath) {
                        DiscoverView(
                            pickedID: pulledFrom == .discover ? pulled?.book.id : nil,
                            isTyping: $isTyping,
                            onPick: { pick($0, $1, from: .discover) }
                        )
                        .endpaperDestinations()
                    }
                }
                place(.diary) {
                    NavigationStack(path: $diaryPath) {
                        DiaryView(onDiscover: { withAnimation(DS.Motion.select) { tab = .discover } })
                            .endpaperDestinations()
                    }
                }
                place(.quotes) {
                    NavigationStack(path: $quotesPath) {
                        QuotesView()
                            .endpaperDestinations()
                    }
                }
                place(.you) {
                    NavigationStack(path: $youPath) {
                        ProfileView()
                            .endpaperDestinations()
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isBarShown {
                    AppTabBar(selection: $tab)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(DS.Motion.standard, value: isBarShown)

            if let pulled {
                BookOpening(pulled: pulled) {
                    // The page fills the screen: put the book's screen beneath it, without a slide.
                    var instant = Transaction()
                    instant.disablesAnimations = true
                    withTransaction(instant) { appendToCurrentPath(pulled.book) }
                } onFinished: {
                    self.pulled = nil
                }
                .zIndex(1)
            }
        }
        .tint(DS.Colors.ink)
        .dsColorScheme()
        #if DEBUG && targetEnvironment(simulator)
        .task { SampleLibrary.addIfNeeded(to: modelContext) }
        #endif
    }

    /// One place, shown when it's the current tab and kept alive when it isn't.
    private func place<Content: View>(_ which: AppTab, @ViewBuilder content: () -> Content) -> some View {
        let isCurrent = tab == which
        return content()
            .opacity(isCurrent ? 1 : 0)
            .allowsHitTesting(isCurrent)
            .accessibilityHidden(!isCurrent)
            .zIndex(isCurrent ? 1 : 0)
    }

    private var currentPathIsEmpty: Bool {
        switch tab {
        case .shelf: shelfPath.isEmpty
        case .discover: discoverPath.isEmpty
        case .diary: diaryPath.isEmpty
        case .quotes: quotesPath.isEmpty
        case .you: youPath.isEmpty
        }
    }

    private var isBarShown: Bool {
        currentPathIsEmpty && pulled == nil && !isTyping
    }

    private func pick(_ item: StackItem, _ pose: SlabPose, from place: AppTab) {
        // One book at a time, and only from a stack on screen.
        guard pulled == nil, tab == place, currentPathIsEmpty else { return }
        pulledFrom = place
        pulled = PulledBook(book: item.book, progress: item.progress, pose: pose)
    }

    private func appendToCurrentPath(_ book: Book) {
        switch pulledFrom {
        case .shelf: shelfPath.append(book)
        case .discover: discoverPath.append(book)
        case .diary: diaryPath.append(book)
        case .quotes: quotesPath.append(book)
        case .you: youPath.append(book)
        }
    }
}

/// Places you can go from a profile.
enum ProfileRoute: Hashable {
    case shelf(ShelfStatus)
    case whatIf
}

extension View {
    /// Every screen any place can open.
    func endpaperDestinations() -> some View {
        self
            .navigationDestination(for: Book.self) { BookView(book: $0) }
            .navigationDestination(for: Version.self) { StoryView(version: $0) }
            .navigationDestination(for: DiaryEntry.self) { DiaryEntryView(entry: $0) }
            .navigationDestination(for: Quote.self) { QuoteView(quote: $0) }
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .shelf(let status): ShelfListView(status: status)
                case .whatIf: WhatIfList()
                }
            }
    }
}

#Preview {
    RootView()
        .modelContainer(Store.preview())
}
