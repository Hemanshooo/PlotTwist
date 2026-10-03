import SwiftUI

/// A clothbound cover in the book's edition: patterned cloth, a stamped label
/// panel with the title and author, and a hinge near the spine.
/// Three fixed sizes, always 2:3.
struct BookCover: View {
    enum Size {
        case small, medium, large, hero

        var dimensions: CGSize {
            switch self {
            case .small: DS.Size.coverSmall
            case .medium: DS.Size.coverMedium
            case .large: DS.Size.coverLarge
            case .hero: DS.Size.coverHero
            }
        }

        /// Pattern tile scales with the book, like a real stamping die.
        var tile: CGFloat {
            switch self {
            case .small: 9
            case .medium: 14
            case .large: 18
            case .hero: 26
            }
        }

        // Cover lettering is part of the illustration, so it uses fixed sizes
        // (like a printed cover) rather than Dynamic Type.
        var titleSize: CGFloat {
            switch self {
            case .small: 6
            case .medium: 11
            case .large: 15
            case .hero: 22
            }
        }

        /// Width available to the title inside the label panel.
        var titleWidth: CGFloat {
            dimensions.width - labelInset * 2 - (isGenerous ? DS.Space.s : DS.Space.xs) * 2 - 10
        }

        /// Large and hero covers get roomier label panels.
        var isGenerous: Bool {
            self == .large || self == .hero
        }

        var authorFont: Font {
            switch self {
            case .small: DS.Typography.stamp(5)
            case .medium: DS.Typography.stamp(7)
            case .large: DS.Typography.stamp(9)
            case .hero: DS.Typography.stamp(12)
            }
        }

        var labelInset: CGFloat {
            switch self {
            case .small: 4
            case .medium: 7
            case .large: 14
            case .hero: 22
            }
        }
    }

    let book: Book
    var size: Size = .medium

    private var edition: Edition { Edition.of(book) }

