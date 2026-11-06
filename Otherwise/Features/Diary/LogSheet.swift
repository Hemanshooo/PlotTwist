import SwiftUI
import SwiftData

/// Logging a read, or editing one: the day you finished, your rating in
/// roses and the heart, what you thought, and two small switches (spoilers,
/// reread). Saving puts it in your diary and the book on your Read shelf.
struct LogSheet: View {
    let book: Book
    var existing: DiaryEntry?
    /// Called when the entry is deleted, so a screen showing it can close first.
    var onDelete: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var earlier: [DiaryEntry]

    @State private var readOn: Date
    @State private var rating: Double
    @State private var liked: Bool
    @State private var review: String
    @State private var hasSpoilers: Bool
    @State private var isReread: Bool
    @State private var choosingDate = false
    @State private var confirmDelete = false
    @State private var saves = 0
    @FocusState private var writing: Bool

    init(book: Book, existing: DiaryEntry? = nil, rating: Double = 0, liked: Bool = false, onDelete: (() -> Void)? = nil) {
        self.book = book
        self.existing = existing
        self.onDelete = onDelete
        let id = book.id
        _earlier = Query(filter: #Predicate<DiaryEntry> { $0.bookID == id })
        _readOn = State(initialValue: existing?.readOn ?? .now)
        _rating = State(initialValue: existing?.rating ?? rating)
        _liked = State(initialValue: existing?.liked ?? liked)
        _review = State(initialValue: existing?.review ?? "")
        _hasSpoilers = State(initialValue: existing?.hasSpoilers ?? false)
        _isReread = State(initialValue: existing?.isReread ?? false)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {
                SheetHeader(
                    book: book,
                    title: Text(book.title),
                    detail: Text(existing == nil ? "Log a read" : "Edit diary entry"),
                    onClose: { dismiss() }
                )

                date
                verdict
                thoughts

                VStack(spacing: 0) {
                    CheckRow(title: "Contains spoilers", detail: "Your review stays hidden until it’s tapped.", isOn: $hasSpoilers)
                    Hairline()
                    CheckRow(title: "I’ve read it before", detail: "Logged as a reread.", isOn: $isReread)
                }

                if existing != nil {
                    Button("Delete this entry", role: .destructive) { confirmDelete = true }
                        .font(DS.Typography.label)
                        .foregroundStyle(DS.Colors.caution)
                        .frame(minHeight: DS.Size.touch)
                }
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.top, DS.Space.l)
            .padding(.bottom, DS.Space.xxl)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(existing == nil ? "Save to diary" : "Save changes", action: save)
                .padding(.horizontal, DS.Space.screen)
                .padding(.vertical, DS.Space.s)
                .background(DS.Colors.canvas)
        }
        .onAppear {
            // A second reading defaults to a reread.
            if existing == nil, !earlier.isEmpty { isReread = true }
        }
        .confirmationDialog("Delete this diary entry?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: delete)
            Button("Keep", role: .cancel) {}
        } message: {
            Text("The book stays on your shelf.")
        }
        .sensoryFeedback(.success, trigger: saves)
        .dsScreen()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DS.Colors.canvas)
        .dsColorScheme()
    }

    // MARK: Sections

    private var date: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionHeader("Finished on")
            Button {
                withAnimation(DS.Motion.standard) { choosingDate.toggle() }
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text(readOn.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                        .font(DS.Typography.heading)
                        .foregroundStyle(DS.Colors.ink)
                    Spacer()
                    Hint(choosingDate ? "done" : "change")
                }
                .frame(minHeight: DS.Size.touch)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())
            if choosingDate {
                DatePicker("Finished on", selection: $readOn, in: ...Date.now, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(DS.Colors.bloom)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .onChange(of: readOn) { _, _ in
                        withAnimation(DS.Motion.standard) { choosingDate = false }
                    }
            }
        }
    }

    private var verdict: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionHeader(title: "Your rating") {
                Hint(verbatim: rating > 0 ? RoseRating.spoken(rating).lowercased() : String(localized: "optional"))
            }
            HStack {
                RoseRating(value: rating, size: DS.Size.roseRatingLarge) { rating = $0 }
                Spacer()
                HeartToggle(isOn: liked, size: 26) { liked.toggle() }
            }
        }
    }

    private var thoughts: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionHeader("Review")
            ComposerField(
                placeholder: "What stayed with you?",
                text: $review,
                focus: $writing,
                label: "Review",
                lines: 4...14
            )
        }
    }

    // MARK: Saving

    private func save() {
        let trimmed = review.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing {
            existing.readOn = readOn
            existing.rating = rating
            existing.liked = liked
            existing.review = trimmed
            existing.hasSpoilers = hasSpoilers
            existing.isReread = isReread
            Library.log(existing, in: modelContext)
        } else {
            let entry = DiaryEntry(
                book: book, readOn: readOn, rating: rating, liked: liked,
                review: trimmed, hasSpoilers: hasSpoilers, isReread: isReread
            )
            Library.log(entry, in: modelContext)
        }
        saves += 1
        dismiss()
    }

    private func delete() {
        guard let existing else { return }
        let context = modelContext
        onDelete?()
        dismiss()
        // Once nothing on screen shows it any more.
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            context.delete(existing)
            Library.save(context)
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            LogSheet(book: Catalog.entries[0].book)
        }
        .modelContainer(Store.preview())
}
