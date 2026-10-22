import SwiftUI

/// Plot Twist Design System.
///
/// Every visual decision in the app resolves to a token in this namespace.
/// Views never use raw colours, font sizes, paddings, radii or animations.
/// If something you need isn't here, add a token first, then use it.
///
/// Plot Twist is a garden of forking paths, set like a type specimen: a flat
/// ground, a crisp display serif, small mono labels, outlined pills, and one
/// two-colour illustration that grows through the app (stems, leaves, roses).
/// There are no gradients, glows or glass. Colour comes from the palette
/// (Palette.swift) and from the books themselves (Edition.swift).
///
/// See DESIGN_SYSTEM.md at the project root for the rules behind each token.
enum DS {}

// MARK: - Color

extension DS {
    /// The current palette's colours. Reading one inside a view's body ties
    /// that view to the palette, so it redraws when the palette changes.
    enum Colors {
        private static var scheme: Palette.Scheme { Theme.shared.palette.scheme }

        // MARK: The room

        static var canvas: Color { scheme.canvas }
        static var surface: Color { scheme.surface }
        static var raised: Color { scheme.raised }
        static var hairline: Color { scheme.hairline }
        static var shadow: Color { scheme.shadow }

        // MARK: Ink

        static var ink: Color { scheme.ink }
        static var inkSecondary: Color { scheme.inkSecondary }
        static var inkTertiary: Color { scheme.inkTertiary }
        /// Text set on `ink` (the selected pill, the primary button): the ground.
        static var onInk: Color { scheme.canvas }
        static var caution: Color { scheme.caution }

        // MARK: The garden

        static var stem: Color { scheme.stem }
        static var bloom: Color { scheme.bloom }
        static var petal: Color { scheme.petal }

        // MARK: Inside the books

        static var page: Color { scheme.page }
        static var pageInk: Color { scheme.pageInk }
    }
}

// MARK: - Typography

extension DS {
    /// Three families, each with one job.
    /// - Instrument Serif: display. Titles, numerals, raised capitals, the wordmark.
    /// - Newsreader: reading. Prose, quotes, descriptions, and lettering on covers.
    /// - DM Mono: the interface. Labels, buttons, metadata, hints.
    /// All bundled in Resources/Fonts and registered at launch. Every style
    /// scales with Dynamic Type, except cover lettering (illustration).
    enum Typography {
        // MARK: Display (Instrument Serif)

        /// A book's or a story's title page.
        static let display = font(.display, 46, relativeTo: .largeTitle)
        /// Moment titles, sheet titles, "The End".
        static let title = font(.display, 32, relativeTo: .title)
        /// Chapter headings in the reader.
        static let chapter = font(.display, 28, relativeTo: .title2)
        /// Titles in lists: moments on the map, twisted stories, search results.
        static let heading = font(.display, 24, relativeTo: .title3)
        /// The reading gauge's numeral.
        static let numeral = font(.display, 84, relativeTo: .largeTitle)
        /// The raised initial that opens every chapter.
        static let raisedCap = font(.display, 62, relativeTo: .largeTitle)
        /// The wordmark at the top of the library: fixed, since the garden is
        /// drawn around it to measure.
        static func wordmark(_ size: CGFloat) -> Font { .custom(Face.display.rawValue, fixedSize: size) }
        /// Italic display, for the odd word set apart.
        static let displayItalic = font(.displayItalic, 32, relativeTo: .title)

        // MARK: Reading (Newsreader)

        /// Long-form reading text.
        static let reading = font(.text, 17, relativeTo: .body)
        /// Descriptions and choices: a moment's summary, an alternative.
        static let blurb = font(.text, 15, relativeTo: .subheadline)
        /// The user's change, quoted; a premise.
        static let quote = font(.textItalic, 17, relativeTo: .body)
        /// A short quotation in small print.
        static let quoteSmall = font(.textItalic, 15, relativeTo: .subheadline)
        /// The user's change, while they write it.
        static let compose = font(.text, 17, relativeTo: .body)

        // MARK: Interface (DM Mono)

