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

/// The user's change, set as a pull quote with a glowing rule.
struct QuoteBlock: View {
    let text: String
    /// The rule colour: the book's ink on book screens, the app accent elsewhere.
    var ink: Color = DS.Colors.accent

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.s) {
            Capsule()
                .fill(ink)
                .frame(width: DS.Size.rule)
                .dsGlow(ink, radius: 6, strength: 0.6)
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

/// The black room with light falling into it from the top, the way Opal's
/// screens glow behind the gem. Library screens glow mint; a book's screens
/// glow in its own cloth.
struct AmbientBackground: View {
    var tint: Color = DS.Gradients.roomGlow
    /// How much of the screen the light reaches (0…1).
    var reach: CGFloat = 0.62
    var strength: Double = 1

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            ZStack(alignment: .top) {
                DS.Colors.canvas
                EllipticalGradient(
                    stops: [
                        .init(color: tint.opacity(0.34 * strength), location: 0),
                        .init(color: tint.opacity(0.12 * strength), location: 0.45),
                        .init(color: .clear, location: 1),
                    ],
                    center: .top,
                    startRadiusFraction: 0,
                    endRadiusFraction: 0.75
                )
                .frame(height: height * reach)
                .offset(y: -height * 0.06)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Long-form story text: serif, relaxed leading, warm page ink.
    func dsReading() -> some View {
        self
            .font(DS.Typography.reading)
            .lineSpacing(DS.Leading.reading)
            .foregroundStyle(DS.Colors.pageInk)
    }

    /// Every screen: the black room with its glow, the interface face for any
    /// text that doesn't set its own, and the tint for system controls.
    func dsScreen(glow: Color = DS.Gradients.roomGlow, tint: Color = DS.Colors.accent) -> some View {
        self
            .font(DS.Typography.body)
            .foregroundStyle(DS.Colors.ink)
            .background { AmbientBackground(tint: glow) }
            .tint(tint)
    }

    /// A glass card: lit from above, with a bright top edge.
    func dsGlass(cornerRadius: CGFloat = DS.Radius.m) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .background(DS.Gradients.glass, in: shape)
            .overlay { shape.strokeBorder(DS.Gradients.glassEdge, lineWidth: DS.Size.hairline) }
    }

    /// A glass capsule: pills, fields and quiet buttons.
    func dsGlassCapsule(fill: Color = DS.Colors.surface) -> some View {
        self
            .background(fill, in: Capsule())
            .overlay { Capsule().strokeBorder(DS.Gradients.glassEdge, lineWidth: DS.Size.hairline) }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: DS.Space.l) {
        Eyebrow("What if")
        QuoteBlock(text: "Elizabeth accepts Mr. Collins's proposal.")
        Hairline()
        Text("It is a truth universally acknowledged…").dsReading()
        Text("A glass card").padding(DS.Space.m).dsGlass()
    }
    .padding(DS.Space.screen)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .dsScreen()
}
