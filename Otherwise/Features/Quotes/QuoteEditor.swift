import SwiftUI
import SwiftData

/// Keeping a line, or editing one: which book (when it isn't already known),
/// the line itself, its page, and a note on why it stayed with you.
struct QuoteEditor: View {
    /// The book it's from; nil lets you choose.
    let book: Book?
    var existing: Quote?
    var onDelete: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var chosen: Book?
    @State private var text: String
    @State private var page: String
    @State private var note: String
    @State private var choosingBook = false
    @State private var confirmDelete = false
    @State private var saves = 0
    @FocusState private var writingLine: Bool
    @FocusState private var writingNote: Bool

    init(book: Book?, existing: Quote? = nil, onDelete: (() -> Void)? = nil) {
        self.book = book ?? existing?.book
        self.existing = existing
        self.onDelete = onDelete
        _chosen = State(initialValue: book ?? existing?.book)
        _text = State(initialValue: existing?.text ?? "")
        _page = State(initialValue: existing?.page ?? "")
        _note = State(initialValue: existing?.note ?? "")
    }

    private var canSave: Bool {
        chosen != nil && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {
                header
                if book == nil { from }
                line
                VStack(alignment: .leading, spacing: DS.Space.s) {
                    SectionHeader(title: "Why it stayed with you") { Hint("optional") }
                    ComposerField(placeholder: "A note for yourself", text: $note, focus: $writingNote, label: "Note", lines: 2...6)
                }
                if existing != nil {
                    Button("Delete this quote", role: .destructive) { confirmDelete = true }
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
            PrimaryButton(existing == nil ? "Keep this line" : "Save changes", action: save)
                .disabled(!canSave)
                .padding(.horizontal, DS.Space.screen)
                .padding(.vertical, DS.Space.s)
                .background(DS.Colors.canvas)
        }
        .onAppear {
            if existing == nil, book != nil { writingLine = true }
        }
        .sheet(isPresented: $choosingBook) {
            BookPicker(title: "Which book is it from?") { picked in
                chosen = picked
                writingLine = true
            }
        }
        .confirmationDialog("Delete this quote?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: delete)
            Button("Keep", role: .cancel) {}
        }
        .sensoryFeedback(.success, trigger: saves)
        .dsScreen()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DS.Colors.canvas)
        .dsColorScheme()
    }

    // MARK: Sections

    private var header: some View {
        HStack(alignment: .center, spacing: DS.Space.s) {
            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                Eyebrow(existing == nil ? "Keep a line" : "Edit quote")
                Text(chosen?.title ?? String(localized: "From any book"))
                    .font(DS.Typography.heading)
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            CircleButton(systemImage: "xmark", label: "Close") { dismiss() }
        }
    }

    private var from: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionHeader("From")
            Button {
                choosingBook = true
            } label: {
                HStack(spacing: DS.Space.m) {
                    if let chosen {
                        BookCover(book: chosen, size: .small)
                        VStack(alignment: .leading, spacing: DS.Space.xxs) {
                            Text(chosen.title)
                                .font(DS.Typography.heading)
                                .foregroundStyle(DS.Colors.ink)
                                .lineLimit(2)
                            if let byline = chosen.byline {
                                Text(byline)
                                    .font(DS.Typography.meta)
                                    .foregroundStyle(DS.Colors.inkSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Hint("change")
                    } else {
                        Text("Choose a book")
                            .font(DS.Typography.label)
                            .foregroundStyle(DS.Colors.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(DS.Colors.inkTertiary)
                    }
                }
                .padding(chosen == nil ? DS.Space.m : DS.Space.s)
                .frame(minHeight: DS.Size.touch)
                .dsOutline()
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private var line: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionHeader("The line")
            ComposerField(placeholder: "Type or paste it, word for word", text: $text, focus: $writingLine, label: "Quote", lines: 4...12)
            HStack(spacing: DS.Space.xs) {
                Text("Page")
                    .font(DS.Typography.label)
                    .foregroundStyle(DS.Colors.inkSecondary)
                TextField("", text: $page, prompt: Text(verbatim: "—").foregroundStyle(DS.Colors.inkTertiary))
                    .font(DS.Typography.field)
                    .foregroundStyle(DS.Colors.ink)
                    .keyboardType(.numbersAndPunctuation)
                    .frame(width: 72)
                    .padding(.horizontal, DS.Space.s)
                    .frame(minHeight: DS.Size.touch - 8)
                    .dsOutline()
                    .accessibilityLabel("Page")
                Spacer()
            }
        }
    }

    // MARK: Saving

    private func save() {
        guard let chosen else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let pageTrimmed = page.trimmingCharacters(in: .whitespaces)
        let noteTrimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing {
            existing.text = trimmed
            existing.page = pageTrimmed
            existing.note = noteTrimmed
        } else {
            modelContext.insert(Quote(book: chosen, text: trimmed, page: pageTrimmed, note: noteTrimmed))
        }
        Library.save(modelContext)
        saves += 1
        dismiss()
    }

    private func delete() {
        guard let existing else { return }
        let context = modelContext
        onDelete?()
        dismiss()
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            context.delete(existing)
            Library.save(context)
        }
    }
}
