import SwiftUI

/// A glass group of rows separated by hairlines.
/// Used for any list that lives inside a scrolling screen.
struct GroupedSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .dsGlass()
    }
}

/// The multiline field where the reader writes their change.
struct ComposerField: View {
    let placeholder: String
    @Binding var text: String
    var focus: FocusState<Bool>.Binding
    /// Edge colour while editing: the book's ink, or the app accent.
    var tint: Color = DS.Colors.accent

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
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
        .background(DS.Gradients.glass, in: shape)
        .overlay {
            shape.strokeBorder(
                focus.wrappedValue ? AnyShapeStyle(tint.opacity(0.8)) : AnyShapeStyle(DS.Gradients.glassEdge),
                lineWidth: DS.Size.hairline
            )
        }
        .dsGlow(tint, radius: 16, strength: focus.wrappedValue ? 0.25 : 0)
        .tint(tint)
        .animation(DS.Motion.quick, value: focus.wrappedValue)
    }
}

/// One option in a single-choice list: a glass row that lights up in the
/// book's ink when chosen.
struct ChoiceRow: View {
    let text: String
    let isSelected: Bool
    var ink: Color = DS.Colors.accent
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: DS.Space.s) {
                Image(systemName: systemImage ?? (isSelected ? "checkmark.circle.fill" : "circle"))
                    .foregroundStyle(isSelected ? ink : DS.Colors.inkTertiary)
                    .contentTransition(.symbolEffect(.replace))
                Text(text)
                    .font(DS.Typography.rowTitle)
                    .foregroundStyle(isSelected ? DS.Colors.ink : DS.Colors.ink.opacity(0.86))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(DS.Space.m)
            .frame(minHeight: DS.Size.touch)
            .background {
                ZStack {
                    shape.fill(DS.Gradients.glass)
                    shape.fill(ink.opacity(isSelected ? 0.10 : 0))
                }
            }
            .overlay {
                shape.strokeBorder(
                    isSelected ? AnyShapeStyle(ink.opacity(0.85)) : AnyShapeStyle(DS.Gradients.glassEdge),
                    lineWidth: isSelected ? 1.25 : DS.Size.hairline
                )
            }
            .dsGlow(ink, radius: 18, strength: isSelected ? 0.28 : 0)
            .contentShape(shape)
        }
        .buttonStyle(PressableButtonStyle())
        .animation(DS.Motion.quick, value: isSelected)
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
                .foregroundStyle(DS.Gradients.opal)
                .dsGlow(DS.Colors.accentDeep, radius: 18, strength: 0.4)
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
        HStack(alignment: .firstTextBaseline, spacing: DS.Space.s) {
            Image(systemName: symbol)
                .foregroundStyle(DS.Colors.accent)
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
        .dsGlass()
        .accessibilityElement(children: .combine)
    }
}

/// Quiet signal that the model is still writing.
struct WritingIndicator: View {
    var label: LocalizedStringKey = "Writing"
    var color: Color = DS.Colors.inkSecondary

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
            InlineNotice(symbol: "apple.intelligence", title: "Turn on Apple Intelligence", message: "Plot Twist writes every story on your iPhone.")
            WritingIndicator()
        }
        .padding(DS.Space.screen)
    }
    .dsScreen()
}
