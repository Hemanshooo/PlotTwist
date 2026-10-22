import SwiftUI

/// A book in search results: its cover, its title in the display serif, a
/// mono byline, and a note in the stem colour if it has a story map.
struct BookRow: View {
    let book: Book

    private var isMapped: Bool { Catalog.entry(for: book) != nil }

    var body: some View {
        HStack(spacing: DS.Space.m) {
            BookCover(book: book, size: .small)
            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                Text(book.title)
                    .font(DS.Typography.heading)
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(2)
                if let byline = book.byline {
                    Text(byline)
                        .font(DS.Typography.meta)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineLimit(1)
                }
                if isMapped {
                    Text("story map")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.stem)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DS.Colors.inkTertiary)
        }
        .padding(.vertical, DS.Space.s)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A twisted story, set like an index entry: its book's cover, the book's
/// title in mono capitals, the story's title in the display serif, your
/// change in italics, and the twist mark.
struct VersionCard: View {
    let version: Version

    /// The story's title, without any markdown emphasis the model wrapped it in.
    private var displayTitle: String {
        let title = version.title.trimmingCharacters(in: CharacterSet(charactersIn: "*_ \n"))
        return title.isEmpty ? version.change : title
    }

    var body: some View {
        HStack(alignment: .center, spacing: DS.Space.m) {
            BookCover(book: version.book, size: .small)
            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                Eyebrow(verbatim: version.bookTitle)
                Text(displayTitle)
                    .font(DS.Typography.heading)
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if displayTitle != version.change {
                    Text("“\(version.change)”")
                        .font(DS.Typography.quoteSmall)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            TwistMark()
        }
        .padding(.vertical, DS.Space.m)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