        /// Buttons and pills.
        static let label = font(.monoMedium, 13, relativeTo: .subheadline)
        /// The tabs in the top bar.
        static let tab = font(.monoMedium, 12, relativeTo: .footnote)
        /// Bylines, metadata, counts.
        static let meta = font(.mono, 12, relativeTo: .footnote)
        /// Hints, footnotes, small print.
        static let caption = font(.mono, 11, relativeTo: .caption)
        /// Section labels. Always paired with `Tracking.eyebrow` and `.textCase(.uppercase)`.
        static let eyebrow = font(.monoMedium, 11, relativeTo: .caption)
        /// Running heads and page numbers.
        static let folio = font(.mono, 10, relativeTo: .caption2)
        /// System symbols standing alone in a message.
        static let symbol = Font.system(.title2, weight: .light)

        // MARK: Lettering on covers (Newsreader, fixed size)

        /// Lettering stamped on covers, spines and labels. Illustration, so
        /// it's fixed-size like a printed cover rather than Dynamic Type.
        static func stamp(_ size: CGFloat) -> Font { .custom(Face.textSemibold.rawValue, fixedSize: size) }
        /// Italic lettering on covers (author lines, blurbs).
        static func stampItalic(_ size: CGFloat) -> Font { .custom(Face.textItalic.rawValue, fixedSize: size) }
        /// Display lettering on half-titles.
        static func stampDisplay(_ size: CGFloat) -> Font { .custom(Face.newsreaderDisplay.rawValue, fixedSize: size) }

        /// Every bundled face, by PostScript name.
        enum Face: String, CaseIterable {
            case display = "InstrumentSerif-Regular"
            case displayItalic = "InstrumentSerif-Italic"
            case newsreaderDisplay = "PlotTwistDisplay-Regular"
            case heading = "PlotTwistHeading-Medium"
            case text = "PlotTwistText-Regular"
            case textItalic = "PlotTwistText-Italic"
            case textSemibold = "PlotTwistText-SemiBold"
            case mono = "DMMono-Regular"
            case monoMedium = "DMMono-Medium"
        }

        private static func font(_ face: Face, _ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
            .custom(face.rawValue, size: size, relativeTo: style)
        }
    }

    enum Tracking {
        /// Section labels in mono capitals.
        static let eyebrow: CGFloat = 1.3
        /// Letter-spacing for titles stamped on covers and spines.
        static let stamp: CGFloat = 1.6
        /// Display titles sit a little tighter, like a specimen.
        static let display: CGFloat = -0.4
    }

    enum Leading {
        /// Extra line spacing for reading text.
        static let reading: CGFloat = 7
        /// Extra line spacing for quotes and descriptions.
        static let relaxed: CGFloat = 4
    }
}

// MARK: - Space

extension DS {
    /// A 4-point grid. Nothing in the app is spaced off this scale.
    enum Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        /// Horizontal margin of every screen.
        static let screen: CGFloat = 20
        /// Inner margin of a printed page in the reader.
        static let page: CGFloat = 28
        /// Maximum width of reading columns (keeps lines ~65 characters on iPad).
        static let readingWidth: CGFloat = 620
    }
}

// MARK: - Radius

extension DS {
    enum Radius {
        /// Book covers and spines. Real books have almost-square corners.
        static let cover: CGFloat = 3
        /// Cards, fields, choices.
        static let s: CGFloat = 12
        /// Panels and swatches.
        static let m: CGFloat = 18
        /// Sheets.
        static let l: CGFloat = 28
    }
}

// MARK: - Size

