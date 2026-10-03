import SwiftUI
import SwiftData

@main
struct PlotTwistApp: App {
    init() {
        DS.registerFonts()
        DS.configureSystemAppearance()
    }

    var body: some Scene {
        WindowGroup {
            LibraryView()
        }
        .modelContainer(for: [Version.self, ShelfEntry.self])
    }
}
