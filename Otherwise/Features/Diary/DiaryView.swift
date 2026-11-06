import SwiftUI
import SwiftData

/// Your diary: every book you've finished, newest first, by month. Each day
/// is a numeral in the display serif beside the book, its roses, the heart,
/// and marks for a reread or a review. Above it, this year so far.
struct DiaryView: View {
    var onDiscover: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DiaryEntry.readOn, order: .reverse) private var entries: [DiaryEntry]
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    var body: some View {
        Group {
            if entries.isEmpty {
                MessageView(
                    title: "Your diary is empty",
                    message: "Finish a book and log it. Every read goes here, by the day, with your roses and what you thought."
                ) {
                    if let onDiscover {
                        SecondaryButton("Find a book", systemImage: "magnifyingglass", action: onDiscover)
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                        ScreenTitle(title: "Diary", detail: "Every book you’ve finished, by the day.")
                            .padding(.bottom, DS.Space.l)
                        YearSummary(year: currentYear, count: count(in: currentYear), goal: profiles.first?.readingGoal ?? 0)
                            .padding(.bottom, DS.Space.xl)
                        ForEach(months, id: \.start) { month in
                            SectionHeader(month.title, hint: "\(month.entries.count)")
                                .padding(.top, DS.Space.l)
                            ForEach(month.entries) { entry in
                                NavigationLink(value: entry) {
                                    DiaryRow(entry: entry)
                                }
                                .buttonStyle(PressableButtonStyle())
                                Hairline()
                            }
                        }
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, DS.Space.s)
                    .padding(.bottom, DS.Space.xxl)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Diary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { RootToolbar { EmptyView() } }
        .dsScreen()
    }

    private var currentYear: Int { Calendar.current.component(.year, from: .now) }

    private func count(in year: Int) -> Int {
        entries.filter { Calendar.current.component(.year, from: $0.readOn) == year }.count
    }

    private struct Month {
        let start: Date
        let title: LocalizedStringKey
        let entries: [DiaryEntry]
    }

    /// Entries grouped by month, newest first; months of other years carry their year.
    private var months: [Month] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.dateInterval(of: .month, for: entry.readOn)?.start ?? entry.readOn
        }
        return grouped.keys.sorted(by: >).map { start in
            let sameYear = calendar.component(.year, from: start) == currentYear
            let name = sameYear
                ? start.formatted(.dateTime.month(.wide))
                : start.formatted(.dateTime.month(.wide).year())
            return Month(start: start, title: LocalizedStringKey(name), entries: grouped[start] ?? [])
        }
    }
}

// MARK: - This year

/// This year so far: how many books, as a big numeral, and the goal as a vine.
struct YearSummary: View {
    let year: Int
    let count: Int
    let goal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            HStack(alignment: .firstTextBaseline, spacing: DS.Space.s) {
                Text(verbatim: "\(count)")
                    .font(DS.Typography.statNumeral)
                    .foregroundStyle(DS.Colors.ink)
                    .contentTransition(.numericText(value: Double(count)))
                Text(count == 1 ? "book in \(String(year))" : "books in \(String(year))")
                    .font(DS.Typography.quote)
                    .foregroundStyle(DS.Colors.inkSecondary)
                Spacer()
                if goal > 0 {
                    Hint("goal \(goal)")
                }
            }
            if goal > 0 {
                VineGauge(value: min(Double(count) / Double(goal), 1), isFinished: count >= goal)
                    .frame(height: DS.Size.gaugeHeight * 0.8)
                    .accessibilityLabel(Text("\(count) of \(goal) books"))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - A day

/// One entry: the day as a numeral, the weekday beneath; the book's cover,
/// title and author; then its roses, the heart, and marks for a reread and a review.
struct DiaryRow: View {
    let entry: DiaryEntry

    var body: some View {
        HStack(alignment: .center, spacing: DS.Space.m) {
            VStack(spacing: 0) {
                Text(entry.readOn.formatted(.dateTime.day()))
                    .font(DS.Typography.dayNumeral)
                    .foregroundStyle(DS.Colors.ink)
                Text(entry.readOn.formatted(.dateTime.weekday(.abbreviated)))
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.inkTertiary)
                    .textCase(.lowercase)
            }
            .frame(width: DS.Size.diaryDay)

            BookCover(book: entry.book, size: .small)

            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                Text(entry.title)
                    .font(DS.Typography.heading)
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let author = entry.author {
                    Text(author)
                        .font(DS.Typography.meta)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineLimit(1)
                }
                HStack(spacing: DS.Space.xs) {
                    if entry.rating > 0 { RoseRating(value: entry.rating) }
                    if entry.liked { HeartMark() }
                    if entry.isReread {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DS.Colors.inkTertiary)
                            .accessibilityLabel("Reread")
                    }
                    if entry.hasReview {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DS.Colors.inkTertiary)
                            .accessibilityLabel("Has a review")
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, DS.Space.s)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        DiaryView(onDiscover: {})
    }
    .modelContainer(Store.preview())
    .dsColorScheme()
}
