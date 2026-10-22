import SwiftUI

/// Which moment the reader opened. `moment == nil` is a free change, off the map.
struct MomentChoice: Identifiable, Hashable {
    let moment: Moment?
    var id: String { moment?.id ?? "free" }
}

/// One turning point: what happened in the book, and what could happen instead.
/// The reader picks an alternative (or writes their own) and rewrites from here.
struct MomentSheet: View {
    let book: Book
    let map: StoryMap
    let moment: Moment?
    let onRewrite: (StoryRequest) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int?
    @State private var writingOwn = false
    @State private var custom = ""
    @State private var notice = StoryEngine.unavailableNotice
    @FocusState private var composing: Bool

    private var change: String? {
        if writingOwn || moment == nil {
            let text = custom.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        }
        guard let moment, let selection, moment.alternatives.indices.contains(selection) else { return nil }
        return moment.alternatives[selection]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    if let moment {
                        momentContent(moment)
                    } else {
                        freeContent
                    }
                    if let notice {
                        InlineNotice(symbol: notice.symbol, title: notice.title, message: notice.message)
                    }
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.top, DS.Space.xs)
                .padding(.bottom, DS.Space.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaBar(edge: .bottom) { actionBar }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
            .dsScreen()
        }
        .tint(DS.Colors.ink)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DS.Colors.canvas)
        .dsColorScheme()
    }

    // MARK: Sections

    @ViewBuilder private func momentContent(_ moment: Moment) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Eyebrow(verbatim: moment.chapter)
            Text(moment.title)
                .dsDisplay(DS.Typography.title)
        }

        PageCard {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Eyebrow("In the book")
                Text(moment.happened).dsReading()
                // A few lines of the scene itself, when the book has a guide.
                if let excerpt = Catalog.entry(for: book)?.guide?.excerpt(for: moment) {
                    QuoteBlock(text: excerpt)
                        .padding(.top, DS.Space.xs)
                        .accessibilityLabel("From the original: \(excerpt)")
                }
            }
        }

        VStack(alignment: .leading, spacing: DS.Space.s) {
            Eyebrow("What if, instead…")
            // Each alternative branches off the moment, like a path forking.
            VStack(spacing: 0) {
                ForEach(Array(moment.alternatives.enumerated()), id: \.offset) { index, alternative in
                    let isSelected = !writingOwn && selection == index
                    BranchRow(isLast: false, isLit: isSelected, seed: index) {
                        ChoiceRow(text: alternative, isSelected: isSelected) {
                            withAnimation(DS.Motion.quick) {
                                writingOwn = false
                                selection = index
                            }
                            composing = false
                        }
                    }
                }
                BranchRow(isLast: true, isLit: writingOwn, seed: 9) {
                    ChoiceRow(
                        text: String(localized: "Something else"),
                        isSelected: writingOwn,
                        systemImage: "square.and.pencil"
                    ) {
                        withAnimation(DS.Motion.quick) { writingOwn = true }
                        composing = true
                    }
                }
            }
            if writingOwn {
                ComposerField(
                    placeholder: String(localized: "Describe what happens instead."),
                    text: $custom,
                    focus: $composing
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder private var freeContent: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Eyebrow("Off the map")
            Text("What changes?")
                .dsDisplay(DS.Typography.title)
            Text("Describe one thing that happens differently in \(book.title).")
                .font(DS.Typography.blurb)
                .foregroundStyle(DS.Colors.inkSecondary)
        }
        ComposerField(
            placeholder: String(localized: "A character makes a different choice…"),
            text: $custom,
            focus: $composing
        )
        .onAppear { composing = true }
    }

    private var actionBar: some View {
        VStack(spacing: DS.Space.xs) {
            if let change {
                // Say it back in one line, so a misunderstanding is caught before writing.
                Text(confirmation(change))
                    .font(DS.Typography.quoteSmall)
                    .foregroundStyle(DS.Colors.inkSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
            PrimaryButton("Rewrite from here", systemImage: "arrow.right") {
                guard let change else { return }
                let guide = Catalog.entry(for: book)?.guide
                onRewrite(StoryRequest(
                    book: book,
                    moment: moment,
                    change: change,
                    premise: map.premise,
                    earlierMoments: moment.map { map.moments(before: $0) } ?? [],
                    grounding: moment.map { guide?.grounding(for: $0) } ?? guide?.grounding(forChange: change)
                ))
                dismiss()
            }
            .disabled(change == nil || notice != nil)
        }
        .animation(DS.Motion.quick, value: change)
        .padding(.horizontal, DS.Space.screen)
        .padding(.bottom, DS.Space.xs)
    }

    private func confirmation(_ change: String) -> String {
        if let moment {
            return "\(moment.chapter) · Instead: \(change)"
        }
        return "In this version: \(change)"
    }
}
