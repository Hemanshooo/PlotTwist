import SwiftUI

/// Small mono capitals that introduce a section.
struct Eyebrow: View {
    private let text: Text
    private let color: Color?

    init(_ key: LocalizedStringKey, color: Color? = nil) {
        self.text = Text(key)
        self.color = color
    }

    /// For content that isn't interface copy, such as a book title.
    init(verbatim string: String, color: Color? = nil) {
        self.text = Text(verbatim: string)
        self.color = color
    }

    var body: some View {
        text
            .font(DS.Typography.eyebrow)
            .tracking(DS.Tracking.eyebrow)
            .textCase(.uppercase)
            .foregroundStyle(color ?? DS.Colors.inkSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// A line of lowercase mono, the way Type Garden labels its controls
/// ("type to grow · space cuts"). Hints and small print.
struct Hint: View {
    private let text: Text

    init(_ key: LocalizedStringKey) { text = Text(key) }
    init(verbatim string: String) { text = Text(verbatim: string) }

    var body: some View {
        text
            .font(DS.Typography.caption)
            .foregroundStyle(DS.Colors.inkTertiary)
    }
}

/// The user's change, set as a pull quote with a rule in the bloom colour.
struct QuoteBlock: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.s) {
            Capsule()
                .fill(DS.Colors.bloom)
                .frame(width: DS.Size.rule)
            Text(text)
                .font(DS.Typography.quote)
                .foregroundStyle(DS.Colors.pageInk)
                .lineSpacing(DS.Leading.relaxed)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// A 1pt separator.
struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(DS.Colors.hairline)
            .frame(height: DS.Size.hairline)
    }
}

extension View {
    /// Long-form story text: serif, relaxed leading, page ink.
    func dsReading() -> some View {
        self
            .font(DS.Typography.reading)
            .lineSpacing(DS.Leading.reading)
            .foregroundStyle(DS.Colors.pageInk)
    }

    /// A display title: Instrument Serif, set a little tight.
    func dsDisplay(_ font: Font = DS.Typography.display) -> some View {
        self
            .font(font)
            .tracking(DS.Tracking.display)
            .foregroundStyle(DS.Colors.ink)
    }

    /// Every screen: the palette's flat ground, the reading face for any text
    /// that doesn't set its own, and the ink as the tint for system controls.
    func dsScreen() -> some View {
        self
            .font(DS.Typography.blurb)
            .foregroundStyle(DS.Colors.ink)
            .background { DS.Colors.canvas.ignoresSafeArea() }
            .tint(DS.Colors.ink)
    }

    /// A panel: a step off the ground, with a fine outline. No shadow, no glass.
    func dsPanel(cornerRadius: CGFloat = DS.Radius.s) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .background(DS.Colors.surface, in: shape)
            .overlay { shape.strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline) }
    }

    /// An outline on the ground: choices, fields, quiet buttons.
    func dsOutline(cornerRadius: CGFloat = DS.Radius.s, isSelected: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .background(isSelected ? DS.Colors.raised : DS.Colors.canvas, in: shape)
            .overlay {
                shape.strokeBorder(
                    isSelected ? DS.Colors.ink : DS.Colors.hairline,
                    lineWidth: isSelected ? 1.2 : DS.Size.hairline
                )
            }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: DS.Space.l) {
        Eyebrow("What if")
        Text("The Great Gatsby").dsDisplay()
        Hint("tap to open · hold to manage")
        QuoteBlock(text: "Elizabeth accepts Mr. Collins's proposal.")
        Hairline()
        Text("It is a truth universally acknowledged…").dsReading()
        Text("A panel").padding(DS.Space.m).dsPanel()
        Text("An outline").padding(DS.Space.m).dsOutline(isSelected: true)
    }
    .padding(DS.Space.screen)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .dsScreen()
}
