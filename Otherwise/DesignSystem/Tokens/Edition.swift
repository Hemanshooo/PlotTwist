import SwiftUI

/// How a book is bound: a cloth colour, a foil colour and a stamped pattern.
///
/// Inspired by clothbound classics, every book in Plot Twist gets its own
/// edition. It is the only source of colour in the app besides the accent:
/// covers, spines, the book screen's header, its timeline and buttons, and
/// the reader's raised capitals all come from the book's edition.
///
/// Curated books have a hand-picked edition in the catalogue. Every other book
/// gets one chosen from `palettes` by a stable hash of its title, so the same
/// book always looks the same.
struct Edition: Hashable {
    enum Pattern: String, CaseIterable {
        case dots, waves, lattice, stars, chevrons, leaves, checks, scallops, diamonds
    }

    /// Cloth and foil as hex, identical in light and dark: a book is an object, not a theme.
    let cloth: UInt32
    let foil: UInt32
    let pattern: Pattern

    var clothColor: Color { Color(hex: cloth) }
    var foilColor: Color { Color(hex: foil) }

    /// The edition used on paper: timeline, raised capitals, rules, buttons.
    /// The darker of the pair in light mode, the lighter in dark mode,
    /// so it always reads against the page.
    var ink: Color {
        Color(light: Self.darker(cloth, foil), dark: Self.lighter(cloth, foil))
    }

    /// Label colour for text set on `ink` (buttons): whichever of white or ink
    /// contrasts more. The crossover sits at a relative luminance of about 0.2.
    var onInk: Color {
        let lightBg = Self.darker(cloth, foil)
        let darkBg = Self.lighter(cloth, foil)
        return Color(
            light: Self.luminance(lightBg) > 0.2 ? 0x1C1A17 : 0xFFFFFF,
            dark: Self.luminance(darkBg) > 0.2 ? 0x1C1A17 : 0xFFFFFF
        )
    }

    // MARK: Palettes

    /// Cloth/foil pairs for books without a curated edition.
    static let palettes: [(cloth: UInt32, foil: UInt32)] = [
        (0xD46A7E, 0x4A1622), // rose / burgundy
        (0x10403F, 0xE9C46A), // teal / gold
        (0x34452F, 0xC9E46B), // moss / lime
        (0x2E3A7A, 0xF2B33D), // indigo / saffron
        (0xA3243A, 0xF8C9C4), // crimson / blush
        (0x1E5B48, 0xEBCB7B), // emerald / gold
        (0xE3A53A, 0x3B2C5E), // mustard / plum
        (0x8EC3E6, 0x1C2C4C), // sky / navy
        (0x1B2B4B, 0xE2B857), // navy / gold
        (0x5A4366, 0xCFE0B0), // heather / sage
        (0xE07A5F, 0x2B2D42), // terracotta / slate
        (0x3F6C96, 0xF4E9D8), // cornflower / cream
    ]

    /// The edition for any book: curated if the catalogue has it, otherwise hashed.
    static func of(_ book: Book) -> Edition {
        if let curated = Catalog.entry(for: book)?.edition { return curated }
        let seed = book.title.lowercased().unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        let pair = palettes[seed % palettes.count]
        let pattern = Pattern.allCases[(seed / palettes.count) % Pattern.allCases.count]
        return Edition(cloth: pair.cloth, foil: pair.foil, pattern: pattern)
    }

    // MARK: Colour maths

    static func luminance(_ hex: UInt32) -> Double {
        func channel(_ v: UInt32) -> Double {
            let c = Double(v) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel((hex >> 16) & 0xFF)
            + 0.7152 * channel((hex >> 8) & 0xFF)
            + 0.0722 * channel(hex & 0xFF)
    }

    private static func darker(_ a: UInt32, _ b: UInt32) -> UInt32 {
        luminance(a) <= luminance(b) ? a : b
    }

    private static func lighter(_ a: UInt32, _ b: UInt32) -> UInt32 {
        luminance(a) > luminance(b) ? a : b
    }
}