extension DS {
    enum Size {
        /// Book covers are always 2:3.
        static let coverSmall = CGSize(width: 44, height: 66)
        static let coverMedium = CGSize(width: 104, height: 156)
        static let coverLarge = CGSize(width: 150, height: 225)
        /// A book held up in front of you, after it's taken from the stack.
        static let coverHero = CGSize(width: 232, height: 348)
        /// The home stack: the margin either side of a book, the thickness of
        /// its spine (the face you see), and the space each book takes.
        static let slabInset: CGFloat = 22
        static let slabSpine: CGFloat = 34
        static let slabStride: CGFloat = 104
        /// The wordmark's type size; its garland is drawn in proportion.
        static let wordmark: CGFloat = 24
        /// The tabs in the top bar, and the palette swatch beside them.
        static let tab: CGFloat = 32
        static let navItem: CGFloat = 38
        /// Pills (choices).
        static let pill: CGFloat = 36
        /// The forking mark on a twisted story.
        static let twistMark: CGFloat = 30
        /// Roses on the story map and at the tip of the reading vine.
        static let rose: CGFloat = 20
        /// Ribbon bookmarks.
        static let ribbonWidth: CGFloat = 14
        static let ribbonLength: CGFloat = 40
        /// The folded corner of a dog-eared page.
        static let fold: CGFloat = 20
        /// The vine running down the story map, and the gutter it grows in.
        static let vineGutter: CGFloat = 34
        /// The reading vine.
        static let gaugeHeight: CGFloat = 56
        /// Stems: the main stroke of every drawn vine.
        static let stem: CGFloat = 1.8
        /// Minimum interactive height (HIG: 44pt).
        static let touch: CGFloat = 44
        /// Primary buttons.
        static let button: CGFloat = 52
        /// Accent rule beside quotes.
        static let rule: CGFloat = 2
        static let hairline: CGFloat = 1
    }
}

// MARK: - Motion

extension DS {
    /// Motion confirms or delights; it never blocks reading.
    /// Every animation respects Reduce Motion at the call site.
    enum Motion {
        /// State changes: content appearing, layout shifts.
        static let standard = Animation.smooth(duration: 0.35)
        /// Direct feedback: taps, toggles, insertions.
        static let quick = Animation.snappy(duration: 0.22)
        /// A selection sliding between options.
        static let select = Animation.spring(duration: 0.38, bounce: 0.22)
        /// Generated text settling onto the page.
        static let reveal = Animation.easeOut(duration: 0.5)
        /// Content arriving on a new screen, one piece after another.
        static func arrive(_ index: Int) -> Animation {
            .spring(duration: 0.55, bounce: 0.12).delay(0.06 * Double(index))
        }
        /// A ribbon bookmark dropping into place.
        static let ribbon = Animation.spring(duration: 0.6, bounce: 0.35)
        /// Turning a cover over to read the back.
        static let flip = Animation.spring(duration: 0.7, bounce: 0.12)
        /// A story's cover swinging open on its spine.
        static let coverOpen = Animation.spring(duration: 1.1, bounce: 0.08)
        /// Taking a book from the stack and opening it: one continuous motion.
        /// Its phases (lift, open, unfold) are eased inside `OpeningBook`.
        static let openBook = Animation.linear(duration: 1.05)
        /// The opened book handing over to its screen.
        static let handOver = Animation.easeOut(duration: 0.22)
        /// Books in the stack lifting as you start to scroll.
        static let lift = Animation.spring(duration: 0.45, bounce: 0.12)
        /// Books settling back when the stack comes to rest: a soft wobble.
        static let settle = Animation.spring(duration: 0.75, bounce: 0.42)
        /// TWIST turning over into place in the wordmark.
        static let twist = Animation.spring(duration: 0.9, bounce: 0.28)
        /// A stem drawing itself.
        static let grow = Animation.easeInOut(duration: 1.1)
        /// A rose or leaf opening, `index` after the first.
        static func bloom(_ index: Int = 0) -> Animation {
            .spring(duration: 0.6, bounce: 0.38).delay(0.08 * Double(index))
        }
        /// The whole app changing palette.
        static let palette = Animation.easeInOut(duration: 0.45)
    }
}

// MARK: - Depth

extension DS {
    /// Perspective for 3D tilts. Lower is flatter (a longer lens).
    enum Depth {
        /// Books lying in the home stack, and the book you lift from it.
        static let stack: CGFloat = 0.42
        /// A cover swinging open.
        static let cover: CGFloat = 0.35
    }
}

// MARK: - Elevation

extension DS {
    enum Elevation {
        /// A book on the table: a fine edge, a contact shadow and a soft one.
        struct Cover: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.Radius.cover, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5)
                    }
                    .shadow(color: DS.Colors.shadow.opacity(0.3), radius: 1.5, x: 0, y: 1)
                    .shadow(color: DS.Colors.shadow.opacity(0.35), radius: 12, x: 0, y: 8)
            }
        }
    }
}

extension View {
    func dsCoverShadow() -> some View { modifier(DS.Elevation.Cover()) }
}

// MARK: - Helpers

extension Color {
    /// A colour from a hex value.
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
