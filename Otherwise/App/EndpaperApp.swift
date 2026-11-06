import SwiftUI
import SwiftData

@main
struct EndpaperApp: App {
    init() {
        DS.registerFonts()
        DS.configureSystemAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(Store.container)
    }
}
