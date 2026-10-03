import SwiftUI

/// A book standing on a shelf: cloth, patterned bands at head and tail,
/// and the title stamped up the spine. Width and height vary per book
/// (from a stable hash) so a shelf looks collected, not generated.
struct BookSpine: View {
    let book: Book
    /// Shows a ribbon hanging from the tail: this book is being read.
    var isReading: Bool = false

    private var edition: Edition { Edition.of(book) }

    /// The spine's size on the shelf.
    static func size(for book: Book) -> CGSize {
        let seed = book.title.unicodeScalars.reduce(7) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        let w = DS.Size.spineWidth, h = DS.Size.spineHeight
        return CGSize(
            width: w.lowerBound + CGFloat(seed % 4) / 3 * (w.upperBound - w.lowerBound),
            height: h.lowerBound + CGFloat((seed / 4) % 5) / 4 * (h.upperBound - h.lowerBound)
        )
    }

    var body: some View {
        let size = Self.size(for: book)
        SpineFace(book: book)
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if isReading {
                    BookmarkRibbon(color: edition.foilColor, width: 8, length: 26)
                        .offset(x: size.width * 0.18, y: 20)
                }
            }
            .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 0)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(book.title))
            .accessibilityValue(Text(isReading ? "Reading" : "Read"))
    }
}

/// The spine itself, filling whatever frame it's given, so it can be
/// stretched and turned while a book is drawn off the shelf.
struct SpineFace: View {
    let book: Book

    private var edition: Edition { Edition.of(book) }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                edition.clothColor
                VStack(spacing: 0) {
                    band
                    Spacer(minLength: 0)
                    band
                }
                Text(book.title.uppercased())
                    .font(DS.Typography.stamp(11))
                    .tracking(DS.Tracking.stamp)
                    .foregroundStyle(edition.foilColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: max(size.height - 64, 1), height: size.width)
                    .rotationEffect(.degrees(-90))
                    // Keep the turned title's layout box inside the spine, so it
                    // never widens the spine's touch or accessibility area.
                    .frame(width: size.width, height: size.height)
                // Rounded spine: light from the left, shade on the right.
                LinearGradient(
                    colors: [.white.opacity(0.12), .clear, .black.opacity(0.22)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .frame(width: size.width, height: size.height)
        }
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        .accessibilityHidden(true)
    }

    /// Head and tail bands: a strip of the edition's pattern between foil rules.
    private var band: some View {
        VStack(spacing: 2) {
            Rectangle().fill(edition.foilColor).frame(height: 1)
            EditionPattern(edition: edition, tile: 8, intensity: 0.8)
                .frame(height: 18)
            Rectangle().fill(edition.foilColor).frame(height: 1)
        }
        .padding(.vertical, DS.Space.xs)
    }
}

/// Pressing a spine tilts the book toward you, the way you'd hook a finger over
/// its top to take it down. Releasing selects it; sliding off puts it back.
struct SpineTiltButtonStyle: ButtonStyle {
    /// Reports press changes, so the shelf can lift this book above its neighbours.
    var onPressChange: (Bool) -> Void = { _ in }

    func makeBody(configuration: Configuration) -> some View {
        SpineTilt(label: configuration.label, isPressed: configuration.isPressed, onPressChange: onPressChange)
    }
}

private struct SpineTilt<Label: View>: View {
    let label: Label
    let isPressed: Bool
    let onPressChange: (Bool) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        label
            // The top comes toward you, hinged on the shelf.
            .rotation3DEffect(
                .degrees(isPressed && !reduceMotion ? 22 : 0),
                axis: (x: 1, y: 0, z: 0),
                anchor: .bottom,
                perspective: 0.55
            )
            .scaleEffect(isPressed ? 1.05 : 1, anchor: .bottom)
            .offset(y: isPressed ? -DS.Space.xxs : 0)
            .shadow(color: .black.opacity(isPressed ? 0.3 : 0), radius: isPressed ? 12 : 0, x: 0, y: isPressed ? 10 : 0)
            .animation(DS.Motion.tilt, value: isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: isPressed) { _, pressed in pressed }
            .onChange(of: isPressed) { _, pressed in onPressChange(pressed) }
    }
}

/// Cards and covers sink slightly under a finger.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DS.Motion.quick, value: configuration.isPressed)
    }
}

/// A horizontal shelf of spines standing on a plank.
struct Shelf<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .bottom) {
            plank
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 3) {
                    content
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.top, DS.Space.xs)
            }
            .scrollClipDisabled()
            .padding(.bottom, DS.Size.shelf)
        }
    }

    private var plank: some View {
        VStack(spacing: 0) {
            Rectangle().fill(DS.Colors.shelf).frame(height: DS.Size.shelf * 0.6)
            Rectangle().fill(DS.Colors.shelfEdge).frame(height: DS.Size.shelf * 0.4)
        }
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 6)
    }
}

#Preview {
    let books = ["Pride and Prejudice", "Dracula", "Little Women", "Frankenstein", "The Great Gatsby", "Jane Eyre"]
    Shelf {
        ForEach(Array(books.enumerated()), id: \.offset) { index, title in
            BookSpine(book: Book(id: title, title: title, author: nil, year: nil, coverID: nil), isReading: index == 2)
        }
    }
    .padding(.vertical, DS.Space.xl)
    .background(DS.Colors.canvas)
}
