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
        }
        .padding(.vertical, DS.Space.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A saved version, marked with a branching path in its book's colours:
/// the story went another way.
struct VersionCard: View {
    let version: Version

    private var edition: Edition { Edition.of(version.book) }

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.m) {
            BookCover(book: version.book, size: .small)
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
            TwistMark(color: edition.ink)
        }
        .padding(DS.Space.m)
        .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                .strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// The mark for a twisted story: one path splitting into two.
struct TwistMark: View {
    let color: Color

    var body: some View {
        Image(systemName: "arrow.triangle.branch")
            .font(DS.Typography.captionEmphasis)
            .foregroundStyle(color)
            .frame(width: DS.Size.twistMark, height: DS.Size.twistMark)
            .background(color.opacity(0.12), in: Circle())
            .accessibilityHidden(true)
    }
}
