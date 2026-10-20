import SwiftUI

/// Plot Twist Design System.
///
/// Every visual decision in the app resolves to a token in this namespace.
/// Views never use raw colours, font sizes, paddings, radii or animations.
/// If something you need isn't here, add a token first, then use it.
///
/// Plot Twist is dark only. The room is black; light comes from two places:
/// the app's own "opal" gradient (mint → aqua → periwinkle → lilac), and the
/// books themselves, each bound in an `Edition` (cloth, foil, pattern) that
/// glows faintly on the black. See Edition.swift.
///
/// See DESIGN_SYSTEM.md at the project root for the rules behind each token.
enum DS {}

// MARK: - Color

extension DS {
    enum Colors {
        // MARK: The room

        /// Screen background: near-black, so OLED screens all but switch off.
        static let canvas = Color(hex: 0x030404)
        /// Cards and fields, at rest.
        static let surface = Color(hex: 0x111414)
        /// Cards and controls lifted toward you: pressed states, selections.
        static let surfaceRaised = Color(hex: 0x1B1F1F)
        /// The top of a glass card, where the light catches it.
        static let glassTop = Color(hex: 0x181C1C)
        /// The bottom of a glass card.
        static let glassBottom = Color(hex: 0x0C0F0F)
        /// Separators, tracks and quiet outlines.
        static let hairline = Color.white.opacity(0.09)
        /// The lit top edge of glass.
        static let rim = Color.white.opacity(0.16)

        // MARK: Ink

        /// Primary text and icons.
        static let ink = Color(hex: 0xF2F5F4)
        /// Supporting text: authors, metadata, descriptions.
        static let inkSecondary = Color(hex: 0xA2A9A7)
        /// Placeholders, footnotes, page numbers, unselected icons.
        static let inkTertiary = Color(hex: 0x646B69)

        // MARK: Light

        /// The app's own accent: pale mint, like the light inside an opal.
        /// Used for numerals, selections and tints on screens that don't
        /// belong to a single book. Book screens use the book's `Edition.ink`.
        static let accent = Color(hex: 0xBDF4D3)
        /// The deeper end of the accent, for glows and fills behind it.
        static let accentDeep = Color(hex: 0x5ED8C4)
        /// Text drawn on top of `accent`.
        static let onAccent = Color(hex: 0x04120D)
        /// Good news: finished, saved.
        static let positive = Color(hex: 0x57D9B7)
        /// Destructive actions and warnings.
        static let caution = Color(hex: 0xFF7383)

        // MARK: Inside the books

        /// A page in the reader: the darkest warm grey, so it reads as paper, not void.
        static let page = Color(hex: 0x0D0E0F)
        /// Reading text on `page`: warm cream rather than white, for long reading.
        static let pageInk = Color(hex: 0xE8E4DC)
        /// The fold of a dog-eared page and the gutter shadow of a spread.
        static let fold = Color(hex: 0x1A1C1D)
    }

    /// The opal: the one gradient that belongs to the app rather than a book.
    enum Gradients {
        /// Mint → aqua → periwinkle → lilac, the fire inside an opal.
        static let opalColors: [Color] = [
            Color(hex: 0xC9F7D6),
            Color(hex: 0x7FE3D4),
            Color(hex: 0xA3B3FF),
            Color(hex: 0xE2B8FF),
        ]
        static let opal = LinearGradient(colors: opalColors, startPoint: .leading, endPoint: .trailing)
        /// For arcs and rings: the same fire, swept around a circle.
        static let opalSweep = AngularGradient(colors: opalColors + [opalColors[0]], center: .center)
        /// The room's ambient light on screens that don't belong to a book.
        static let roomGlow = Color(hex: 0x3FC9A8)

