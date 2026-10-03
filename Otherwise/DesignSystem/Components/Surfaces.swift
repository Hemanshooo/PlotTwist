import SwiftUI

/// A raised group of rows on the surface color, separated by hairlines.
/// Used for any list that lives inside a scrolling screen.
struct GroupedSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                .strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline)
        }
    }
}

/// The multiline field where the reader writes their change.
struct ComposerField: View {
    let placeholder: String
    @Binding var text: String
    var focus: FocusState<Bool>.Binding
    /// Border colour while editing: the book's ink, or the app accent.
    var tint: Color = DS.Colors.accent

    var body: some View {
        TextField(
            "What changes",
            text: $text,
            prompt: Text(placeholder).foregroundStyle(DS.Colors.inkTertiary),
            axis: .vertical
        )
        .font(DS.Typography.compose)
        .foregroundStyle(DS.Colors.ink)
        .lineSpacing(DS.Leading.relaxed)
        .lineLimit(3...8)
        .focused(focus)
        .submitLabel(.done)
        .padding(DS.Space.m)
        .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                .strokeBorder(
                    focus.wrappedValue ? tint.opacity(0.7) : DS.Colors.hairline,
                    lineWidth: DS.Size.hairline
                )
        }
        .tint(tint)
        .animation(DS.Motion.quick, value: focus.wrappedValue)
    }
}

/// One option in a single-choice list. The chosen row is outlined in the
/// book's ink and a ribbon bookmark drops onto it.
struct ChoiceRow: View {
    let text: String
    let isSelected: Bool
    var ink: Color = DS.Colors.accent
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: DS.Space.s) {
                Image(systemName: systemImage ?? (isSelected ? "checkmark.circle.fill" : "circle"))
                    .foregroundStyle(isSelected ? ink : DS.Colors.inkTertiary)
                    .contentTransition(.symbolEffect(.replace))
                Text(text)
                    .font(DS.Typography.rowTitle)
                    .foregroundStyle(DS.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(width: DS.Size.ribbonWidth, height: 1)
            }
            .padding(DS.Space.m)
            .frame(minHeight: DS.Size.touch)
            .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                    .strokeBorder(isSelected ? ink : DS.Colors.hairline, lineWidth: isSelected ? 1.5 : DS.Size.hairline)
            }
            .overlay(alignment: .topTrailing) {
                BookmarkRibbon(color: ink, isPlaced: isSelected, width: 12, length: 30)
                    .frame(height: 30, alignment: .top)
                    .clipped()
                    .padding(.trailing, DS.Space.m)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Full-area message for empty, unavailable and error states.
struct MessageView<Actions: View>: View {
    let symbol: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: DS.Space.m) {
            Image(systemName: symbol)
                .font(DS.Typography.symbol)
                .foregroundStyle(DS.Colors.inkTertiary)
                .padding(.bottom, DS.Space.xxs)
            Text(title)
                .font(DS.Typography.heading)
                .foregroundStyle(DS.Colors.ink)
            Text(message)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.inkSecondary)
                .lineSpacing(DS.Leading.relaxed)
            actions
                .padding(.top, DS.Space.xs)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, DS.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension MessageView where Actions == EmptyView {
    init(symbol: String, title: LocalizedStringKey, message: LocalizedStringKey) {
        self.init(symbol: symbol, title: title, message: message) { EmptyView() }
    }
}

/// A compact explanation that sits inside a screen rather than replacing it.
struct InlineNotice: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        GroupedSurface {
            HStack(alignment: .firstTextBaseline, spacing: DS.Space.s) {
                Image(systemName: symbol)
                    .foregroundStyle(DS.Colors.inkSecondary)
                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    Text(verbatim: title)
                        .font(DS.Typography.emphasis)
                        .foregroundStyle(DS.Colors.ink)
                    Text(verbatim: message)
                        .font(DS.Typography.meta)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineSpacing(DS.Leading.relaxed)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(DS.Space.m)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Quiet signal that the model is still writing.
struct WritingIndicator: View {
    var label: LocalizedStringKey = "Writing"
    var color: Color = DS.Colors.inkTertiary

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            Image(systemName: "ellipsis")
                .symbolEffect(.variableColor.iterative.reversing, options: .repeating)
            Text(label)
        }
        .font(DS.Typography.meta)
        .foregroundStyle(color)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @FocusState var focused: Bool
    ScrollView {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            ComposerField(placeholder: "Elizabeth accepts Mr. Collins.", text: $text, focus: $focused)
            ChoiceRow(text: "Darcy never writes the letter", isSelected: true) {}
            ChoiceRow(text: "Lydia is found before Wickham marries her", isSelected: false) {}
            WritingIndicator()
        }
        .padding(DS.Space.screen)
    }
    .dsScreen()
}
