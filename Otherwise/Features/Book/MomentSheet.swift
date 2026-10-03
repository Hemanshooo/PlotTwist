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
    let edition: Edition
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
        .tint(edition.ink)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DS.Colors.canvas)
    }

    // MARK: Sections

    @ViewBuilder private func momentContent(_ moment: Moment) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Eyebrow(verbatim: moment.chapter, color: edition.ink)
            Text(moment.title)
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.ink)
        }

        PageCard {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Eyebrow("In the book")
                Text(moment.happened).dsReading()
            }
        }

        VStack(alignment: .leading, spacing: DS.Space.s) {
            Eyebrow("What if, instead…", color: edition.ink)
            ForEach(Array(moment.alternatives.enumerated()), id: \.offset) { index, alternative in
                ChoiceRow(text: alternative, isSelected: !writingOwn && selection == index, ink: edition.ink) {
                    withAnimation(DS.Motion.quick) {
                        writingOwn = false
                        selection = index
                    }
                    composing = false
                }
            }
            ChoiceRow(
                text: String(localized: "Something else"),
                isSelected: writingOwn,
                ink: edition.ink,
                systemImage: writingOwn ? "checkmark.circle.fill" : "square.and.pencil"
            ) {
                withAnimation(DS.Motion.quick) { writingOwn = true }
                composing = true
            }
            if writingOwn {
                ComposerField(
                    placeholder: String(localized: "Describe what happens instead."),
                    text: $custom,
                    focus: $composing,
                    tint: edition.ink
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder private var freeContent: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Eyebrow("Off the map", color: edition.ink)
            Text("What changes?")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.ink)
            Text("Describe one thing that happens differently in \(book.title).")
                .font(DS.Typography.meta)
                .foregroundStyle(DS.Colors.inkSecondary)
        }
        ComposerField(
            placeholder: String(localized: "A character makes a different choice…"),
            text: $custom,
            focus: $composing,
            tint: edition.ink
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
            PrimaryButton("Rewrite from here", systemImage: "book.pages", edition: edition) {
                guard let change else { return }
                onRewrite(StoryRequest(
                    book: book,
                    moment: moment,
                    change: change,
                    premise: map.premise,
                    earlierMoments: moment.map { map.moments(before: $0) } ?? []
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
