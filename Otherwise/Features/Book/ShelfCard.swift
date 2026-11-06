import SwiftUI
import SwiftData

/// Your copy of a book: which shelf it's on, and then whatever that shelf
/// needs. While you're reading, how far you've got, as a vine you set with
/// a slider. Once you've read it, your rating in roses and the heart.
/// Underneath, the one prominent action: log a read in your diary.
///
/// How far you've read also decides how much of the "What if" map is shown,
/// so nobody is spoiled.
struct ShelfCard: View {
    let book: Book
    let entry: ShelfEntry?
    let diary: [DiaryEntry]
    let onLog: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var fraction: Double = 0.3
    @State private var shown: Double = 0
    @State private var confirmRemove = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var status: ShelfStatus? { entry?.status }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionHeader(title: "Your copy") {
                Hint(verbatim: caption)
            }

            HStack(spacing: DS.Space.xs) {
                ChoicePills(
                    options: [ShelfStatus.toRead, .reading, .read].map { ChoicePills<ShelfStatus>.Option(id: $0, title: $0.title) },
                    selection: status == .didNotFinish ? nil : status,
                    onSelect: choose
                )
                more
            }

            Group {
                switch status {
                case .reading:
                    reading
                case .read, .didNotFinish:
                    verdict
                case .toRead:
                    Text("On your list. Mark it Reading when you start, and the story map opens as you go.")
                        .font(DS.Typography.blurb)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineSpacing(DS.Leading.relaxed)
                        .fixedSize(horizontal: false, vertical: true)
                case nil:
                    Text("Put it on a shelf to keep track of it.")
                        .font(DS.Typography.blurb)
                        .foregroundStyle(DS.Colors.inkSecondary)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))

            PrimaryButton(diary.isEmpty ? "Log a read" : "Log another read", systemImage: "plus", action: onLog)
                .padding(.top, DS.Space.xs)
        }
        .animation(DS.Motion.standard, value: status)
        .onAppear {
            if let entry, entry.status == .reading, entry.progress > 0 { fraction = entry.progress }
            fill(to: target)
        }
        .onChange(of: target) { _, value in fill(to: value) }
        .confirmationDialog("Take it off your shelves?", isPresented: $confirmRemove, titleVisibility: .visible) {
            Button("Remove from shelves", role: .destructive) {
                withAnimation(DS.Motion.standard) { Library.unshelve(book, in: modelContext) }
            }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("Your diary entries and quotes from it stay.")
        }
    }

    // MARK: Reading

    private var reading: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(verbatim: "\(Int((shown * 100).rounded()))")
                    .font(DS.Typography.numeral)
                    .contentTransition(.numericText(value: shown))
                Text(verbatim: "%")
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Colors.inkSecondary)
                Spacer()
                if let pages = Catalog.pages(for: book) ?? entry?.pages, pages > 0 {
                    Hint("page \(Int((shown * Double(pages)).rounded())) of \(pages)")
                }
            }
            .foregroundStyle(DS.Colors.ink)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("\(Int((shown * 100).rounded())) percent read"))

            VineGauge(value: shown, isFinished: false)

            VStack(spacing: DS.Space.xxs) {
                Slider(value: $fraction, in: 0.01...0.99, onEditingChanged: { editing in
                    if !editing { Library.setProgress(fraction, for: book, in: modelContext) }
                })
                .tint(DS.Colors.stem)
                .onChange(of: fraction) { _, value in shown = value }
                .accessibilityLabel("How far through the book")
                .accessibilityValue(Text("\(Int(fraction * 100)) percent"))
                HStack {
                    Hint("beginning")
                    Spacer()
                    Hint("end")
                }
            }
            .padding(.horizontal, DS.Space.m)
            .padding(.vertical, DS.Space.s)
            .dsOutline()
        }
    }

    // MARK: Read

    private var verdict: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                RoseRating(value: entry?.rating ?? 0, size: DS.Size.roseRatingLarge) { value in
                    withAnimation(DS.Motion.quick) { Library.rate(book, value, in: modelContext) }
                }
                Hint((entry?.rating ?? 0) > 0 ? ratingHint : "tap or drag along the roses to rate")
            }
            Spacer(minLength: DS.Space.s)
            HeartToggle(isOn: entry?.liked ?? false, size: 26) {
                Library.setLiked(book, !(entry?.liked ?? false), in: modelContext)
            }
        }
    }

    private var ratingHint: LocalizedStringKey {
        "\(RoseRating.spoken(entry?.rating ?? 0).lowercased()) · tap again to clear"
    }

    // MARK: More

    private var more: some View {
        Menu {
            Button {
                Library.shelve(book, as: .didNotFinish, in: modelContext)
            } label: {
                Label("Didn’t finish it", systemImage: "bookmark.slash")
            }
            if entry != nil {
                Button(role: .destructive) {
                    confirmRemove = true
                } label: {
                    Label("Remove from shelves", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DS.Colors.ink)
                .frame(width: DS.Size.pill + 6, height: DS.Size.pill + 6)
                .overlay { Circle().strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline) }
                .contentShape(Circle())
        }
        .accessibilityLabel("More")
    }

    // MARK: Helpers

    private var caption: String {
        if status == .didNotFinish { return String(localized: "didn’t finish") }
        if let last = diary.first {
            let date = last.readOn.formatted(.dateTime.day().month(.abbreviated).year())
            return diary.count > 1
                ? String(localized: "read \(diary.count) times · last \(date)")
                : String(localized: "read \(date)")
        }
        if let entry {
            return String(localized: "added \(entry.addedAt.formatted(.dateTime.day().month(.abbreviated)))")
        }
        return String(localized: "not on a shelf")
    }

    private var target: Double {
        guard let entry else { return 0 }
        switch entry.status {
        case .reading: return entry.progress
        case .read: return 1
        case .toRead, .didNotFinish: return entry.progress
        }
    }

    private func fill(to value: Double) {
        withAnimation(reduceMotion ? DS.Motion.standard : .easeInOut(duration: 1.2)) { shown = value }
    }

    private func choose(_ newStatus: ShelfStatus) {
        withAnimation(DS.Motion.standard) {
            if newStatus == .reading {
                let start = (entry?.status == .reading && (entry?.progress ?? 0) > 0) ? entry!.progress : 0.05
                fraction = start
                Library.shelve(book, as: .reading, in: modelContext)
                Library.setProgress(start, for: book, in: modelContext)
            } else {
                Library.shelve(book, as: newStatus, in: modelContext)
            }
        }
    }
}

#Preview {
    ShelfCard(book: Catalog.entries[0].book, entry: nil, diary: [], onLog: {})
        .padding(DS.Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modelContainer(Store.preview())
        .dsScreen()
}
