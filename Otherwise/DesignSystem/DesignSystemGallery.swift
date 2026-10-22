import SwiftUI

/// A living reference of every token and component, in every palette.
/// Open the canvas (⌥⌘↩) on this file before shipping a change.
struct DesignSystemGallery: View {
    @State private var text = ""
    @State private var choice = 0
    @State private var ribbon = true
    @State private var collection = Glyph.library
    @State private var progress: ReadingProgress? = .partway(0.4)
    @FocusState private var focused: Bool

    private var colors: [(String, Color)] {
        [
            ("canvas", DS.Colors.canvas),
            ("surface", DS.Colors.surface),
            ("raised", DS.Colors.raised),
            ("page", DS.Colors.page),
            ("ink", DS.Colors.ink),
            ("inkSecondary", DS.Colors.inkSecondary),
            ("inkTertiary", DS.Colors.inkTertiary),
            ("pageInk", DS.Colors.pageInk),
            ("stem", DS.Colors.stem),
            ("bloom", DS.Colors.bloom),
            ("petal", DS.Colors.petal),
            ("caution", DS.Colors.caution),
        ]
    }

    private let spaces: [(String, CGFloat)] = [
        ("xxs", DS.Space.xxs), ("xs", DS.Space.xs), ("s", DS.Space.s), ("m", DS.Space.m),
        ("l", DS.Space.l), ("xl", DS.Space.xl), ("xxl", DS.Space.xxl),
    ]

    private var sample: CatalogEntry { Catalog.entries[0] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xxl) {
                section("Palette") {
                    ChoicePills(
                        options: Palette.allCases.map { ChoicePills<Palette>.Option(id: $0, title: $0.name) },
                        selection: Theme.shared.palette
                    ) { palette in withAnimation(DS.Motion.palette) { Theme.shared.choose(palette) } }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96))], alignment: .leading, spacing: DS.Space.s) {
                        ForEach(colors, id: \.0) { name, color in
                            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                                RoundedRectangle(cornerRadius: DS.Radius.s, style: .continuous)
                                    .fill(color)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: DS.Radius.s, style: .continuous)
                                            .strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline)
                                    }
                                    .frame(height: DS.Size.touch)
                                Hint(verbatim: name)
                            }
                        }
                    }
                }

                section("Garden") {
                    HStack(spacing: DS.Space.l) {
                        Rose(size: 40, seed: 1)
                        Rose(size: 40, seed: 2)
                        Bud(size: 40)
                        Bud(size: 40, muted: true)
                        TwistMark(size: 40)
                    }
                    Growing { Flourish(width: 180, progress: $0) }
                    Growing { Sprig(height: 120, progress: $0) }
                    Wordmark()
                }

                section("Type") {
                    Text("Display").dsDisplay()
                    Text("Title").dsDisplay(DS.Typography.title)
                    Text("Heading").dsDisplay(DS.Typography.heading)
                    Text(verbatim: "72").font(DS.Typography.numeral)
                    RaisedCapText(text: "Reading text opens with a raised capital in the bloom.")
                    Text("A blurb, in the reading face.").font(DS.Typography.blurb)
                    Text("“A quotation.”").font(DS.Typography.quote)
                    Text("Label · 1813").font(DS.Typography.label)
                    Text("Meta · 1813").font(DS.Typography.meta).foregroundStyle(DS.Colors.inkSecondary)
                    Hint("a hint, in lowercase mono")
                    Eyebrow("Eyebrow")
                }
                .foregroundStyle(DS.Colors.ink)

                section("Space") {
                    ForEach(spaces, id: \.0) { name, value in
                        HStack(spacing: DS.Space.s) {
                            Rectangle().fill(DS.Colors.stem).frame(width: value, height: DS.Space.s)
                            Hint(verbatim: "\(name) · \(Int(value))")
                        }
                    }
                }

                section("Icons") {
                    GlyphSwitcher(
                        items: Glyph.allCases.map { GlyphSwitcher<Glyph>.Item(id: $0, glyph: $0, label: LocalizedStringKey($0.rawValue)) },
                        selection: $collection
                    )
                    HStack(spacing: DS.Space.l) {
                        ForEach(Glyph.allCases, id: \.self) { GlyphView(glyph: $0, isSelected: true, size: 56) }
                    }
                    PaletteButton {}
                }

                section("Book objects") {
                    SlabBook(book: sample.book, length: 320, progress: 0.4, coverAngle: 74)
                        .padding(.vertical, DS.Space.l)
                    HStack(alignment: .bottom, spacing: DS.Space.l) {
                        BookCover(book: sample.book, size: .small)
                        FlippableCover(book: sample.book, blurb: sample.map.premise)
                    }
                    HStack(spacing: DS.Space.l) {
                        BookmarkRibbon(color: DS.Colors.bloom, isPlaced: ribbon)
                            .frame(height: DS.Size.ribbonLength, alignment: .top)
                            .clipped()
                        SecondaryButton("Drop ribbon") { ribbon.toggle() }
                    }
                    PageCard {
                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Eyebrow("In the book")
                            Text(sample.map.moments[0].happened).dsReading()
                        }
                    }
                }

                section("Reading") {
                    ReadingGauge(progress: progress) { progress = $0 }
                }

                section("Components") {
                    QuoteBlock(text: "Darcy asks Elizabeth to dance.")
                    VStack(spacing: 0) {
                        ForEach(Array(sample.map.moments[0].alternatives.enumerated()), id: \.offset) { index, alternative in
                            BranchRow(isLast: index == sample.map.moments[0].alternatives.count - 1, isLit: choice == index, seed: index) {
                                ChoiceRow(text: alternative, isSelected: choice == index) { choice = index }
                            }
                        }
                    }
                    ComposerField(placeholder: "Describe what happens instead.", text: $text, focus: $focused)
                    InlineNotice(symbol: "apple.intelligence", title: "Turn on Apple Intelligence", message: "Plot Twist writes every story on your iPhone.")
                    WritingIndicator()
                    PrimaryButton("Rewrite from here", systemImage: "arrow.right") {}
                    SecondaryButton("Try again", systemImage: "arrow.clockwise") {}
                    CircleButton(systemImage: "xmark", label: "Close") {}
                    ActionRow(Text("Remove from Read"), systemImage: "bookmark.slash", detail: Text("Later moments seal again.")) {}
                }
            }
            .padding(DS.Space.screen)
        }
        .dsScreen()
        .dsColorScheme()
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            Eyebrow(title)
            Hairline()
            content()
        }
    }
}

#Preview { DesignSystemGallery() }
