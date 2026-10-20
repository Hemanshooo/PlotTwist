import SwiftUI

/// How a book is bound: a cloth colour, a foil colour and a stamped pattern.
///
/// Inspired by clothbound classics, every book in Plot Twist gets its own
/// edition. On the black room it is the main source of colour: covers, spines,
/// the glow at the top of the book's screen, its gauge, timeline and buttons,
/// and the reader's raised capitals all come from the book's edition.
///
/// Curated books have a hand-picked edition in the catalogue. Every other book
/// gets one chosen from `palettes` by a stable hash of its title, so the same
/// book always looks the same.
struct Edition: Hashable {
    enum Pattern: String, CaseIterable {
        case dots, waves, lattice, stars, chevrons, leaves, checks, scallops, diamonds
    }

    /// Cloth and foil as hex: a book is an object, not a theme.
    let cloth: UInt32
    let foil: UInt32
    let pattern: Pattern

    var clothColor: Color { Color(hex: cloth) }
    var foilColor: Color { Color(hex: foil) }

    /// The edition's light on the black: the brighter of cloth and foil,
    /// lifted if it's too dark to read. Used for numerals, rules, the
    /// timeline, raised capitals and the tint of the book's screens.
    var ink: Color { Color(hex: Self.inkHex(cloth, foil)) }

    /// The glow behind a book's screen and under its spine: the cloth's own
    /// colour, unless the cloth is nearly black, when the foil glows instead.
    var glow: Color {
        Color(hex: Self.luminance(cloth) < 0.035 ? foil : cloth)
    }

    /// Label colour for text set on `ink`.
    var onInk: Color {
        Self.luminance(Self.inkHex(cloth, foil)) > 0.25 ? Color(hex: 0x0B0C0C) : .white
    }

    /// The gradient for this book's arcs and glowing buttons.
    var gradientColors: [Color] { [glow, ink] }

    /// Foil for lettering stamped on the cloth (spines): the edition's foil,
    /// pushed lighter or darker, keeping its hue, until it reads against the
    /// cloth at 4.5:1.
    var lettering: Color { Color(hex: Self.legibleFoil(foil, on: cloth)) }

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

    /// The brighter of the pair, mixed toward white until it reads on black (≥ 0.2 luminance).
    private static func inkHex(_ a: UInt32, _ b: UInt32) -> UInt32 {
        var color = luminance(a) > luminance(b) ? a : b
        var steps = 0
        while luminance(color) < 0.2, steps < 10 {
            color = mix(color, 0xFFFFFF, 0.18)
            steps += 1
        }
        return color
    }

    static func contrast(_ a: UInt32, _ b: UInt32) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    /// The foil, moved away from the cloth's brightness in small steps until
    /// the pair reaches 4.5:1.
    private static func legibleFoil(_ foil: UInt32, on cloth: UInt32) -> UInt32 {
        let target: UInt32 = luminance(foil) >= luminance(cloth) ? 0xFFFFFF : 0x000000
        var color = foil
        var steps = 0
        while contrast(color, cloth) < 4.5, steps < 12 {
            color = mix(color, target, 0.15)
            steps += 1
        }
        // A foil darker than its cloth that still can't reach 4.5:1 (mid-tone
        // cloth) reads better turned light.
        if contrast(color, cloth) < 4.5 {
            var light = foil
            steps = 0
            while contrast(light, cloth) < 4.5, steps < 12 {
                light = mix(light, 0xFFFFFF, 0.15)
                steps += 1
            }
            if contrast(light, cloth) > contrast(color, cloth) { color = light }
        }
        return color
    }

    private static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        func channel(_ shift: UInt32) -> UInt32 {
            let x = Double((a >> shift) & 0xFF), y = Double((b >> shift) & 0xFF)
            return UInt32((x + (y - x) * t).rounded()) << shift
        }
        return channel(16) | channel(8) | channel(0)
    }
}
