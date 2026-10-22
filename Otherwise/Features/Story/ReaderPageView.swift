import SwiftUI

/// One printed page of the alternate version: running head, content, folio,
/// and a soft gutter shadow along the spine.
struct ReaderPageView: View {
    let model: ReaderModel
    let index: Int
    let onChangeAnother: () -> Void
    let onRetry: () -> Void

    private var edition: Edition { model.edition }

    var body: some View {
        let page = model.page(at: index)
        ZStack(alignment: .leading) {
            if page == .colophon {
                // The book closes on its back endpaper.
                EditionPattern(edition: edition, tile: 20, intensity: 0.55)
            } else {
                DS.Colors.page
            }
            // Gutter: the page curves into the spine.
            LinearGradient(colors: [DS.Colors.shadow.opacity(0.12), DS.Colors.shadow.opacity(0)], startPoint: .leading, endPoint: .trailing)
                .frame(width: DS.Space.l)
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                runningHead(for: page)
                    .padding(.top, DS.Space.s)
                content(for: page)
                    .frame(maxWidth: DS.Space.readingWidth, maxHeight: .infinity)
                    .frame(maxWidth: .infinity)
                Text(verbatim: "\(index + 1)")
                    .font(DS.Typography.folio)
                    .foregroundStyle(DS.Colors.inkTertiary)
                    .padding(.bottom, DS.Space.l)
                    .opacity(page == .colophon ? 0 : 1)
                    .accessibilityLabel(Text("Page \(index + 1)"))
            }
        }
    }

    // MARK: Chrome

    @ViewBuilder private func runningHead(for page: ReaderModel.Page) -> some View {
        switch page {
        case .title, .colophon:
            Text(verbatim: " ").font(DS.Typography.folio)
        default:
            Text(model.story.title.isEmpty ? model.book.title : model.story.title)
                .font(DS.Typography.folio)
                .foregroundStyle(DS.Colors.inkTertiary)
                .lineLimit(1)
                .padding(.horizontal, DS.Space.page)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder private func content(for page: ReaderModel.Page) -> some View {
        switch page {
        case .title:
            TitlePage(model: model)
        case .divergence:
            scrolling { DivergencePage(model: model) }
        case .chapter(let i):
            scrolling { chapter(i) }
        case .ending:
            scrolling { ending }
        case .writing:
            writing
        case .colophon:
            ColophonPage(model: model, onChangeAnother: onChangeAnother, onRetry: onRetry)
        }
    }

    private func scrolling<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ScrollView {
            content()
                .padding(.horizontal, DS.Space.page)
                .padding(.vertical, DS.Space.l)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }

    // MARK: Pages

    @ViewBuilder private func chapter(_ i: Int) -> some View {
        let chapters = model.story.chapters
        if chapters.indices.contains(i) {
            let chapter = chapters[i]
            VStack(spacing: DS.Space.m) {
                Eyebrow("Chapter \(Roman.numeral(i + 1))", color: DS.Colors.bloom)
                if !chapter.heading.isEmpty {
                    Text(chapter.heading)
                        .font(DS.Typography.chapter)
                        .tracking(DS.Tracking.display)
                        .foregroundStyle(DS.Colors.pageInk)
                        .multilineTextAlignment(.center)
                }
                Flourish(width: 96)
                    .padding(.bottom, DS.Space.xs)
                if chapter.text.isEmpty {
                    WritingIndicator()
                } else {
                    RaisedCapText(text: chapter.text)
                }
            }
        }
    }

    private var ending: some View {
        VStack(spacing: DS.Space.m) {
            Eyebrow("How it ends", color: DS.Colors.bloom)
            Flourish(width: 96)
                .padding(.bottom, DS.Space.xs)
            RaisedCapText(text: model.story.ending)
        }
    }

    private var writing: some View {
        VStack(spacing: DS.Space.m) {
            Image(systemName: "pencil.line")
                .font(DS.Typography.symbol)
                .foregroundStyle(DS.Colors.bloom)
                .symbolEffect(.pulse, options: .repeating)
            WritingIndicator(label: "writing the next page")
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Title page

private struct TitlePage: View {
    let model: ReaderModel

    var body: some View {
        VStack(spacing: DS.Space.l) {
            Spacer()
            Eyebrow("Plot Twist", color: DS.Colors.bloom)
            Text(model.story.title.isEmpty ? "An untitled version" : model.story.title)
                .font(DS.Typography.display)
                .tracking(DS.Tracking.display)
                .foregroundStyle(DS.Colors.pageInk)
                .multilineTextAlignment(.center)
                // A placeholder only while the title is still being written.
                .redacted(reason: model.story.title.isEmpty && model.phase == .writing ? .placeholder : [])
                .contentTransition(.opacity)
            Growing(delay: 0.2) { Flourish(width: 132, progress: $0) }
            VStack(spacing: DS.Space.xxs) {
                Text("after \(model.book.title)")
                    .font(DS.Typography.quote)
                    .foregroundStyle(DS.Colors.inkSecondary)
                if let author = model.book.author {
                    Text(author)
                        .font(DS.Typography.meta)
                        .foregroundStyle(DS.Colors.inkTertiary)
                }
            }
            .multilineTextAlignment(.center)
            Spacer()
            Hint("turn the page →")
        }
        .padding(.horizontal, DS.Space.page)
        .padding(.bottom, DS.Space.s)
        .animation(DS.Motion.reveal, value: model.story.title)
    }
}

// MARK: - Divergence page

/// What happened, struck through like an editor's correction, and what happens now.
private struct DivergencePage: View {
    let model: ReaderModel

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            if let chapter = model.momentChapter {
                Eyebrow(verbatim: chapter, color: DS.Colors.bloom)
            }
            if let happened = model.momentHappened {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Eyebrow("In the book")
                    Text(happened)
                        .font(DS.Typography.reading)
                        .foregroundStyle(DS.Colors.pageInk.opacity(0.55))
                        .lineSpacing(DS.Leading.reading)
                        .strikethrough(true, color: DS.Colors.bloom)
                }
            }
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Eyebrow("In this version", color: DS.Colors.bloom)
                QuoteBlock(text: model.change)
            }
            Flourish(width: 96)
                .frame(maxWidth: .infinity)
                .padding(.top, DS.Space.s)
        }
        .padding(.trailing, DS.Space.l)
    }
}

