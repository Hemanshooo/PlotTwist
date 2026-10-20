import UIKit
import SwiftUI
import CoreText

extension DS {
    /// Registers the bundled serif (Resources/Fonts) used inside the books.
    /// Call once, before any view is drawn.
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

    /// Carries the room's colours into UIKit-drawn chrome: navigation titles,
    /// the search field, page indicators. The app is dark only.
    static func configureSystemAppearance() {
        let ink = UIColor(DS.Colors.ink)
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [.foregroundColor: ink]
        bar.titleTextAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .headline),
            .foregroundColor: ink,
        ]
        UISearchTextField.appearance().tintColor = UIColor(DS.Colors.accent)
    }
}

extension View {
    /// The whole app runs in the dark appearance, whatever the system setting.
    func dsDarkOnly() -> some View {
        self.preferredColorScheme(.dark)
    }
}
