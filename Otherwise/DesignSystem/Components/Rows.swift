import SwiftUI

/// A book in search results.
struct BookRow: View {
    let book: Book

    private var isMapped: Bool { Catalog.entry(for: book) != nil }

    var body: some View {
        HStack(spacing: DS.Space.m) {
            BookCover(book: book, size: .small)
            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                Text(book.title)
                    .font(DS.Typography.rowTitle)
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(2)
                if let byline = book.byline {
                    Text(byline)
                        .font(DS.Typography.meta)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineLimit(1)
                }
                if isMapped {
                    Label("Story map", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                        .font(DS.Typography.captionEmphasis)
                        .foregroundStyle(Edition.of(book).ink)
                        .padding(.top, DS.Space.xxs)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(DS.Typography.captionEmphasis)
                .foregroundStyle(DS.Colors.inkTertiary)
        }
        .padding(DS.Space.s)
        .dsGlass(cornerRadius: DS.Radius.m)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A twisted story: its book's cover, your change, and the forking mark
/// lit in the book's colours.
struct VersionCard: View {
    let version: Version

    private var edition: Edition { Edition.of(version.book) }

    var body: some View {
        HStack(alignment: .center, spacing: DS.Space.m) {
            BookCover(book: version.book, size: .small)
                .dsGlow(edition.glow, radius: 12, strength: 0.4)
            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                Eyebrow(verbatim: version.bookTitle, color: edition.ink)
                Text(version.title.isEmpty ? version.change : version.title)
                    .font(DS.Typography.rowTitle)
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if !version.title.isEmpty {
                    Text("“\(version.change)”")
                        .font(DS.Typography.quoteSmall)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            TwistMark(edition: edition)
        }
        .padding(DS.Space.m)
        .dsGlass()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// The mark for a twisted story: the forking-path glyph, lit by its book.
struct TwistMark: View {
    let edition: Edition

    var body: some View {
        Glyph.twisted.shape
            .fill(LinearGradient(colors: edition.gradientColors, startPoint: .bottomLeading, endPoint: .topTrailing))
            .frame(width: DS.Size.twistMark * 0.58, height: DS.Size.twistMark * 0.58)
            .frame(width: DS.Size.twistMark, height: DS.Size.twistMark)
            .background(edition.ink.opacity(0.10), in: Circle())
            .overlay { Circle().strokeBorder(edition.ink.opacity(0.25), lineWidth: DS.Size.hairline) }
            .dsGlow(edition.glow, radius: 10, strength: 0.4)
            .accessibilityHidden(true)
    }
}
