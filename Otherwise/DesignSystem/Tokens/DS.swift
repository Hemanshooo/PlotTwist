import SwiftUI

/// Plot Twist Design System.
///
/// Every visual decision in the app resolves to a token in this namespace.
/// Views never use raw colors, font sizes, paddings, radii or animations.
/// If something you need isn't here, add a token first, then use it.
///
/// The interface is paper and ink. Colour comes from the books themselves:
/// every book is bound in an `Edition` (cloth, foil, pattern), see Edition.swift.
///
/// See DESIGN_SYSTEM.md at the project root for the rules behind each token.
enum DS {}

// MARK: - Color

extension DS {
    /// The paper-and-ink palette. Light and dark are defined together
    /// so the two themes can never drift apart.
    enum Colors {
        /// Screen background. Soft bone paper in light, near-black in dark.
        static let canvas = Color(light: 0xF4F1EB, dark: 0x111110)
        /// Raised surfaces: pages, fields, cards.
        static let surface = Color(light: 0xFBFAF7, dark: 0x1B1A19)
        /// Primary text and icons.
        static let ink = Color(light: 0x171615, dark: 0xEEEBE5)
        /// Supporting text: authors, metadata, descriptions.
        static let inkSecondary = Color(light: 0x6B675F, dark: 0xA6A29B)
        /// Placeholders, footnotes, page numbers.
        static let inkTertiary = Color(light: 0x9C978F, dark: 0x6F6B65)
        /// Separators and 1pt borders.
        static let hairline = Color(light: 0xE3DED5, dark: 0x2A2927)
        /// The app's own accent: ink blue, like a fountain pen in the margin.
        /// Used on screens that don't belong to a single book (home, search).
        /// Book screens use the book's `Edition.ink` instead.
        static let accent = Color(light: 0x2B4C8C, dark: 0x8EAAE6)
        /// Text drawn on top of `accent` (≥ 4.5:1 in both themes).
        static let onAccent = Color(light: 0xFFFFFF, dark: 0x0E1424)
        /// The shelf plank books stand on.
        static let shelf = Color(light: 0xD9CFBE, dark: 0x34302B)
        /// The shadowed front edge of the shelf.
        static let shelfEdge = Color(light: 0xBBAE98, dark: 0x24211D)
        /// The fold of a dog-eared page and the gutter shadow of a spread.
        static let fold = Color(light: 0xE8E3D9, dark: 0x272523)
    }
}

// MARK: - Typography

extension DS {
    /// Two families, each with one job.
    /// Newsreader (serif, bundled in Resources/Fonts and registered at launch)
    /// is the type *inside the books*: covers, title pages, chapters, prose.
    /// San Francisco (the system font) is the *interface*: titles, lists,
    /// controls, metadata. Every interface style is a Dynamic Type text style.
    enum Typography {
        // MARK: Inside the books (Newsreader)

        /// A book's or a story's title page.
        static let display = serif(.display, 30, relativeTo: .title)
        /// Book title on the book screen, moment titles.
        static let title = serif(.heading, 22, relativeTo: .title2)
        /// Chapter headings in the reader; the bookplate on an endpaper.
        static let chapter = serif(.heading, 20, relativeTo: .title3)
        /// Long-form reading text.
        static let reading = serif(.text, 17, relativeTo: .body)
        /// The raised initial that opens every chapter.
        static let raisedCap = serif(.display, 40, relativeTo: .largeTitle)
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
        /// Uppercase labels (eyebrows, top-bar options). Always paired with `Tracking.eyebrow`.
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
        /// Small controls, pills.
        static let s: CGFloat = 10
        /// Fields, cards and pages.
        static let m: CGFloat = 18
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
        /// A held book set down to open: the spread (cover + first page) fits the screen.
        static let spreadScale: CGFloat = 0.8
        /// The book stack on the home screen: distance between books, the
        /// margin either side, and the height of each book's title strip.
        static let stackStride: CGFloat = 92
        static let stackInset: CGFloat = 40
        static let stackStrip: CGFloat = 30
        /// Spines vary within these ranges so a shelf never looks stamped out.
        static let spineWidth: ClosedRange<CGFloat> = 34...46
        static let spineHeight: ClosedRange<CGFloat> = 148...184
        /// The branching mark on a twisted story's card.
        static let twistMark: CGFloat = 28
        /// Ribbon bookmarks.
        static let ribbonWidth: CGFloat = 14
        static let ribbonLength: CGFloat = 40
        /// Shelf plank thickness.
        static let shelf: CGFloat = 12
        /// The folded corner of a dog-eared page.
        static let fold: CGFloat = 20
        /// Story-map timeline: the spine line and its moment nodes.
        static let timelineNode: CGFloat = 12
        static let timelineGutter: CGFloat = 28
        /// Minimum interactive height (HIG: 44pt).
        static let touch: CGFloat = 44
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
        /// Generated text settling onto the page.
        static let reveal = Animation.easeOut(duration: 0.5)
        /// A ribbon bookmark dropping into place.
        static let ribbon = Animation.spring(duration: 0.6, bounce: 0.35)
        /// Turning a cover over to read the back.
        static let flip = Animation.spring(duration: 0.7, bounce: 0.12)
        /// A book cover swinging open on its spine.
        static let coverOpen = Animation.spring(duration: 1.1, bounce: 0.08)
        /// A book cover swinging shut.
        static let coverClose = Animation.spring(duration: 0.7, bounce: 0.04)
        /// A book sliding up out of the stack, or back down into it.
        static let slide = Animation.snappy(duration: 0.3)
        /// A book tipping up toward you under your finger.
        static let tilt = Animation.spring(duration: 0.32, bounce: 0.35)
        /// A book standing up in your hands.
        static let pullOut = Animation.spring(duration: 0.6, bounce: 0.12)
        /// A first page coming up to fill the screen.
        static let unfold = Animation.spring(duration: 0.55, bounce: 0.04)
    }
}

// MARK: - Depth

extension DS {
    /// Perspective for 3D tilts. Lower is flatter (a longer lens).
    enum Depth {
        /// Books laid back in the home stack, and the book you pick from it.
        static let stack: CGFloat = 0.32
    }
}

// MARK: - Elevation

extension DS {
    enum Elevation {
        /// A book resting on paper.
        struct Cover: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .shadow(color: .black.opacity(0.10), radius: 1, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 10)
            }
        }

        /// A sheet of paper lifted slightly off the desk.
        struct Page: ViewModifier {
            func body(content: Content) -> some View {
                content.shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
            }
        }
    }
}

extension View {
    func dsCoverShadow() -> some View { modifier(DS.Elevation.Cover()) }
    func dsPageShadow() -> some View { modifier(DS.Elevation.Page()) }
}

// MARK: - Helpers

extension Color {
    /// A color that resolves differently in light and dark appearance.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    /// A color that is the same in both appearances (book cloth and foil).
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
