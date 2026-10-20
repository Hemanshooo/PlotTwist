import SwiftUI

/// A book lying flat with its spine toward you, the way books lie in the home
/// stack. It's drawn as two faces that share one hinge: the front cover on
/// top, the spine hanging down in front.
///
/// The same faces, at the same sizes, are used by the stack and by the
/// opening animation, so a book lifted out of the stack starts from exactly
/// the pixels it was drawn with.
///
/// Geometry, for a slab `length` long (the length of the spine):
/// - the cover is `length` wide and `depth` deep (depth = length × 2/3, so
///   standing up it's a 2:3 cover), drawn sideways with its spine edge at the
///   bottom;
/// - the spine is `length` wide and `DS.Size.slabSpine` tall.
enum Slab {
    static func depth(for length: CGFloat) -> CGFloat { length * 2 / 3 }

    /// How far the cover lies back, in degrees from upright, for a book whose
    /// hinge sits `fraction` of the way down the screen (0 = top, 1 = bottom).
    /// Books near the top lie almost flat (you see little more than the spine);
    /// lower books show more of their cover, as on a table in front of you.
    nonisolated static func coverAngle(atScreenFraction fraction: CGFloat) -> Double {
        let t = min(max(fraction, 0), 1)
        let visible = 0.05 + 0.27 * pow(t, 1.15)
        return acos(visible) * 180 / .pi
    }

    /// Books far up the screen sit a little in shadow.
    nonisolated static func fog(atScreenFraction fraction: CGFloat) -> Double {
        let t = min(max(fraction, 0), 1)
        return -0.22 * pow(1 - t, 1.6)
    }

    /// The cover face's rotation for a cover angle: hinged at its bottom edge,
    /// the top tipping away from you.
    nonisolated static func coverRotation(_ angle: Double) -> Double { angle }
    /// The spine face's rotation for a cover angle: the two faces are at right
    /// angles, so when the cover lies flat the spine faces you, and when the
    /// cover stands up the spine points straight at you.
    nonisolated static func spineRotation(_ angle: Double) -> Double { 90 - angle }
}

// MARK: - Cover face

/// The front cover, turned on its side so its spine edge is at the bottom,
/// with the light falling off toward the back as it lies down.
struct SlabCoverFace: View {
    let book: Book
    let length: CGFloat
    /// 0 = upright, 1 = lying flat: how much of the falloff to show.
    var lying: Double = 1

    var body: some View {
        let depth = Slab.depth(for: length)
        let hero = DS.Size.coverHero
        BookCover(book: book, size: .hero)
            // Portrait, scaled to depth × length (uniformly, since both are 2:3)…
            .scaleEffect(length / hero.height)
            .frame(width: depth, height: length)
            // …and turned so its spine edge runs along the bottom.
            .rotationEffect(.degrees(-90))
            .frame(width: length, height: depth)
            .overlay {
                // Further from the light at the back.
                LinearGradient(
                    colors: [.black.opacity(0.55), .black.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(lying)
                .allowsHitTesting(false)
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Spine face

/// The spine: cloth in the edition's pattern, banded in foil at each end,
/// stamped with the title and author. A bookmark ribbon hangs out of books
/// you're partway through; finished books carry a small seal.
struct SlabSpineFace: View {
    let book: Book
    let length: CGFloat
    var progress: Double?

    private var edition: Edition { Edition.of(book) }

    var body: some View {
        let height = DS.Size.slabSpine
        ZStack {
            EditionPattern(edition: edition, tile: 13, intensity: 0.32)
            // The spine is rounded: brighter along the middle.
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.10), location: 0),
                    .init(color: .white.opacity(0.03), location: 0.35),
                    .init(color: .black.opacity(0.28), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            HStack(spacing: DS.Space.s) {
                bands
                Text(book.title.uppercased())
                    .font(DS.Typography.stamp(11.5))
                    .tracking(DS.Tracking.stamp * 0.75)
                    .lineLimit(1)
                    .layoutPriority(1)
                Spacer(minLength: DS.Space.xs)
                if let author = book.author {
                    Text(author)
                        .font(DS.Typography.stampItalic(12))
                        .lineLimit(1)
                        .opacity(0.85)
                }
                if let progress, progress >= 0.999 {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .accessibilityHidden(true)
                }
                bands
            }
            .foregroundStyle(edition.foilColor)
            .padding(.horizontal, DS.Space.s)
        }
        .frame(width: length, height: height)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.cover, style: .continuous))
        // The edge where spine meets cover catches the light.
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.22)).frame(height: 0.75)
        }
        .overlay(alignment: .bottomTrailing) {
            if let progress, progress < 0.999 {
                // A ribbon hanging from the pages, a little past the spine.
                BookmarkRibbon(color: edition.ink, isPlaced: true, width: 9, length: 22)
                    .offset(y: 20)
                    .padding(.trailing, length * 0.22)
            }
        }
        .accessibilityHidden(true)
    }

    private var bands: some View {
        HStack(spacing: 2.5) {
            Rectangle().frame(width: 1.5)
            Rectangle().frame(width: 0.75)
        }
        .frame(height: DS.Size.slabSpine)
        .opacity(0.75)
    }
}

// MARK: - The whole book

/// Cover and spine, hinged together and posed. `coverAngle` is in degrees
/// from upright (0) to flat (90).
struct SlabBook: View {
    let book: Book
    let length: CGFloat
    var progress: Double?
    var coverAngle: Double
    var fog: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            SlabCoverFace(book: book, length: length, lying: coverAngle / 90)
                .rotation3DEffect(
                    .degrees(Slab.coverRotation(coverAngle)),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: DS.Depth.stack
                )
            SlabSpineFace(book: book, length: length, progress: progress)
                .rotation3DEffect(
                    .degrees(Slab.spineRotation(coverAngle)),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: DS.Depth.stack
                )
                .opacity(coverAngle < 4 ? 0 : 1)
        }
        .brightness(fog)
    }
}

#Preview {
    let books = Catalog.entries.prefix(4).map(\.book)
    VStack(spacing: DS.Space.l) {
        ForEach(Array(books.enumerated()), id: \.offset) { index, book in
            SlabBook(book: book, length: 340, progress: index == 1 ? 0.4 : nil, coverAngle: 86 - Double(index) * 5)
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .dsScreen()
}
