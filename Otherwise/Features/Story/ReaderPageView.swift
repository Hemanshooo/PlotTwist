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
                DS.Colors.surface
            }
            // Gutter: the page curves into the spine.
            LinearGradient(colors: [DS.Colors.fold, DS.Colors.surface.opacity(0)], startPoint: .leading, endPoint: .trailing)
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
                Text(verbatim: Roman.numeral(i + 1))
                    .font(DS.Typography.chapter)
                    .foregroundStyle(edition.ink)
                if !chapter.heading.isEmpty {
                    Text(chapter.heading)
                        .font(DS.Typography.chapter)
                        .foregroundStyle(DS.Colors.ink)
                        .multilineTextAlignment(.center)
                }
                Ornament(color: edition.ink)
                    .padding(.bottom, DS.Space.xs)
                if chapter.text.isEmpty {
                    WritingIndicator()
                } else {
                    RaisedCapText(text: chapter.text, ink: edition.ink)
                }
            }
        }
    }

    private var ending: some View {
        VStack(spacing: DS.Space.m) {
            Eyebrow("How it ends", color: edition.ink)
            Ornament(color: edition.ink)
                .padding(.bottom, DS.Space.xs)
            RaisedCapText(text: model.story.ending, ink: edition.ink)
        }
    }

    private var writing: some View {
        VStack(spacing: DS.Space.m) {
            Image(systemName: "pencil.line")
                .font(DS.Typography.symbol)
                .foregroundStyle(edition.ink)
                .symbolEffect(.pulse, options: .repeating)
            WritingIndicator(label: "Writing the next page")
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
            Eyebrow("Plot Twist", color: model.edition.ink)
            Text(model.story.title.isEmpty ? "An untitled version" : model.story.title)
                .font(DS.Typography.display)
                .foregroundStyle(DS.Colors.ink)
                .multilineTextAlignment(.center)
                .redacted(reason: model.story.title.isEmpty ? .placeholder : [])
                .contentTransition(.opacity)
            Ornament(color: model.edition.ink)
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
            Label("Turn the page", systemImage: "hand.draw")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.inkTertiary)
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
                Eyebrow(verbatim: chapter, color: model.edition.ink)
            }
            if let happened = model.momentHappened {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Eyebrow("In the book")
                    Text(happened)
                        .font(DS.Typography.reading)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .lineSpacing(DS.Leading.reading)
                        .strikethrough(true, color: model.edition.ink.opacity(0.6))
                }
            }
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Eyebrow("In this version", color: model.edition.ink)
                QuoteBlock(text: model.change, ink: model.edition.ink)
            }
            Ornament(color: model.edition.ink)
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

    private var ink: Color { model.edition.ink }

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
                        .foregroundStyle(ink)
                    Ornament(color: ink)
                    Text("Imagined on this iPhone with Apple Intelligence. Not part of the original book.")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.inkSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(DS.Leading.relaxed)
                    PrimaryButton(
                        "Change another moment",
                        systemImage: "point.topleft.down.to.point.bottomright.curvepath",
                        edition: model.edition,
                        action: onChangeAnother
                    )
                    .padding(.top, DS.Space.xs)
                    ShareLink(item: model.shareText) {
                        Label("Share this version", systemImage: "square.and.arrow.up")
                            .font(DS.Typography.label)
                            .foregroundStyle(DS.Colors.ink)
                            .frame(minHeight: DS.Size.touch)
                    }
                }
            }
            .padding(DS.Space.l)
            .background(DS.Colors.surface)
            // A bookplate's double rule.
            .overlay(Rectangle().strokeBorder(ink, lineWidth: 1).padding(4))
            .overlay(Rectangle().strokeBorder(ink.opacity(0.4), lineWidth: DS.Size.hairline))
            .dsPageShadow()
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
