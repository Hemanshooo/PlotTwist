import SwiftUI
import SwiftData

/// You: your name and a line about you, your favourite four, your year in
/// books (how many, how many pages, your average, and how your roses fall),
/// your shelves, your "What if" stories, and the palette.
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(sort: \ShelfEntry.updatedAt, order: .reverse) private var shelf: [ShelfEntry]
    @Query(sort: \DiaryEntry.readOn, order: .reverse) private var diary: [DiaryEntry]
    @Query private var quotes: [Quote]
    @Query private var versions: [Version]

    @State private var editing = false
    @State private var choosingFavourites = false
    @State private var choosingPalette = false

    private var profile: Profile? { profiles.first }
    private var year: Int { Calendar.current.component(.year, from: .now) }
    private var thisYear: [DiaryEntry] {
        diary.filter { Calendar.current.component(.year, from: $0.readOn) == year }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xxl) {
                header
                favourites
                yearInBooks
                ratings
                shelves
                more
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.top, DS.Space.s)
            .padding(.bottom, DS.Space.xxl)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("You")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            RootToolbar {
                PaletteButton { choosingPalette = true }
            }
        }
        .sheet(isPresented: $editing) { ProfileEditor() }
        .sheet(isPresented: $choosingFavourites) { FavouritesEditor() }
        .sheet(isPresented: $choosingPalette) { PaletteSheet() }
        .onAppear { _ = Profile.current(in: modelContext) }
        .dsScreen()
    }

    // MARK: Header

    private var header: some View {
        Button {
            editing = true
        } label: {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                let name = profile?.name.trimmingCharacters(in: .whitespaces) ?? ""
                Text(name.isEmpty ? String(localized: "Your name") : name)
                    .dsDisplay()
                    .foregroundStyle(name.isEmpty ? DS.Colors.inkTertiary : DS.Colors.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if let bio = profile?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(DS.Typography.quote)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineSpacing(DS.Leading.relaxed)
                        .multilineTextAlignment(.leading)
                }
                Hint(caption)
                    .padding(.top, DS.Space.xxs)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint("Edits your name, a line about you, and your goal")
    }

    private var caption: LocalizedStringKey {
        let read = shelf.filter { $0.status == .read }.count
        if let first = diary.last {
            return "^[\(read) book](inflect: true) read · keeping a diary since \(first.readOn.formatted(.dateTime.month(.wide).year()))"
        }
        return "tap to add your name and a line about you"
    }

    // MARK: Favourite four

    private var favourites: some View {
        let books = profile?.favourites ?? []
        return VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionHeader(title: "Favourite four") {
                Button(books.isEmpty ? "choose" : "change") { choosingFavourites = true }
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.inkSecondary)
            }
            FavouriteFour(books: books) { choosingFavourites = true }
        }
    }

    // MARK: Year in books

    private var yearInBooks: some View {
        let pages = thisYear.compactMap { Catalog.pages(for: $0.book) }.reduce(0, +)
        let rated = thisYear.filter { $0.rating > 0 }
        let average = rated.isEmpty ? 0 : rated.map(\.rating).reduce(0, +) / Double(rated.count)
        let goal = profile?.readingGoal ?? 0
        return VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionHeader(LocalizedStringKey(String(year)), hint: thisYear.isEmpty ? String(localized: "nothing logged yet") : String(localized: "so far"))
            HStack(alignment: .top, spacing: 0) {
                Stat(value: "\(thisYear.count)", label: thisYear.count == 1 ? "book" : "books")
                Stat(value: pages > 0 ? pages.formatted() : "—", label: "pages")
                Stat(value: average > 0 ? average.formatted(.number.precision(.fractionLength(1))) : "—", label: "average")
            }
            if goal > 0 {
                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    VineGauge(value: min(Double(thisYear.count) / Double(goal), 1), isFinished: thisYear.count >= goal)
                        .frame(height: DS.Size.gaugeHeight * 0.8)
                    Hint("\(thisYear.count) of \(goal) · your goal for \(String(year))")
                }
                .accessibilityElement(children: .combine)
            } else {
                DashedButton("Set a reading goal for \(String(year))", systemImage: "flag") { editing = true }
            }
        }
    }

    // MARK: Ratings

    private var ratings: some View {
        let rated = shelf.filter { $0.rating > 0 }
        return VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionHeader("Your roses", hint: rated.isEmpty ? String(localized: "nothing rated yet") : String(localized: "\(rated.count) rated"))
            RatingGarden(ratings: rated.map(\.rating))
        }
    }

    // MARK: Shelves

    private var shelves: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("Shelves")
            ForEach([ShelfStatus.reading, .toRead, .read, .didNotFinish]) { status in
                let count = shelf.filter { $0.status == status }.count
                if status != .didNotFinish || count > 0 {
                    NavigationLink(value: ProfileRoute.shelf(status)) {
                        IndexRow(title: status.title, count: count)
                    }
                    .buttonStyle(PressableButtonStyle())
                    Hairline()
                }
            }
        }
    }

    // MARK: More

    private var more: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("Also yours")
            NavigationLink(value: ProfileRoute.whatIf) {
                IndexRow(title: "What if stories", count: versions.count)
            }
            .buttonStyle(PressableButtonStyle())
            Hairline()
            HStack {
                Text("Quotes kept")
                    .font(DS.Typography.heading)
                    .foregroundStyle(DS.Colors.ink)
                Spacer()
                Text(verbatim: "\(quotes.count)")
                    .font(DS.Typography.meta)
                    .foregroundStyle(DS.Colors.inkSecondary)
            }
            .padding(.vertical, DS.Space.s + 2)
            Hairline()
            Hint("everything you keep stays on this iphone")
                .padding(.top, DS.Space.m)
        }
    }
}

