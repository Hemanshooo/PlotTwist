import Foundation
import SwiftData

/// A saved alternate version. Written automatically when a story finishes.
@Model
final class Version {
    var createdAt: Date
    var bookID: String
    var bookTitle: String
    var bookAuthor: String?
    var bookYear: Int?
    var bookCoverID: Int?
    var change: String
    var title: String
    var ending: String
    /// Chapters stored as JSON: simple, and stable across schema changes.
    var chaptersData: Data
    /// The turning point that was changed, if it came from the story map.
    var momentChapter: String?
    var momentTitle: String?
    var momentHappened: String?

    init(request: StoryRequest, story: Story) {
        self.createdAt = .now
        self.bookID = request.book.id
        self.bookTitle = request.book.title
        self.bookAuthor = request.book.author
        self.bookYear = request.book.year
        self.bookCoverID = request.book.coverID
        self.change = request.change
        self.title = story.title
        self.ending = story.ending
        self.chaptersData = (try? JSONEncoder().encode(story.chapters)) ?? Data()
        self.momentChapter = request.moment?.chapter
        self.momentTitle = request.moment?.title
        self.momentHappened = request.moment?.happened
    }

    var book: Book {
        Book(id: bookID, title: bookTitle, author: bookAuthor, year: bookYear, coverID: bookCoverID)
    }

    var story: Story {
        let chapters = (try? JSONDecoder().decode([Story.Chapter].self, from: chaptersData)) ?? []
        return Story(title: title, chapters: chapters, ending: ending)
    }
}

/// A book on the reader's shelf, and how far they've read it.
/// Only books the reader has started or finished live here.
@Model
final class ShelfEntry {
    @Attribute(.unique) var bookID: String
    var title: String
    var author: String?
    var year: Int?
    var coverID: Int?
    /// 0…1. 1 means finished.
    var progress: Double
    var updatedAt: Date

    init(book: Book, progress: Double) {
        self.bookID = book.id
        self.title = book.title
        self.author = book.author
        self.year = book.year
        self.coverID = book.coverID
        self.progress = progress
        self.updatedAt = .now
    }

    var book: Book {
        Book(id: bookID, title: title, author: author, year: year, coverID: coverID)
    }

    var isFinished: Bool { progress >= 0.999 }
}
