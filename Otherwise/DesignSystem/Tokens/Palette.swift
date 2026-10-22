import SwiftUI

/// The rooms Plot Twist can be read in. Each is a ground, an ink, and the
/// two colours of the garden that grows through the app: the stems (and
/// leaves), and the blooms.
///
/// Rose noir is the default. The reader picks another from the palette
/// sheet (the swatch next to the wordmark), and the whole app recolours at once.
enum Palette: String, CaseIterable, Identifiable {
    case roseNoir, paper, midnight, citrus

    var id: String { rawValue }

    var name: LocalizedStringKey {
        switch self {
        case .roseNoir: "Rose noir"
        case .paper: "Paper"
        case .midnight: "Midnight"
        case .citrus: "Citrus"
        }
    }

    /// Every colour of one palette.
    struct Scheme {
        /// The ground every screen sits on.
        let canvas: Color
        /// Panels and fields: a step off the ground.
        let surface: Color
        /// Selected and pressed things, folds: a step further.
        let raised: Color
        /// Primary text, the selected pill, the primary button.
        let ink: Color
        /// Supporting text: bylines, descriptions, unselected icons.
        let inkSecondary: Color
        /// Hints, placeholders, folios, sealed things.
        let inkTertiary: Color
        /// Separators and outlines.
        let hairline: Color
        /// Stems, leaves and tendrils.
        let stem: Color
        /// Roses and buds; raised capitals, ribbons.
        let bloom: Color
        /// The lines drawn inside a rose.
        let petal: Color
        /// Destructive actions.
        let caution: Color
        /// A page in the reader, and the text printed on it.
        let page: Color
        let pageInk: Color
        /// Every shadow.
        let shadow: Color
        /// Whether system chrome (status bar, keyboards, alerts) runs dark.
        let isDark: Bool
        /// How strongly distant books in the stack fade: negative sinks them
        /// into shadow (dark grounds), positive into haze (light grounds).
        let fog: Double
        /// How much a lying cover darkens toward its far edge.
        let coverFalloff: Double
    }

    var scheme: Scheme { Self.schemes[self] ?? makeScheme() }

    /// Built once: tokens are read on every frame of some animations.
    private static let schemes: [Palette: Scheme] = Dictionary(
        uniqueKeysWithValues: allCases.map { ($0, $0.makeScheme()) }
    )

    private func makeScheme() -> Scheme {
        switch self {
        case .roseNoir:
            Scheme(
                canvas: Color(hex: 0x000000),
                surface: Color(hex: 0x0D0D0D),
                raised: Color(hex: 0x1C1C1C),
                ink: Color(hex: 0xFFFFFF),
                inkSecondary: Color(hex: 0xA6A6A6),
                inkTertiary: Color(hex: 0x6B6B6B),
                hairline: Color.white.opacity(0.16),
                stem: Color(hex: 0x3257FF),
                bloom: Color(hex: 0xFF1400),
                petal: Color(hex: 0xFFB4A8),
                caution: Color(hex: 0xFF4A3A),
                page: Color(hex: 0x0B0B0B),
                pageInk: Color(hex: 0xEDE9E1),
                shadow: Color(hex: 0x000000),
                isDark: true,
                fog: -0.24,
                coverFalloff: 0.5
            )
        case .paper:
            Scheme(
                canvas: Color(hex: 0xF3EEE4),
                surface: Color(hex: 0xECE5D7),
                raised: Color(hex: 0xE2D9C8),
                ink: Color(hex: 0x111111),
                inkSecondary: Color(hex: 0x5A544B),
                inkTertiary: Color(hex: 0x948C80),
                hairline: Color(hex: 0x111111).opacity(0.14),
                stem: Color(hex: 0x1C2B8F),
                bloom: Color(hex: 0xFF3B1F),
                petal: Color(hex: 0xFFD2C4),
                caution: Color(hex: 0xC92A12),
                page: Color(hex: 0xF8F4EC),
                pageInk: Color(hex: 0x1A1714),
                shadow: Color(hex: 0x2A2118),
                isDark: false,
                fog: 0.1,
                coverFalloff: 0.3
            )
        case .midnight:
            Scheme(
                canvas: Color(hex: 0x0C1445),
                surface: Color(hex: 0x121C55),
                raised: Color(hex: 0x1C2768),
                ink: Color(hex: 0xF5F2FF),
                inkSecondary: Color(hex: 0xA7AEDB),
                inkTertiary: Color(hex: 0x6871A8),
                hairline: Color.white.opacity(0.16),
                stem: Color(hex: 0x9C8CFF),
                bloom: Color(hex: 0xFF6B57),
                petal: Color(hex: 0xFFD3CB),
                caution: Color(hex: 0xFF7A68),
                page: Color(hex: 0x0F1849),
                pageInk: Color(hex: 0xECE8F7),
                shadow: Color(hex: 0x03061A),
                isDark: true,
                fog: -0.2,
                coverFalloff: 0.5
            )
        case .citrus:
            Scheme(
                canvas: Color(hex: 0x0E1A12),
                surface: Color(hex: 0x14241A),
                raised: Color(hex: 0x1D3324),
                ink: Color(hex: 0xF4F7EF),
                inkSecondary: Color(hex: 0xA5B8A8),
                inkTertiary: Color(hex: 0x637A68),
                hairline: Color.white.opacity(0.15),
                stem: Color(hex: 0x3CC46D),
                bloom: Color(hex: 0xFF8A1E),
                petal: Color(hex: 0xFFE1B5),
                caution: Color(hex: 0xFF9A3C),
                page: Color(hex: 0x101D15),
                pageInk: Color(hex: 0xECEFE6),
                shadow: Color(hex: 0x040906),
                isDark: true,
                fog: -0.2,
                coverFalloff: 0.5
            )
        }
    }
}

/// The palette the app is shown in. Observable, so every view that reads a
/// colour token redraws when the reader picks another palette.
@Observable
final class Theme {
    static let shared = Theme()
    private static let key = "theme.palette"

    private(set) var palette: Palette

    private init() {
        palette = UserDefaults.standard.string(forKey: Self.key).flatMap(Palette.init(rawValue:)) ?? .roseNoir
    }

    /// Switches the whole app to `palette` and remembers it.
    func choose(_ palette: Palette) {
        self.palette = palette
        UserDefaults.standard.set(palette.rawValue, forKey: Self.key)
        DS.configureSystemAppearance()
    }
}
