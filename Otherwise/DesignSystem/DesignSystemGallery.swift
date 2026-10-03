import SwiftUI

/// A living reference of every token and component.
/// Open the canvas (⌥⌘↩) on this file and check both appearances before shipping a change.
struct DesignSystemGallery: View {
    @State private var text = ""
    @State private var choice = 0
    @State private var ribbon = true
    @FocusState private var focused: Bool

    private let colors: [(String, Color)] = [
        ("canvas", DS.Colors.canvas),
        ("surface", DS.Colors.surface),
        ("ink", DS.Colors.ink),
        ("inkSecondary", DS.Colors.inkSecondary),
        ("inkTertiary", DS.Colors.inkTertiary),
        ("hairline", DS.Colors.hairline),
        ("accent", DS.Colors.accent),
        ("shelf", DS.Colors.shelf),
        ("fold", DS.Colors.fold),
    ]

    private let spaces: [(String, CGFloat)] = [
        ("xxs", DS.Space.xxs), ("xs", DS.Space.xs), ("s", DS.Space.s), ("m", DS.Space.m),
        ("l", DS.Space.l), ("xl", DS.Space.xl), ("xxl", DS.Space.xxl),
    ]

    private var sample: CatalogEntry { Catalog.entries[0] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xxl) {
                section("Paper & ink") {
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
                }

                section("Editions") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Space.m) {
                            ForEach(Catalog.entries, id: \.book.id) { entry in
                                BookCover(book: entry.book, size: .medium)
                            }
                        }
                        .padding(.vertical, DS.Space.s)
                    }
                    .scrollClipDisabled()
                }

                section("Type") {
                    Text("Display").font(DS.Typography.display)
                    Text("Title").font(DS.Typography.title)
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

                section("Book objects") {
                    HStack(alignment: .bottom, spacing: DS.Space.l) {
                        BookCover(book: sample.book, size: .small)
                        FlippableCover(book: sample.book, blurb: sample.map.premise)
                    }
                    Shelf {
                        ForEach(Array(Catalog.entries.prefix(6).enumerated()), id: \.offset) { index, entry in
                            BookSpine(book: entry.book, isReading: index == 1)
                        }
                    }
                    .padding(.bottom, DS.Space.l)
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

                section("Components") {
                    QuoteBlock(text: "Darcy asks Elizabeth to dance.", ink: sample.edition.ink)
                    ForEach(Array(sample.map.moments[0].alternatives.enumerated()), id: \.offset) { index, alternative in
                        ChoiceRow(text: alternative, isSelected: choice == index, ink: sample.edition.ink) { choice = index }
                    }
                    ComposerField(placeholder: "Describe what happens instead.", text: $text, focus: $focused, tint: sample.edition.ink)
                    ReadingProgressChip(edition: sample.edition, progress: .partway(0.4)) {}
                    InlineNotice(symbol: "apple.intelligence", title: "Turn on Apple Intelligence", message: "Plot Twist writes every story on your iPhone.")
                    WritingIndicator()
                    PrimaryButton("Rewrite from here", edition: sample.edition) {}
                    PrimaryButton("App accent") {}
                    SecondaryButton("Try again", systemImage: "arrow.clockwise") {}
                }
            }
            .padding(DS.Space.screen)
        }
        .dsScreen()
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            Eyebrow(title)
            Hairline()
            content()
        }
    }
}

#Preview("Light") { DesignSystemGallery() }
#Preview("Dark") { DesignSystemGallery().preferredColorScheme(.dark) }
