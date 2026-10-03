import SwiftUI

/// Small uppercase label that introduces a section.
struct Eyebrow: View {
    private let text: Text
    private let color: Color

    init(_ key: LocalizedStringKey, color: Color = DS.Colors.inkSecondary) {
        self.text = Text(key)
        self.color = color
    }

    /// For content that isn't interface copy, such as a book title.
    init(verbatim string: String, color: Color = DS.Colors.inkSecondary) {
        self.text = Text(verbatim: string)
        self.color = color
    }

    var body: some View {
        text
            .font(DS.Typography.eyebrow)
            .tracking(DS.Tracking.eyebrow)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The user's change, set as a pull quote with the accent rule.
/// This is the one place the accent appears in reading content.
struct QuoteBlock: View {
    let text: String
    /// The rule colour: the book's ink on book screens, the app accent elsewhere.
    var ink: Color = DS.Colors.accent

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.s) {
            Capsule()
                .fill(ink)
                .frame(width: DS.Size.rule)
            Text(text)
                .font(DS.Typography.quote)
                .foregroundStyle(DS.Colors.ink)
                .lineSpacing(DS.Leading.relaxed)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// A 1pt separator in the hairline color.
struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(DS.Colors.hairline)
            .frame(height: DS.Size.hairline)
    }
}

extension View {
    /// Long-form story text: serif, relaxed leading, primary ink.
    func dsReading() -> some View {
        self
            .font(DS.Typography.reading)
            .lineSpacing(DS.Leading.reading)
            .foregroundStyle(DS.Colors.ink)
    }

    /// Every screen: paper background edge to edge, the interface face for
    /// any text that doesn't set its own, and accent tint for system controls.
    func dsScreen() -> some View {
        self
            .font(DS.Typography.body)
            .background(DS.Colors.canvas.ignoresSafeArea())
            .tint(DS.Colors.accent)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: DS.Space.l) {
        Eyebrow("What if")
        QuoteBlock(text: "Elizabeth accepts Mr. Collins's proposal.")
        Hairline()
        Text("It is a truth universally acknowledged…").dsReading()
    }
    .padding(DS.Space.screen)
    .dsScreen()
}
