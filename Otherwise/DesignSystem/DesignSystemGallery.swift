import SwiftUI

/// A living reference of every token and component.
/// Open the canvas (⌥⌘↩) on this file before shipping a change.
struct DesignSystemGallery: View {
    @State private var text = ""
    @State private var choice = 0
    @State private var ribbon = true
    @State private var collection = Glyph.library
    @State private var progress: ReadingProgress? = .partway(0.4)
    @FocusState private var focused: Bool

    private let colors: [(String, Color)] = [
        ("canvas", DS.Colors.canvas),
        ("surface", DS.Colors.surface),
        ("surfaceRaised", DS.Colors.surfaceRaised),
        ("page", DS.Colors.page),
        ("ink", DS.Colors.ink),
        ("inkSecondary", DS.Colors.inkSecondary),
        ("inkTertiary", DS.Colors.inkTertiary),
        ("pageInk", DS.Colors.pageInk),
        ("accent", DS.Colors.accent),
        ("accentDeep", DS.Colors.accentDeep),
        ("positive", DS.Colors.positive),
        ("caution", DS.Colors.caution),
    ]

    private let spaces: [(String, CGFloat)] = [
        ("xxs", DS.Space.xxs), ("xs", DS.Space.xs), ("s", DS.Space.s), ("m", DS.Space.m),
        ("l", DS.Space.l), ("xl", DS.Space.xl), ("xxl", DS.Space.xxl),
    ]

    private var sample: CatalogEntry { Catalog.entries[0] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xxl) {
                section("The room") {
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
                                Text(verbatim: name).font(DS.Typography.caption).foregroundStyle(DS.Colors.inkSecondary)
                            }
                        }
                    }
                    Capsule()
                        .fill(DS.Gradients.twilight)
                        .frame(height: DS.Space.s)
                        .dsGlow(DS.Colors.accentDeep)
                    Text(verbatim: "twilight").font(DS.Typography.caption).foregroundStyle(DS.Colors.inkSecondary)
                }

                section("Editions") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Space.m) {
                            ForEach(Catalog.entries, id: \.book.id) { entry in
                                BookCover(book: entry.book, size: .medium)
                                    .dsGlow(entry.edition.glow, radius: 16, strength: 0.4)
                            }
                        }
                        .padding(.vertical, DS.Space.m)
                    }
                    .scrollClipDisabled()
                }

                section("Type") {
                    Text("Display").font(DS.Typography.display)
                    Text("Title").font(DS.Typography.title)
                    Text(verbatim: "72").font(DS.Typography.gauge).foregroundStyle(DS.Colors.accent)
                    Text("Screen title").font(DS.Typography.screenTitle)
                    Text("Heading").font(DS.Typography.heading)
                    Text("Row title").font(DS.Typography.rowTitle)
                    RaisedCapText(text: "Reading text opens with a raised capital in the book’s ink.", ink: sample.edition.ink)
                    Text("Interface body").font(DS.Typography.body)
                    Text("Meta · 1813").font(DS.Typography.meta).foregroundStyle(DS.Colors.inkSecondary)
                    Text("Folio · 12").font(DS.Typography.folio).foregroundStyle(DS.Colors.inkTertiary)
                    Eyebrow("Eyebrow")
                }
                .foregroundStyle(DS.Colors.ink)

                section("Space") {
                    ForEach(spaces, id: \.0) { name, value in
                        HStack(spacing: DS.Space.s) {
                            Rectangle().fill(DS.Colors.accent).frame(width: value, height: DS.Space.s)
                            Text(verbatim: "\(name) · \(Int(value))").font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.inkSecondary)
                        }
                    }
                }

                section("Icons") {
                    GlyphSwitcher(
                        items: Glyph.allCases.map { GlyphSwitcher<Glyph>.Item(id: $0, glyph: $0, label: LocalizedStringKey($0.rawValue)) },
                        selection: $collection
                    )
                    TwistMark(edition: sample.edition)
                }

                section("Book objects") {
                    SlabBook(book: sample.book, length: 320, progress: 0.4, coverAngle: 74)
                        .padding(.vertical, DS.Space.l)
                    HStack(alignment: .bottom, spacing: DS.Space.l) {
                        BookCover(book: sample.book, size: .small)
                        FlippableCover(book: sample.book, blurb: sample.map.premise)
                    }
                    HStack(spacing: DS.Space.l) {
                        BookmarkRibbon(color: sample.edition.ink, isPlaced: ribbon)
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
                    Ornament(color: sample.edition.ink)
                }

                section("Gauges") {
                    ReadingGauge(edition: sample.edition, progress: progress) { progress = $0 }
                }

                section("Components") {
                    QuoteBlock(text: "Darcy asks Elizabeth to dance.", ink: sample.edition.ink)
                    VStack(spacing: 0) {
                        ForEach(Array(sample.map.moments[0].alternatives.enumerated()), id: \.offset) { index, alternative in
                            BranchRow(isLast: index == sample.map.moments[0].alternatives.count - 1, ink: sample.edition.ink, isLit: choice == index) {
                                ChoiceRow(text: alternative, isSelected: choice == index, ink: sample.edition.ink) { choice = index }
                            }
                        }
                    }
                    ComposerField(placeholder: "Describe what happens instead.", text: $text, focus: $focused, tint: sample.edition.ink)
                    InlineNotice(symbol: "apple.intelligence", title: "Turn on Apple Intelligence", message: "Plot Twist writes every story on your iPhone.")
                    WritingIndicator()
                    PrimaryButton("Rewrite from here", edition: sample.edition) {}
                    PrimaryButton("App accent") {}
                    SecondaryButton("Try again", systemImage: "arrow.clockwise") {}
                    GlassIconButton(systemImage: "xmark", label: "Close") {}
                }
            }
            .padding(DS.Space.screen)
        }
        .dsScreen()
        .dsDarkOnly()
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
