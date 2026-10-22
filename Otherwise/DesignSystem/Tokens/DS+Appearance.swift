import UIKit
import SwiftUI
import CoreText

extension DS {
    /// Registers the bundled faces (Resources/Fonts). Call once, before any view is drawn.
    static func registerFonts() {
        guard let root = Bundle.main.resourceURL,
              let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        else { return }
        let fonts = files.compactMap { $0 as? URL }.filter { $0.pathExtension == "ttf" }
        for url in fonts {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        #if DEBUG
        for face in Typography.Face.allCases where UIFont(name: face.rawValue, size: 12) == nil {
            assertionFailure("Missing bundled font \(face.rawValue)")
        }
        #endif
    }

    /// Carries the palette into UIKit-drawn chrome: navigation titles and the
    /// search field. Called at launch and whenever the palette changes.
    static func configureSystemAppearance() {
        let ink = UIColor(DS.Colors.ink)
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [.foregroundColor: ink]
        bar.titleTextAttributes = [
            .font: UIFont(name: Typography.Face.monoMedium.rawValue, size: 13) ?? UIFont.preferredFont(forTextStyle: .headline),
            .foregroundColor: ink,
        ]
        UISearchTextField.appearance().tintColor = ink
    }
}

extension View {
    /// System chrome (status bar, keyboard, alerts, sheets) follows the
    /// palette: dark on Rose noir, Midnight and Citrus, light on Paper.
    func dsColorScheme() -> some View {
        self.preferredColorScheme(Theme.shared.palette.scheme.isDark ? .dark : .light)
    }
}
