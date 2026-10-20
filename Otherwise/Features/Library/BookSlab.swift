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

    /// Spines take only a little of the shadow, so their lettering stays readable.
    nonisolated static let spineFog: Double = 0.35

    /// How far covers lift (degrees) while the stack is moving; see `BookStack`.
    nonisolated static let flutterLift: Double = 7

    /// The cover angle for a book at `fraction` down the screen while the
    /// stack moves: `flutter` +1 lifts covers open (scrolling on through the
    /// stack), −1 lays them flatter (scrolling back), 0 is at rest.
    nonisolated static func coverAngle(atScreenFraction fraction: CGFloat, flutter: Double) -> Double {
        let base = coverAngle(atScreenFraction: fraction)
        let lift = flutter >= 0 ? flutterLift : flutterLift * 0.55
        return min(max(base - flutter * lift, 50), 89)
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

/// The spine, panelled like a real cloth spine: the edition's pattern on the
/// two end panels, foil bands, and a plain centre panel where the title and
/// author are stamped in a foil that's checked to read against the cloth.
/// A ribbon lies across books you're partway through; finished books carry a seal.
/// Nothing is drawn outside the spine.
struct SlabSpineFace: View {
    let book: Book
    let length: CGFloat
    var progress: Double?

    private var edition: Edition { Edition.of(book) }
    private var height: CGFloat { DS.Size.slabSpine }
    /// The patterned panel at each end of the spine.
    private var endPanel: CGFloat { DS.Space.l }

    var body: some View {
        ZStack {
            edition.clothColor
            // A whisper of the pattern across the whole spine, for texture…
            EditionPattern(edition: edition, tile: 13, intensity: 0.32)
                .opacity(0.22)
            // …and the full pattern on the end panels.
            HStack(spacing: 0) {
                EditionPattern(edition: edition, tile: 13, intensity: 0.38)
                    .frame(width: endPanel)
                Spacer(minLength: 0)
                EditionPattern(edition: edition, tile: 13, intensity: 0.38)
                    .frame(width: endPanel)
            }
            // The spine is rounded: brighter along the top, falling into shadow.
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.12), location: 0),
                    .init(color: .white.opacity(0.03), location: 0.4),
                    .init(color: .black.opacity(0.24), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            HStack(spacing: DS.Space.s) {
                Text(book.title.uppercased())
                    .font(DS.Typography.stamp(11.5))
                    .tracking(DS.Tracking.stamp * 0.75)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .layoutPriority(1)
                Spacer(minLength: DS.Space.xs)
                if let author = book.author {
                    Text(author)
                        .font(DS.Typography.stampItalic(12.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                if let progress, progress >= 0.999 {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .accessibilityHidden(true)
                } else if progress != nil {
                    // Your bookmark, lying across the spine from its top edge.
                    RibbonShape()
                        .fill(edition.lettering)
                        .overlay {
                            LinearGradient(colors: [.white.opacity(0), .white.opacity(0.3), .white.opacity(0)], startPoint: .leading, endPoint: .trailing)
                                .clipShape(RibbonShape())
                        }
                        .frame(width: 8, height: height - 7)
                        .shadow(color: .black.opacity(0.45), radius: 1, x: 0, y: 0.5)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(edition.lettering)
            .padding(.horizontal, endPanel + DS.Space.s)
            // Foil bands where the end panels meet the centre.
            HStack(spacing: 0) {
                bands.frame(width: endPanel, alignment: .trailing)
                Spacer(minLength: 0)
                bands.scaleEffect(x: -1).frame(width: endPanel, alignment: .leading)
            }
            .foregroundStyle(edition.foilColor)
        }
        .frame(width: length, height: height)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.cover, style: .continuous))
        // The edge where spine meets cover catches the light.
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.22)).frame(height: 0.75)
        }
        .accessibilityHidden(true)
    }

    private var bands: some View {
        HStack(spacing: 2.5) {
            Rectangle().frame(width: 0.75)
            Rectangle().frame(width: 1.5)
        }
        .frame(height: height)
        .opacity(0.85)
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
                .brightness(fog)
            SlabSpineFace(book: book, length: length, progress: progress)
                .rotation3DEffect(
                    .degrees(Slab.spineRotation(coverAngle)),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: DS.Depth.stack
                )
                .brightness(fog * Slab.spineFog)
                .opacity(coverAngle < 4 ? 0 : 1)
        }
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
