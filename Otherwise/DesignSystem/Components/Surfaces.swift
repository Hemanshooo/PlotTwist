import SwiftUI

/// The multiline field where the reader writes their change: an outline on
/// the ground, set in the reading face.
struct ComposerField: View {
    let placeholder: String
    @Binding var text: String
    var focus: FocusState<Bool>.Binding

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: DS.Radius.s, style: .continuous)
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
        .background(DS.Colors.surface, in: shape)
        .overlay {
            shape.strokeBorder(
                focus.wrappedValue ? DS.Colors.ink : DS.Colors.hairline,
                lineWidth: focus.wrappedValue ? 1.2 : DS.Size.hairline
            )
        }
        .tint(DS.Colors.bloom)
        .animation(DS.Motion.quick, value: focus.wrappedValue)
    }
}

/// One option in a single-choice list: an outlined card in the reading face
/// that fills and takes a firm edge when chosen.
struct ChoiceRow: View {
    let text: String
    let isSelected: Bool
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: DS.Space.s) {
                marker
                Text(text)
                    .font(DS.Typography.blurb)
                    .foregroundStyle(isSelected ? DS.Colors.ink : DS.Colors.inkSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, DS.Space.m)
            .padding(.vertical, DS.Space.s + 2)
            .frame(minHeight: DS.Size.touch)
            .dsOutline(isSelected: isSelected)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .animation(DS.Motion.quick, value: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder private var marker: some View {
        if let systemImage {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? DS.Colors.ink : DS.Colors.inkTertiary)
                .frame(width: 14)
        } else {
            Circle()
                .strokeBorder(isSelected ? DS.Colors.ink : DS.Colors.inkTertiary, lineWidth: DS.Size.hairline)
                .background(Circle().fill(isSelected ? DS.Colors.ink : .clear).padding(3.5))
                .frame(width: 14, height: 14)
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
        }
    }
}

/// Full-area message for empty, unavailable and error states: a sprig
/// growing (or a symbol, for errors), a serif title and a line of explanation.
struct MessageView<Actions: View>: View {
    var symbol: String?
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: DS.Space.m) {
            if let symbol {
                Image(systemName: symbol)
                    .font(DS.Typography.symbol)
                    .foregroundStyle(DS.Colors.inkSecondary)
                    .padding(.bottom, DS.Space.xxs)
            } else {
                Growing { Sprig(height: 92, progress: $0) }
                    .padding(.bottom, DS.Space.xs)
            }
            Text(title)
                .dsDisplay(DS.Typography.title)
            Text(message)
                .font(DS.Typography.blurb)
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
    init(symbol: String? = nil, title: LocalizedStringKey, message: LocalizedStringKey) {
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
                .foregroundStyle(DS.Colors.bloom)
            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                Text(verbatim: title)
                    .font(DS.Typography.label)
                    .foregroundStyle(DS.Colors.ink)
                Text(verbatim: message)
                    .font(DS.Typography.blurb)
                    .foregroundStyle(DS.Colors.inkSecondary)
                    .lineSpacing(DS.Leading.relaxed)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DS.Space.m)
        .dsPanel()
        .accessibilityElement(children: .combine)
    }
}

/// Quiet signal that the model is still writing.
struct WritingIndicator: View {
    var label: LocalizedStringKey = "writing"
    var color: Color?

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            Image(systemName: "ellipsis")
                .symbolEffect(.variableColor.iterative.reversing, options: .repeating)
            Text(label)
        }
        .font(DS.Typography.meta)
        .foregroundStyle(color ?? DS.Colors.inkSecondary)
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
            MessageView(title: "Nothing read yet", message: "Open any book and say how far you've read.")
                .frame(height: 320)
        }
        .padding(DS.Space.screen)
    }
    .dsScreen()
}