// MARK: - Colophon

/// The last page: a bookplate on the back endpaper, saying what this is
/// and where to go next.
private struct ColophonPage: View {
    let model: ReaderModel
    let onChangeAnother: () -> Void
    let onRetry: () -> Void


    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: DS.Space.m) {
                if case .failed(let notice) = model.phase {
                    MessageView(
                        symbol: notice.symbol,
                        title: LocalizedStringKey(notice.title),
                        message: LocalizedStringKey(notice.message)
                    ) {
                        SecondaryButton("Try again", systemImage: "arrow.clockwise", action: onRetry)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("The End")
                        .font(DS.Typography.title)
                        .foregroundStyle(DS.Colors.pageInk)
                    Growing(delay: 0.2) { Flourish(width: 120, progress: $0) }
                    Text("Imagined on this iPhone with Apple Intelligence. Not part of the original book.")
                        .font(DS.Typography.meta)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(DS.Leading.relaxed)
                    PrimaryButton(
                        "Change another moment",
                        systemImage: "arrow.right",
                        action: onChangeAnother
                    )
                    .padding(.top, DS.Space.xs)
                    ShareLink(item: model.shareText) {
                        Label("Share this version", systemImage: "square.and.arrow.up")
                            .font(DS.Typography.label)
                            .foregroundStyle(DS.Colors.pageInk)
                            .frame(minHeight: DS.Size.touch)
                    }
                }
            }
            .padding(DS.Space.l)
            .background(DS.Colors.page)
            // A bookplate's double rule.
            .overlay(Rectangle().strokeBorder(DS.Colors.bloom, lineWidth: 1).padding(4))
            .overlay(Rectangle().strokeBorder(DS.Colors.hairline, lineWidth: DS.Size.hairline))
            .shadow(color: DS.Colors.shadow.opacity(0.14), radius: 20, x: 0, y: 10)
            Spacer()
        }
        .padding(.horizontal, DS.Space.page)
    }
}

// MARK: - Roman numerals

enum Roman {
    static func numeral(_ number: Int) -> String {
        let table: [(Int, String)] = [(10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
        var remaining = number
        var result = ""
        for (value, numeral) in table {
            while remaining >= value {
                result += numeral
                remaining -= value
            }
        }
        return result
    }
}
