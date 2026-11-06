import Foundation
import SwiftData

/// One reading of a book, as it goes in your diary: the day you finished it,
/// your rating and heart then, and what you thought. Reading a book again
/// makes a new entry.
@Model
final class DiaryEntry {
    var bookID: String = ""
    var title: String = ""
    var author: String?
    var year: Int?
    var coverID: Int?
    var pages: Int?
    /// The day you finished it.
    var readOn: Date = Date.now
    /// In half-roses, 0.5…5. Zero means not rated.
    var rating: Double = 0
    var liked: Bool = false
    var review: String = ""
    /// The review gives away the plot; it stays hidden until tapped.
    var hasSpoilers: Bool = false
    var isReread: Bool = false
    var createdAt: Date = Date.now

    init(book: Book, readOn: Date = .now, rating: Double = 0, liked: Bool = false, review: String = "",
         hasSpoilers: Bool = false, isReread: Bool = false) {
        self.bookID = book.id
        self.title = book.title
        self.author = book.author
        self.year = book.year
        self.coverID = book.coverID
        self.pages = book.pages
        self.readOn = readOn
        self.rating = rating
        self.liked = liked
        self.review = review
        self.hasSpoilers = hasSpoilers
        self.isReread = isReread
        self.createdAt = .now
    }

    var book: Book {
        Book(id: bookID, title: title, author: author, year: year, coverID: coverID, pages: pages)
    }

    var hasReview: Bool {
        !review.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// A line you kept from a book, for your commonplace book.
@Model
final class Quote {
    var bookID: String = ""
    var title: String = ""
    var author: String?
    var year: Int?
    var coverID: Int?
    var text: String = ""
    /// As printed: "34", "xii".
    var page: String = ""
    /// Why it stayed with you.
    var note: String = ""
    var createdAt: Date = Date.now

    init(book: Book, text: String, page: String = "", note: String = "") {
        self.bookID = book.id
        self.title = book.title
        self.author = book.author
        self.year = book.year
        self.coverID = book.coverID
        self.text = text
        self.page = page
        self.note = note
        self.createdAt = .now
    }

    var book: Book {
        Book(id: bookID, title: title, author: author, year: year, coverID: coverID)
    }

    /// "Jane Austen, Pride and Prejudice · p. 34"
    var citation: String {
        var parts: [String] = []
        if let author { parts.append(author) }
        parts.append(title)
        var line = parts.joined(separator: ", ")
        let trimmed = page.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { line += " · p. \(trimmed)" }
        return line
    }
}

/// You: your name, a line about you, your favourite four and this year's goal.
/// There's only ever one.
@Model
final class Profile {
    var name: String = ""
    var bio: String = ""
    /// Your favourite four, in order, as JSON: simple, and stable across schema changes.
    var favouritesData: Data = Data()
    /// Books to read this year; zero means no goal.
    var readingGoal: Int = 0
    var createdAt: Date = Date.now

    init() {
        self.createdAt = .now
    }

    var favourites: [Book] {
        get { (try? JSONDecoder().decode([Book].self, from: favouritesData)) ?? [] }
        set { favouritesData = (try? JSONEncoder().encode(Array(newValue.prefix(4)))) ?? Data() }
    }

    /// The one profile, made the first time it's needed.
    @MainActor
    static func current(in context: ModelContext) -> Profile {
        var descriptor = FetchDescriptor<Profile>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first { return existing }
        let profile = Profile()
        context.insert(profile)
        try? context.save()
        return profile
    }
}