        /// A glass card's fill: lit from above.
        static let glass = LinearGradient(
            colors: [Colors.glassTop, Colors.glassBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        /// A glass card's edge: bright at the top, gone by the bottom.
        static let glassEdge = LinearGradient(
            colors: [Colors.rim, Color.white.opacity(0.04), Color.white.opacity(0.02)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Typography

extension DS {
    /// Two families, each with one job.
    /// Newsreader (serif, bundled in Resources/Fonts and registered at launch)
    /// is the type *inside the books*: covers, title pages, chapters, prose.
    /// San Francisco (the system font) is the *interface*: titles, lists,
    /// controls, numerals, metadata. Every interface style is a Dynamic Type style.
    enum Typography {
        // MARK: Inside the books (Newsreader)

        /// A book's or a story's title page.
        static let display = serif(.display, 34, relativeTo: .largeTitle)
        /// Moment titles and sheet titles that belong to a book.
        static let title = serif(.heading, 24, relativeTo: .title2)
        /// Chapter headings in the reader; the bookplate on an endpaper.
        static let chapter = serif(.heading, 20, relativeTo: .title3)
        /// Long-form reading text.
        static let reading = serif(.text, 17, relativeTo: .body)
        /// The raised initial that opens every chapter.
        static let raisedCap = serif(.display, 44, relativeTo: .largeTitle)
        /// The user's change, quoted; a book's blurb.
        static let quote = serif(.textItalic, 17, relativeTo: .body)
        /// Running heads and page numbers.
        static let folio = serif(.textItalic, 12, relativeTo: .caption)

        // MARK: Interface (San Francisco)

        /// The app's name at the top of home: small, tracked capitals.
        /// Always paired with `Tracking.masthead` and `.textCase(.uppercase)`.
        static let masthead = Font.system(.subheadline, weight: .semibold)
        /// One line under a screen title, in tracked capitals.
        /// Always paired with `Tracking.eyebrow` and `.textCase(.uppercase)`.
        static let subtitle = Font.system(.caption2, weight: .medium)
        /// Big numerals: the reading gauge, scores. Light, like Opal's.
        static let gauge = Font.system(size: 52, weight: .light).monospacedDigit()
        /// Numerals inside pills and stats.
        static let stat = Font.system(.subheadline, weight: .semibold).monospacedDigit()
        /// Screen titles in the interface ("Twisted", sheet titles).
        static let screenTitle = Font.system(.title2, weight: .semibold)
        /// Sheet titles, message titles, card titles.
        static let heading = Font.system(.headline)
        /// Titles in lists, cards and the story map.
        static let rowTitle = Font.system(.subheadline, weight: .semibold)
        /// A short quotation in small print: your change on a card, a confirmation line.
        static let quoteSmall = Font.system(.footnote).italic()
        /// The user's change, while they write it.
        static let compose = Font.system(.callout)
        /// Interface body text: fields, descriptions.
        static let body = Font.system(.subheadline)
        /// Button labels.
        static let label = Font.system(.subheadline, weight: .semibold)
        /// Interface emphasis: notice titles.
        static let emphasis = Font.system(.subheadline, weight: .semibold)
        /// Metadata: author, year, counts.
        static let meta = Font.system(.footnote)
        /// Metadata that needs a little more weight (progress, status).
        static let metaEmphasis = Font.system(.footnote, weight: .medium)
        /// Small print: timestamps, footnotes.
        static let caption = Font.system(.caption)
        /// Small print that needs a little more weight.
        static let captionEmphasis = Font.system(.caption, weight: .medium)
        /// Uppercase labels (eyebrows). Always paired with `Tracking.eyebrow`.
        static let eyebrow = Font.system(.caption2, weight: .semibold)
        /// Icons that stand alone in a message (empty and error states).
        static let symbol = Font.system(.title, weight: .light)

        // MARK: Lettering on covers (Newsreader, fixed size)

        /// Lettering stamped on covers, spines and labels. Illustration, so
        /// it's fixed-size like a printed cover rather than Dynamic Type.
        static func stamp(_ size: CGFloat) -> Font { .custom(Face.textSemibold.rawValue, fixedSize: size) }
        /// Italic lettering on covers (author lines, blurbs).
        static func stampItalic(_ size: CGFloat) -> Font { .custom(Face.textItalic.rawValue, fixedSize: size) }
        /// Display lettering on half-titles.
        static func stampDisplay(_ size: CGFloat) -> Font { .custom(Face.display.rawValue, fixedSize: size) }

        /// Every bundled face, by PostScript name.
        enum Face: String, CaseIterable {
            case display = "PlotTwistDisplay-Regular"
            case heading = "PlotTwistHeading-Medium"
            case text = "PlotTwistText-Regular"
            case textItalic = "PlotTwistText-Italic"
            case textSemibold = "PlotTwistText-SemiBold"
        }

        private static func serif(_ face: Face, _ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
            .custom(face.rawValue, size: size, relativeTo: style)
        }
    }

    enum Tracking {
        static let eyebrow: CGFloat = 1.2
        /// Letter-spacing for the app's name at the top of home.
        static let masthead: CGFloat = 2.4
        /// Letter-spacing for titles stamped on covers and spines.
        static let stamp: CGFloat = 1.6
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
        /// Small controls.
        static let s: CGFloat = 14
        /// Glass cards, fields and pages.
        static let m: CGFloat = 24
        /// Large panels and sheets.
        static let l: CGFloat = 32
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
        /// The custom icons in the top bar, and the capsule that holds them.
        static let navGlyph: CGFloat = 22
        static let navItem: CGFloat = 40
        /// The reading gauge on a book's screen.
        static let gauge: CGFloat = 220
        static let gaugeLine: CGFloat = 7
        /// Pills (choices and stats).
        static let pill: CGFloat = 44
        /// The branching mark on a twisted story's card.
        static let twistMark: CGFloat = 32
        /// Ribbon bookmarks.
        static let ribbonWidth: CGFloat = 14
        static let ribbonLength: CGFloat = 40
        /// The folded corner of a dog-eared page.
        static let fold: CGFloat = 20
        /// Story-map timeline: the spine line and its moment nodes.
        static let timelineNode: CGFloat = 12
        static let timelineGutter: CGFloat = 28
        /// Branch lines from a moment to its alternatives.
        static let branchGutter: CGFloat = 26
        /// Minimum interactive height (HIG: 44pt).
        static let touch: CGFloat = 44
        /// Primary buttons.
        static let button: CGFloat = 54
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
        /// The gauge filling to your progress.
        static let gauge = Animation.spring(duration: 1.0, bounce: 0.1)
        /// Books in the stack lifting as you start to scroll.
        static let lift = Animation.spring(duration: 0.45, bounce: 0.12)
        /// Books settling back when the stack comes to rest: a soft wobble.
        static let settle = Animation.spring(duration: 0.75, bounce: 0.42)
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
        /// A book on the black: a soft shadow under it and a faint rim of light.
        struct Cover: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.Radius.cover, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
                    }
                    .shadow(color: .black.opacity(0.6), radius: 14, x: 0, y: 10)
            }
        }

        /// Light spilling from something onto the black around it.
        struct Glow: ViewModifier {
            let color: Color
            var radius: CGFloat = 22
            var strength: Double = 0.35

            func body(content: Content) -> some View {
                content.shadow(color: color.opacity(strength), radius: radius, x: 0, y: radius * 0.35)
            }
        }
    }
}

extension View {
    func dsCoverShadow() -> some View { modifier(DS.Elevation.Cover()) }
    func dsGlow(_ color: Color, radius: CGFloat = 22, strength: Double = 0.35) -> some View {
        modifier(DS.Elevation.Glow(color: color, radius: radius, strength: strength))
    }
}

// MARK: - Helpers

extension Color {
    /// A colour from a hex value. Plot Twist is dark only, so every colour is one value.
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
