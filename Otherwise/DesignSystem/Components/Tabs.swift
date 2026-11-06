import SwiftUI

/// Words in an outlined capsule, the chosen one in a solid ink pill that
/// slides between them, like Type Garden's Type | Poster toggle. Switches
/// the shelf between Reading, To read and Read, and is the tab bar.
struct TabSwitcher<ID: Hashable>: View {
    struct Item: Identifiable {
        let id: ID
        let title: LocalizedStringKey
    }

    let items: [Item]
    @Binding var selection: ID
    /// The pill's height; the capsule is a little taller.
    var height: CGFloat = DS.Size.tab

    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let isSelected = item.id == selection
                Button {
                    withAnimation(DS.Motion.select) { selection = item.id }
                } label: {
                    Text(item.title)
                        .font(DS.Typography.tab)
                        .foregroundStyle(isSelected ? DS.Colors.onInk : DS.Colors.inkSecondary)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, height > DS.Size.tab ? DS.Space.m - 2 : DS.Space.s - 2)
                        .frame(height: height)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(DS.Colors.ink)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(3)
        .background(DS.Colors.canvas, in: Capsule())
        .overlay { Capsule().strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline) }
        // The top bar has room for the tabs at the larger text sizes, not the largest.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview {
    @Previewable @State var selection = 0
    TabSwitcher(
        items: [.init(id: 0, title: "Reading"), .init(id: 1, title: "To read"), .init(id: 2, title: "Read")],
        selection: $selection
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .dsScreen()
}
