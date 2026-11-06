import Foundation
import SwiftData

/// Where everything you keep is stored: on this iPhone, in one SwiftData store.
///
/// Every model has defaults for all its properties and no unique attributes,
/// so the same store can sync through iCloud once the app has the iCloud
/// capability (which needs a paid Apple Developer account).
enum Store {
    static let schema = Schema([
        Version.self,
        ShelfEntry.self,
        DiaryEntry.self,
        Quote.self,
        Profile.self,
    ])

    @MainActor
    static let container: ModelContainer = {
        // The same store Plot Twist used, so shelves and stories carry over.
        let configuration = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // Never crash on launch: if the old store can't be opened, start a
            // new one beside it and leave the old file untouched.
            print("[Endpaper] Couldn’t open the store, starting a new one: \(error)")
            let fresh = ModelConfiguration("Endpaper", schema: schema)
            if let container = try? ModelContainer(for: schema, configurations: fresh) { return container }
            let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: memory)
        }
    }()

    /// For previews: an empty store in memory.
    @MainActor
    static func preview() -> ModelContainer {
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: memory)
    }
}
