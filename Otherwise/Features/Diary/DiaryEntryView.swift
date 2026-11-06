import SwiftUI
import SwiftData

/// One reading, set like a page: the book's cover and title, the day you
/// finished it, your roses and heart, and your review opening with a raised
/// capital. A review with spoilers stays veiled until you tap it.
struct DiaryEntryView: View {
    let entry: DiaryEntry

    @State private var editing = false
    @State private var showSpoilers = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {
                header
                verdict
                review
                NavigationLink(value: entry.book) {
                    HStack(spacing: DS.Space.xs) {
                        Text("Go to the book")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .font(DS.Typography.label)
                    .foregroundStyle(DS.Colors.ink)
                    .frame(minHeight: DS.Size.touch)
                    .padding(.horizontal, DS.Space.l)
                    .overlay { Capsule().strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline) }
                    .contentShape(Capsule())
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, DS.Space.screen)
            .frame(maxWidth: DS.Space.readingWidth)
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Space.l)
            .padding(.bottom, DS.Space.xxl)
        }
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { editing = true }
                    .font(DS.Typography.label)
            }
        }
        .sheet(isPresented: $editing) {
            LogSheet(book: entry.book, existing: entry) { dismiss() }
        }
        .dsScreen()
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: DS.Space.m) {
            BookCover(book: entry.book, size: .medium)
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Eyebrow(entry.isReread ? "Reread" : "Read")
                Text(entry.title)
                    .dsDisplay(DS.Typography.title)
                    .fixedSize(horizontal: false, vertical: true)
                if let byline = entry.book.byline {
                    Text(byline)
                        .font(DS.Typography.meta)
                        .foregroundStyle(DS.Colors.inkSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var verdict: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionHeader(title: "Finished") {
                Hint(verbatim: entry.readOn.formatted(.dateTime.weekday(.wide).day().month(.wide).year()).lowercased())
            }
            HStack {
                if entry.rating > 0 {
                    RoseRating(value: entry.rating, size: DS.Size.roseRatingLarge)
                } else {
                    Hint("not rated")
                }
                Spacer()
                if entry.liked {
                    HeartMark(size: 22)
                }
            }
        }
    }

    @ViewBuilder private var review: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionHeader("Review")
            if !entry.hasReview {
                Hint("no review · tap edit to write one")
            } else if entry.hasSpoilers && !showSpoilers {
                Button {
                    withAnimation(DS.Motion.standard) { showSpoilers = true }
                } label: {
                    VStack(alignment: .leading, spacing: DS.Space.s) {
                        Text(entry.review)
                            .dsReading()
                            .lineLimit(4)
                            .blur(radius: 7)
                            .accessibilityHidden(true)
                        Label("Contains spoilers · tap to read", systemImage: "eye.slash")
                            .font(DS.Typography.label)
                            .foregroundStyle(DS.Colors.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())
            } else {
                RaisedCapText(text: entry.review)
                    .transition(.opacity)
            }
        }
    }
}
