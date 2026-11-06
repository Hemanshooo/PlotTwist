import SwiftUI

/// A quote in your commonplace book: a dog-eared slip of page, a large
/// opening quotation mark in the bloom colour, the line in the reading face,
/// and who wrote it in mono capitals beneath.
struct QuoteCard: View {
    let quote: Quote

    var body: some View {
        PageCard {
            VStack(alignment: .leading, spacing: DS.Space.s) {
                Text(verbatim: "“")
                    .font(DS.Typography.quoteMark)
                    .foregroundStyle(DS.Colors.bloom)
                    .frame(height: 34, alignment: .top)
                    .padding(.bottom, -DS.Space.xxs)
                    .accessibilityHidden(true)
                Text(quote.text)
                    .font(DS.Typography.commonplace)
                    .foregroundStyle(DS.Colors.pageInk)
                    .lineSpacing(DS.Leading.relaxed)
                    .multilineTextAlignment(.leading)
                    .lineLimit(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(alignment: .center, spacing: DS.Space.xs) {
                    Rectangle()
                        .fill(DS.Colors.stem)
                        .frame(width: DS.Space.l, height: DS.Size.stem)
                    VStack(alignment: .leading, spacing: 2) {
                        if let author = quote.author {
                            Eyebrow(verbatim: author)
                        }
                        Text(quote.page.isEmpty ? quote.title : "\(quote.title) · p. \(quote.page)")
                            .font(DS.Typography.quoteSmall)
                            .foregroundStyle(DS.Colors.inkSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(.top, DS.Space.xs)
            }
            .padding(.vertical, DS.Space.xs)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("“\(quote.text)” \(quote.citation)"))
    }
}

/// A quote on its book's page: a rule in the bloom colour, the line in
/// italics, and the page in small mono.
struct QuoteSnippet: View {
    let quote: Quote

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.s) {
            Capsule()
                .fill(DS.Colors.bloom)
                .frame(width: DS.Size.rule)
            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                Text(quote.text)
                    .font(DS.Typography.quote)
                    .foregroundStyle(DS.Colors.ink)
                    .lineSpacing(DS.Leading.relaxed)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
                if !quote.page.isEmpty {
                    Hint("p. \(quote.page)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, DS.Space.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Share art

/// The shapes a quote can be shared in.
enum QuoteFormat: String, CaseIterable, Identifiable {
    /// 4:5, for a feed.
    case post
    /// 9:16, for a story.
    case story

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .post: "Post"
        case .story: "Story"
        }
    }

    /// Laid out at this size in points, rendered at 3×: 1080 × 1350 and 1080 × 1920.
    var size: CGSize {
        switch self {
        case .post: CGSize(width: 360, height: 450)
        case .story: CGSize(width: 360, height: 640)
        }
    }
}

/// A quote set as a card to share, in any of the palettes: the line large in
/// the reading face, a quotation mark and a rose sprig in the garden's two
/// colours, who wrote it in mono capitals, and the wordmark small at the foot.
/// Drawn from the palette it's given, not the app's, so you can share in any room.
struct QuoteArt: View {
    let quote: Quote
    let palette: Palette
    let format: QuoteFormat

    private var scheme: Palette.Scheme { palette.scheme }

    /// The longer the line, the smaller the type.
    private var textSize: CGFloat {
        let length = quote.text.count
        let story = format == .story
        switch length {
        case ..<90: return story ? 32 : 30
        case ..<180: return story ? 26 : 24
        case ..<320: return story ? 21 : 19
        default: return story ? 18 : 16
        }
    }

    var body: some View {
        let size = format.size
        ZStack(alignment: .topLeading) {
            scheme.canvas

            CornerSprig(ink: GardenInk(stem: scheme.stem, bloom: scheme.bloom, petal: scheme.petal, ground: scheme.canvas))
                .frame(width: size.width * 0.42, height: size.height * 0.36)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "“")
                    .font(.custom(DS.Typography.Face.display.rawValue, fixedSize: 110))
                    .foregroundStyle(scheme.bloom)
                    .frame(height: 64, alignment: .top)
                    .padding(.bottom, 4)
                Text(quote.text)
                    .font(.custom(DS.Typography.Face.text.rawValue, fixedSize: textSize))
                    .foregroundStyle(scheme.ink)
                    .lineSpacing(textSize * 0.28)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if format == .story { Spacer(minLength: 24) } else { Spacer(minLength: 18) }
                VStack(alignment: .leading, spacing: 5) {
                    Rectangle()
                        .fill(scheme.stem)
                        .frame(width: 28, height: 1.8)
                        .padding(.bottom, 6)
                    if let author = quote.author {
                        Text(author.uppercased())
                            .font(.custom(DS.Typography.Face.monoMedium.rawValue, fixedSize: 10))
                            .tracking(1.6)
                            .foregroundStyle(scheme.inkSecondary)
                    }
                    Text(quote.page.isEmpty ? quote.title : "\(quote.title), p. \(quote.page)")
                        .font(.custom(DS.Typography.Face.textItalic.rawValue, fixedSize: 14))
                        .foregroundStyle(scheme.inkSecondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: size.width * 0.6, alignment: .leading)
                Text(verbatim: "Endpaper")
                    .font(.custom(DS.Typography.Face.display.rawValue, fixedSize: 15))
                    .foregroundStyle(scheme.inkTertiary)
                    .padding(.top, 22)
            }
            .padding(.horizontal, 30)
            .padding(.top, format == .story ? 84 : 34)
            .padding(.bottom, 26)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

/// A rose sprig rising from the bottom-right corner: a curving stem, leaves,
/// a bud and two roses. Drawn in the colours it's given.
private struct CornerSprig: View {
    let ink: GardenInk

    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let points = [
                CGPoint(x: w * 1.02, y: h * 1.02),
                CGPoint(x: w * 0.78, y: h * 0.8),
                CGPoint(x: w * 0.7, y: h * 0.52),
                CGPoint(x: w * 0.52, y: h * 0.3),
                CGPoint(x: w * 0.36, y: h * 0.16),
            ]
            let stem = Botany.stem(through: points)
            context.drawStem(stem, ink: ink, width: 2)
            let branch = Botany.stem(through: [
                CGPoint(x: w * 0.72, y: h * 0.6),
                CGPoint(x: w * 0.84, y: h * 0.44),
                CGPoint(x: w * 0.84, y: h * 0.3),
            ])
            context.drawStem(branch, ink: ink, width: 1.6)
            context.drawLeaf(at: CGPoint(x: w * 0.8, y: h * 0.82), angle: .degrees(-160), length: w * 0.2, ink: ink)
            context.drawLeaf(at: CGPoint(x: w * 0.72, y: h * 0.62), angle: .degrees(-40), length: w * 0.17, ink: ink)
            context.drawLeaf(at: CGPoint(x: w * 0.6, y: h * 0.4), angle: .degrees(-150), length: w * 0.16, ink: ink)
            context.drawLeaf(at: CGPoint(x: w * 0.84, y: h * 0.46), angle: .degrees(-20), length: w * 0.12, ink: ink)
            context.drawRose(at: CGPoint(x: w * 0.34, y: h * 0.14), size: w * 0.24, seed: 5, ink: ink)
            context.drawRose(at: CGPoint(x: w * 0.84, y: h * 0.27), size: w * 0.17, seed: 2, ink: ink)
            context.drawBud(at: CGPoint(x: w * 0.52, y: h * 0.3), angle: .degrees(-120), length: w * 0.1, ink: ink)
        }
        .accessibilityHidden(true)
    }
}
