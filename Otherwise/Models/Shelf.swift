import SwiftUI
import SwiftData

/// Where a book sits on your shelves.
enum ShelfStatus: String, CaseIterable, Identifiable, Codable {
    case toRead, reading, read, didNotFinish

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .toRead: "To read"
        case .reading: "Reading"
        case .read: "Read"
        case .didNotFinish: "Didn’t finish"
        }
    }

    /// The shelves the home stack switches between.
    static let shelves: [ShelfStatus] = [.reading, .toRead, .read]
}

/// A book on one of your shelves: want to read, reading, read, or put down.
/// Your rating and heart for the book live here; each time you finish it, a
/// diary entry records that reading.
///
/// Every property has a default, and none is unique, so the store can sync
/// through iCloud (CloudKit) once that's switched on.
@Model
final class ShelfEntry {
    var bookID: String = ""
    var title: String = ""
    var author: String?
    var year: Int?
    var coverID: Int?
    var pages: Int?
    /// 0…1. 1 means finished.
    var progress: Double = 0
    var updatedAt: Date = Date.now
    /// When it first went on a shelf.
    var addedAt: Date = Date.now
    /// A `ShelfStatus`. Empty for books saved before shelves existed, which
    /// are worked out from their progress.
    var statusRaw: String = ""
    /// Your rating in half-roses, 0.5…5. Zero means not rated.
    var rating: Double = 0
    /// The heart: a book you loved.
    var liked: Bool = false

    init(book: Book, status: ShelfStatus, progress: Double = 0) {
        self.bookID = book.id
        self.title = book.title
        self.author = book.author
        self.year = book.year
        self.coverID = book.coverID
        self.pages = book.pages
        self.statusRaw = status.rawValue
        self.progress = status == .read ? 1 : progress
        self.updatedAt = .now
        self.addedAt = .now
    }

    var book: Book {
        Book(id: bookID, title: title, author: author, year: year, coverID: coverID, pages: pages)
    }

    var status: ShelfStatus {
        get { ShelfStatus(rawValue: statusRaw) ?? (progress >= 0.999 ? .read : .reading) }
        set { statusRaw = newValue.rawValue }
    }

    var isFinished: Bool { status == .read }

    /// How much of the story map to show: everything once it's read.
    var reading: ReadingProgress {
        switch status {
        case .read: .finished
        case .reading, .didNotFinish: ReadingProgress(fraction: progress)
        case .toRead: .notStarted
        }
    }
}

// MARK: - Changing the shelves

/// Every change to your shelves, diary and quotes goes through here, so the
/// shelf, the diary and the rating always agree.
@MainActor
enum Library {
    static func entry(for book: Book, in context: ModelContext) -> ShelfEntry? {
        let id = book.id
        var descriptor = FetchDescriptor<ShelfEntry>(predicate: #Predicate { $0.bookID == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// The book's entry, put on a shelf if it isn't on one yet.
    @discardableResult
    static func shelve(_ book: Book, as status: ShelfStatus, in context: ModelContext) -> ShelfEntry {
        if let entry = entry(for: book, in: context) {
            entry.status = status
            if status == .read { entry.progress = 1 }
            if status == .toRead { entry.progress = 0 }
            if entry.pages == nil { entry.pages = book.pages }
            entry.updatedAt = .now
            save(context)
            return entry
        }
        let entry = ShelfEntry(book: book, status: status)
        context.insert(entry)
        save(context)
        return entry
    }

    /// Off every shelf. Diary entries and quotes stay.
    static func unshelve(_ book: Book, in context: ModelContext) {
        if let entry = entry(for: book, in: context) {
            context.delete(entry)
            save(context)
        }
    }

    static func setProgress(_ fraction: Double, for book: Book, in context: ModelContext) {
        let entry = entry(for: book, in: context) ?? shelve(book, as: .reading, in: context)
        entry.progress = min(max(fraction, 0), 1)
        if entry.status != .reading { entry.status = .reading }
        entry.updatedAt = .now
        save(context)
    }

    static func rate(_ book: Book, _ rating: Double, in context: ModelContext) {
        let entry = entry(for: book, in: context) ?? shelve(book, as: .read, in: context)
        entry.rating = rating
        entry.updatedAt = .now
        save(context)
    }

    static func setLiked(_ book: Book, _ liked: Bool, in context: ModelContext) {
        let entry = entry(for: book, in: context) ?? shelve(book, as: .read, in: context)
        entry.liked = liked
        entry.updatedAt = .now
        save(context)
    }

    /// Records a finished reading in the diary, and marks the book read with
    /// that rating and heart.
    static func log(_ diary: DiaryEntry, in context: ModelContext) {
        if diary.modelContext == nil { context.insert(diary) }
        let entry = entry(for: diary.book, in: context) ?? shelve(diary.book, as: .read, in: context)
        entry.status = .read
        entry.progress = 1
        if diary.rating > 0 { entry.rating = diary.rating }
        if diary.liked { entry.liked = true }
        entry.updatedAt = .now
        save(context)
    }

    static func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("[Endpaper] Couldn’t save: \(error)")
        }
    }
}
