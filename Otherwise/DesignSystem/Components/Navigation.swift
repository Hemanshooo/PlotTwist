import SwiftUI

/// The app's places, in the tab bar's order. Discover sits apart, behind
/// the search circle.
enum AppTab: String, CaseIterable, Hashable {
    case shelf, diary, quotes, you, discover

    var title: LocalizedStringKey {
        switch self {
        case .shelf: "Shelf"
        case .diary: "Diary"
        case .quotes: "Quotes"
        case .you: "You"
        case .discover: "Discover"
        }
    }

    static let barItems: [AppTab] = [.shelf, .diary, .quotes, .you]
}

/// The tab bar: the four places as words in an outlined capsule, the current
/// one in the ink pill (the same toggle as the shelf's), and a search circle
/// beside it for finding any book. It floats over the screen, flat, with a
/// soft shadow so scrolling covers pass cleanly beneath it.
struct AppTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            TabSwitcher(
                items: AppTab.barItems.map { TabSwitcher<AppTab>.Item(id: $0, title: $0.title) },
                selection: $selection,
                height: DS.Size.tabBar - 6
            )
            SearchCircle(isSelected: selection == .discover) {
                withAnimation(DS.Motion.select) { selection = .discover }
            }
        }
        .dsFloating()
        .padding(.bottom, DS.Space.xs)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }
}

/// The round search button at the end of the tab bar; solid ink while you're in Discover.
private struct SearchCircle: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isSelected ? DS.Colors.onInk : DS.Colors.ink)
                .frame(width: DS.Size.tabBar, height: DS.Size.tabBar)
                .background(isSelected ? DS.Colors.ink : DS.Colors.canvas, in: Circle())
                .overlay { Circle().strokeBorder(isSelected ? .clear : DS.Colors.hairline, lineWidth: DS.Size.hairline) }
                .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Discover")
        .accessibilityHint("Search for any book")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// A search field in the garden's style: an outlined capsule with a mono
/// prompt, outlined in ink while you type.
struct SearchField<Accessory: View>: View {
    let prompt: LocalizedStringKey
    @Binding var text: String
    var focus: FocusState<Bool>.Binding
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DS.Colors.inkSecondary)
            TextField(prompt, text: $text)
                .font(DS.Typography.field)
                .foregroundStyle(DS.Colors.ink)
                .focused(focus)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(DS.Colors.inkTertiary)
                        .frame(width: DS.Size.touch - 12, height: DS.Size.touch - 12)
                }
                .accessibilityLabel("Clear")
            }
            accessory
        }
        .padding(.leading, DS.Space.m)
        .padding(.trailing, DS.Space.xxs)
        .frame(minHeight: DS.Size.touch)
        .background(DS.Colors.canvas, in: Capsule())
        .overlay {
            Capsule().strokeBorder(
                focus.wrappedValue ? DS.Colors.ink : DS.Colors.hairline,
                lineWidth: focus.wrappedValue ? 1.2 : DS.Size.hairline
            )
        }
        .animation(DS.Motion.quick, value: focus.wrappedValue)
    }
}

extension SearchField where Accessory == EmptyView {
    init(prompt: LocalizedStringKey, text: Binding<String>, focus: FocusState<Bool>.Binding) {
        self.init(prompt: prompt, text: text, focus: focus) { EmptyView() }
    }
}

/// The top of every main screen: the wordmark at the left, anything else at the right.
struct RootToolbar<Trailing: View>: ToolbarContent {
    @ViewBuilder var trailing: Trailing

    var body: some ToolbarContent {
        // The centred inline title is left empty; the wordmark stands in for it.
        ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1) }
        ToolbarItem(placement: .topBarLeading) { Wordmark() }
            .sharedBackgroundVisibility(.hidden)
        ToolbarItem(placement: .topBarTrailing) { trailing }
            .sharedBackgroundVisibility(.hidden)
    }
}

/// A main screen's title: a display line and an italic one beneath, set at the
/// top of the content (the wordmark has the top bar).
struct ScreenTitle: View {
    let title: LocalizedStringKey
    var detail: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxs) {
            Text(title)
                .dsDisplay(DS.Typography.title)
                .accessibilityAddTraits(.isHeader)
            if let detail {
                Text(detail)
                    .font(DS.Typography.quoteSmall)
                    .foregroundStyle(DS.Colors.inkSecondary)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// A section on a page: mono capitals at the left, a hint or a count at the
/// right, a hairline beneath.
struct SectionHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(spacing: DS.Space.xs) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow(title)
                Spacer(minLength: DS.Space.s)
                trailing
            }
            Hairline()
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: LocalizedStringKey) {
        self.init(title: title) { EmptyView() }
    }
}

extension SectionHeader where Trailing == Hint {
    init(_ title: LocalizedStringKey, hint: String) {
        self.init(title: title) { Hint(verbatim: hint) }
    }
}