// MARK: - Pieces

/// A figure and what it counts, in a column.
private struct Stat: View {
    let value: String
    let label: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: value)
                .font(DS.Typography.statNumeral)
                .foregroundStyle(DS.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.inkTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// A line in an index: a title in the display serif, a count in mono, an arrow.
struct IndexRow: View {
    let title: LocalizedStringKey
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .font(DS.Typography.heading)
                .foregroundStyle(DS.Colors.ink)
            Spacer()
            Text(verbatim: "\(count)")
                .font(DS.Typography.meta)
                .foregroundStyle(DS.Colors.inkSecondary)
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DS.Colors.inkTertiary)
        }
        .padding(.vertical, DS.Space.s + 2)
        .contentShape(Rectangle())
    }
}

/// Your favourite four, side by side; an empty place is a dashed outline you can tap.
struct FavouriteFour: View {
    let books: [Book]
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: DS.Size.favouriteGap) {
            ForEach(0..<4, id: \.self) { index in
                Group {
                    if index < books.count {
                        NavigationLink(value: books[index]) {
                            ScaledBookCover(book: books[index])
                        }
                        .buttonStyle(PressableButtonStyle())
                        .accessibilityLabel(Text(books[index].title))
                    } else {
                        Button(action: onEdit) {
                            RoundedRectangle(cornerRadius: DS.Radius.cover, style: .continuous)
                                .strokeBorder(DS.Colors.inkTertiary, style: StrokeStyle(lineWidth: DS.Size.hairline, dash: [4, 4]))
                                .overlay {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundStyle(DS.Colors.inkTertiary)
                                }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableButtonStyle())
                        .accessibilityLabel("Choose a favourite")
                    }
                }
                .aspectRatio(2 / 3, contentMode: .fit)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// How your ratings fall, as a row of stems: one for each half-rose from ½
/// to 5, as tall as the books you gave it, each topped with a bud (a half)
/// or a rose (a whole) once it has any.
struct RatingGarden: View {
    let ratings: [Double]

    private static let steps: [Double] = (1...10).map { Double($0) / 2 }

    var body: some View {
        let counts = Self.steps.map { step in ratings.filter { abs($0 - step) < 0.01 }.count }
        let most = max(counts.max() ?? 0, 1)
        let ink = GardenInk.current
        let track = DS.Colors.hairline
        VStack(spacing: DS.Space.xs) {
            Canvas { context, size in
                let slot = size.width / CGFloat(Self.steps.count)
                let floor = size.height - 2
                let headroom: CGFloat = 20
                for (index, count) in counts.enumerated() {
                    let x = slot * (CGFloat(index) + 0.5)
                    let base = CGPoint(x: x, y: floor)
                    if count == 0 {
                        context.fill(Path(ellipseIn: CGRect(x: x - 1.5, y: floor - 1.5, width: 3, height: 3)), with: .color(track))
                        continue
                    }
                    let height = max(10, (size.height - headroom) * CGFloat(count) / CGFloat(most))
                    let top = CGPoint(x: x, y: floor - height)
                    let stem = Botany.stem(through: [base, CGPoint(x: x + (index.isMultiple(of: 2) ? 2 : -2), y: floor - height / 2), top])
                    context.drawStem(stem, ink: ink, width: DS.Size.stem + 0.4)
                    if height > 30 {
                        context.drawLeaf(at: CGPoint(x: x, y: floor - height * 0.42), angle: .degrees(index.isMultiple(of: 2) ? -38 : -142), length: 12, ink: ink, vein: false)
                    }
                    if height > 60 {
                        context.drawLeaf(at: CGPoint(x: x, y: floor - height * 0.7), angle: .degrees(index.isMultiple(of: 2) ? -142 : -38), length: 10, ink: ink, vein: false)
                    }
                    let whole = Self.steps[index].truncatingRemainder(dividingBy: 1) == 0
                    if whole {
                        context.drawRose(at: top, size: 17, seed: index, ink: ink)
                    } else {
                        context.drawBud(at: CGPoint(x: x, y: top.y + 4), angle: .degrees(-90), length: 13, ink: ink)
                    }
                }
            }
            .frame(height: 110)
            HStack {
                Hint("half a rose")
                Spacer()
                Hint("five roses")
            }
        }
        .accessibilityElement()
        .accessibilityLabel("How your ratings fall")
        .accessibilityValue(Text(Self.steps.indices.compactMap { index -> String? in
            let count = counts[index]
            return count > 0 ? "\(RoseRating.spoken(Self.steps[index])): \(count)" : nil
        }.joined(separator: ", ")))
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .modelContainer(Store.preview())
    .dsColorScheme()
}