    var body: some View {
        ZStack {
            EditionPattern(edition: edition, tile: size.tile, intensity: 0.6)
            if size != .small {
                label
            }
            CoverHinge(width: size.dimensions.width)
        }
        .frame(width: size.dimensions.width, height: size.dimensions.height)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.cover, style: .continuous))
        .dsCoverShadow()
        .accessibilityHidden(true)
    }

    private var label: some View {
        VStack(spacing: size.isGenerous ? DS.Space.xs : DS.Space.xxs + 1) {
            // Set the title in balanced lines and size it so the longest line fits:
            // words never break, as on a real stamped cover.
            let lines = CoverTitle.lines(book.title)
            let longest = CGFloat(lines.map(\.count).max() ?? 1)
            let fitted = min(size.titleSize, size.titleWidth / (longest * 0.74))
            VStack(spacing: 1) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(verbatim: line)
                        .font(DS.Typography.stamp(fitted))
                        .tracking(fitted * 0.08)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            Ornament(color: edition.foilColor, compact: !size.isGenerous)
            if let author = book.author {
                Text(author.uppercased())
                    .font(size.authorFont)
                    .tracking(DS.Tracking.stamp * 0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .foregroundStyle(edition.foilColor)
        .padding(.vertical, size.isGenerous ? DS.Space.m : DS.Space.s)
        .padding(.horizontal, size.isGenerous ? DS.Space.s : DS.Space.xs)
        .frame(maxWidth: .infinity)
        .background(edition.clothColor)
        // A double rule, as stamped on a label panel.
        .overlay(Rectangle().strokeBorder(edition.foilColor, lineWidth: 1).padding(3))
        .overlay(Rectangle().strokeBorder(edition.foilColor.opacity(0.5), lineWidth: 0.5))
        .padding(.horizontal, size.labelInset)
        .padding(.leading, size.dimensions.width * 0.04)
    }
}

/// The front cover drawn at hero size and scaled to fill whatever frame it's
/// given, so one cover can be shown at any size without its lettering reflowing.
struct ScaledBookCover: View {
    let book: Book

    var body: some View {
        GeometryReader { proxy in
            let hero = DS.Size.coverHero
            let scale = min(proxy.size.width / hero.width, proxy.size.height / hero.height)
            BookCover(book: book, size: .hero)
                .scaleEffect(scale)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

/// Breaks a title into short, balanced lines for a cover label.
enum CoverTitle {
    static func lines(_ title: String, maxCharacters: Int = 11) -> [String] {
        var lines: [String] = []
        var current = ""
        for word in title.uppercased().split(separator: " ") {
            let candidate = current.isEmpty ? String(word) : current + " " + word
            if candidate.count > maxCharacters, !current.isEmpty {
                lines.append(current)
                current = String(word)
            } else {
                current = candidate
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }
}

/// The groove where a hardback's cover meets its spine.
struct CoverHinge: View {
    let width: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(colors: [.black.opacity(0.32), .black.opacity(0.04)], startPoint: .leading, endPoint: .trailing)
                .frame(width: width * 0.07)
            Rectangle().fill(.white.opacity(0.14)).frame(width: 1)
            LinearGradient(colors: [.black.opacity(0.10), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: width * 0.05)
            Spacer(minLength: 0)
        }
        .allowsHitTesting(false)
    }
}

/// The back of a cover: a quieter pattern and the blurb, set in foil.
struct BookBackCover: View {
    let book: Book
    let blurb: String

    private var edition: Edition { Edition.of(book) }

    var body: some View {
        ZStack {
            EditionPattern(edition: edition, tile: BookCover.Size.large.tile, intensity: 0.22)
            VStack(spacing: DS.Space.s) {
                Text(blurb)
                    .font(DS.Typography.stampItalic(12))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .minimumScaleFactor(0.7)
                Ornament(color: edition.foilColor, compact: true)
                if let byline = book.byline {
                    Text(byline.uppercased())
                        .font(BookCover.Size.large.authorFont)
                        .tracking(DS.Tracking.stamp * 0.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .foregroundStyle(edition.foilColor)
            .padding(DS.Space.m)
        }
        .frame(width: DS.Size.coverLarge.width, height: DS.Size.coverLarge.height)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.cover, style: .continuous))
        .dsCoverShadow()
    }
}

/// The inside of a cover: endpaper, with a bookplate.
struct Endpaper: View {
    let book: Book

    private var edition: Edition { Edition.of(book) }

    var body: some View {
        ZStack {
            DS.Colors.surface
            EditionPattern(edition: edition, tile: 16, intensity: 0.35)
                .opacity(0.35)
            VStack(spacing: DS.Space.xs) {
                Text("Ex libris")
                    .font(DS.Typography.folio)
                Text("Plot Twist")
                    .font(DS.Typography.chapter)
            }
            .foregroundStyle(edition.ink)
            .padding(.horizontal, DS.Space.l)
            .padding(.vertical, DS.Space.m)
            .background(DS.Colors.surface)
            .overlay(Rectangle().strokeBorder(edition.ink, lineWidth: 1).padding(3))
        }
    }
}

/// A cover you can turn over to read the back.
struct FlippableCover: View {
    let book: Book
    let blurb: String

    @State private var angle: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CardFlip(angle: angle) {
            BookCover(book: book, size: .large)
        } back: {
            BookBackCover(book: book, blurb: blurb)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(reduceMotion ? DS.Motion.standard : DS.Motion.flip) {
                angle = angle == 0 ? 180 : 0
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: angle)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(angle == 0 ? "Cover of \(book.title)" : blurb))
        .accessibilityHint("Turns the book over")
        .accessibilityAddTraits(.isButton)
    }
}

/// Rotates two faces around the vertical axis, swapping them at 90°.
struct CardFlip<Front: View, Back: View>: View, Animatable {
    var angle: Double
    @ViewBuilder let front: Front
    @ViewBuilder let back: Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        ZStack {
            if angle < 90 {
                front
            } else {
                back.rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.45)
    }
}

#Preview {
    let book = Book(id: "x", title: "Pride and Prejudice", author: "Jane Austen", year: 1813, coverID: nil)
    VStack(spacing: DS.Space.l) {
        HStack(alignment: .bottom, spacing: DS.Space.l) {
            BookCover(book: book, size: .small)
            BookCover(book: book, size: .medium)
            FlippableCover(book: book, blurb: "Five sisters, one proud gentleman, and a first impression that is entirely wrong.")
        }
        Endpaper(book: book).frame(width: 150, height: 225)
    }
    .padding()
    .background(DS.Colors.canvas)
}
