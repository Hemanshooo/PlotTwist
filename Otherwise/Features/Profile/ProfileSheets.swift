import SwiftUI
import SwiftData

// MARK: - About you

/// Your name, a line about you, and how many books you mean to read this year.
struct ProfileEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var bio = ""
    @State private var goal = 0
    @FocusState private var naming: Bool
    @FocusState private var describing: Bool

    private var year: Int { Calendar.current.component(.year, from: .now) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {
                HStack {
                    Eyebrow("About you")
                    Spacer()
                    CircleButton(systemImage: "xmark", label: "Close") { dismiss() }
                }
                VStack(alignment: .leading, spacing: DS.Space.s) {
                    SectionHeader("Name")
                    TextField("Name", text: $name, prompt: Text("Your name").foregroundStyle(DS.Colors.inkTertiary))
                        .font(DS.Typography.title)
                        .foregroundStyle(DS.Colors.ink)
                        .focused($naming)
                        .submitLabel(.next)
                        .onSubmit { describing = true }
                }
                VStack(alignment: .leading, spacing: DS.Space.s) {
                    SectionHeader(title: "A line about you") { Hint("optional") }
                    ComposerField(placeholder: "What you read, and why", text: $bio, focus: $describing, label: "About you", lines: 2...4)
                }
                VStack(alignment: .leading, spacing: DS.Space.s) {
                    SectionHeader(title: "Reading goal") { Hint("books in \(String(year))") }
                    HStack(spacing: DS.Space.m) {
                        Text(verbatim: goal > 0 ? "\(goal)" : "—")
                            .font(DS.Typography.statNumeral)
                            .foregroundStyle(goal > 0 ? DS.Colors.ink : DS.Colors.inkTertiary)
                            .contentTransition(.numericText(value: Double(goal)))
                            .frame(minWidth: 72, alignment: .leading)
                        Spacer()
                        Stepper("Reading goal", value: $goal, in: 0...365, step: goal >= 20 ? 5 : 1)
                            .labelsHidden()
                    }
                    Hint(goal == 0 ? "no goal · your year still counts every book" : "about \(max(1, 52 * 7 / max(goal, 1))) days a book")
                }
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.top, DS.Space.l)
            .padding(.bottom, DS.Space.xxl)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton("Save", action: save)
                .padding(.horizontal, DS.Space.screen)
                .padding(.vertical, DS.Space.s)
                .background(DS.Colors.canvas)
        }
        .onAppear {
            let profile = Profile.current(in: modelContext)
            name = profile.name
            bio = profile.bio
            goal = profile.readingGoal
        }
        .animation(DS.Motion.quick, value: goal)
        .dsScreen()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DS.Colors.canvas)
        .dsColorScheme()
    }

    private func save() {
        let profile = Profile.current(in: modelContext)
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.readingGoal = goal
        Library.save(modelContext)
        dismiss()
    }
}

// MARK: - Favourite four

/// Choosing your favourite four: the four places at the top (tap one to take
/// it out), and your books beneath to fill them.
struct FavouritesEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var books: [Book] = []
    @State private var picking = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            HStack {
                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    Eyebrow("Favourite four")
                    Text("The books that made you")
                        .dsDisplay(DS.Typography.heading)
                }
                Spacer()
                CircleButton(systemImage: "xmark", label: "Close") { dismiss() }
            }

            HStack(spacing: DS.Size.favouriteGap) {
                ForEach(0..<4, id: \.self) { index in
                    Group {
                        if index < books.count {
                            Button {
                                withAnimation(DS.Motion.standard) { _ = books.remove(at: index) }
                            } label: {
                                ScaledBookCover(book: books[index])
                                    .overlay(alignment: .topTrailing) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(DS.Colors.onInk)
                                            .frame(width: 20, height: 20)
                                            .background(DS.Colors.ink, in: Circle())
                                            .offset(x: 6, y: -6)
                                    }
                            }
                            .buttonStyle(PressableButtonStyle())
                            .accessibilityLabel(Text("Remove \(books[index].title)"))
                        } else {
                            Button {
                                picking = true
                            } label: {
                                RoundedRectangle(cornerRadius: DS.Radius.cover, style: .continuous)
                                    .strokeBorder(DS.Colors.inkTertiary, style: StrokeStyle(lineWidth: DS.Size.hairline, dash: [4, 4]))
                                    .overlay {
                                        Text(verbatim: "\(index + 1)")
                                            .font(DS.Typography.heading)
                                            .foregroundStyle(DS.Colors.inkTertiary)
                                    }
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PressableButtonStyle())
                            .accessibilityLabel(Text("Choose favourite \(index + 1)"))
                        }
                    }
                    .aspectRatio(2 / 3, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                }
            }

            Hint(books.count < 4 ? "tap an empty place to choose a book · tap a cover to take it out" : "tap a cover to take it out")

            Spacer(minLength: 0)

            PrimaryButton("Save", action: save)
        }
        .padding(.horizontal, DS.Space.screen)
        .padding(.top, DS.Space.l)
        .padding(.bottom, DS.Space.s)
        .onAppear { books = Profile.current(in: modelContext).favourites }
        .sheet(isPresented: $picking) {
            BookPicker(title: "Choose a favourite", excluded: Set(books.map(\.id))) { book in
                withAnimation(DS.Motion.standard) {
                    if books.count < 4 { books.append(book) }
                }
            }
        }
        .dsScreen()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DS.Colors.canvas)
        .dsColorScheme()
    }

    private func save() {
        Profile.current(in: modelContext).favourites = books
        Library.save(modelContext)
        dismiss()
    }
}

// MARK: - A shelf, as a list

/// Every book on one shelf, as an index.
struct ShelfListView: View {
    let status: ShelfStatus

    @Query(sort: \ShelfEntry.updatedAt, order: .reverse) private var shelf: [ShelfEntry]

    var body: some View {
        let books = shelf.filter { $0.status == status }
        Group {
            if books.isEmpty {
                MessageView(title: "Nothing here yet", message: "Books you put on this shelf will be listed here.")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ScreenTitle(title: status.title, detail: "^[\(books.count) book](inflect: true)")
                            .padding(.bottom, DS.Space.m)
                        Hairline()
                        ForEach(books) { entry in
                            NavigationLink(value: entry.book) {
                                ShelfRow(entry: entry)
                            }
                            .buttonStyle(PressableButtonStyle())
                            Hairline()
                        }
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, DS.Space.s)
                    .padding(.bottom, DS.Space.xxl)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .dsScreen()
    }
}

/// A book on a shelf: cover, title, author, and its roses, heart or progress.
private struct ShelfRow: View {
    let entry: ShelfEntry

    var body: some View {
        HStack(spacing: DS.Space.m) {
            BookCover(book: entry.book, size: .small)
            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                Text(entry.title)
                    .font(DS.Typography.heading)
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let byline = entry.book.byline {
                    Text(byline)
                        .font(DS.Typography.meta)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineLimit(1)
                }
                HStack(spacing: DS.Space.xs) {
                    if entry.status == .reading {
                        Hint(verbatim: String(localized: "\(Int((entry.progress * 100).rounded())) percent read"))
                    }
                    if entry.rating > 0 { RoseRating(value: entry.rating) }
                    if entry.liked { HeartMark() }
                }
                .padding(.top, 2)
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
