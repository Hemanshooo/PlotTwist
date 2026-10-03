import Foundation
import Observation

/// The endless part of the library: after the hand-mapped classics, more books
/// load from Open Library as you near the bottom of the stack: English-language
/// fiction, classics first, then a run of genres, the most-published books first,
/// skipping anything already shown.
@MainActor
@Observable
final class LibraryFeed {
    private(set) var books: [Book] = []
    private(set) var isLoading = false
    /// The last page failed (usually no connection); the stack offers a retry.
    private(set) var failed = false
    /// Every subject has been read to the end.
    private(set) var isExhausted = false

    /// English-language fiction, the best-known first: classics, then a run of genres.
    private let subjects = [
        "Classic Literature", "Literary fiction", "Adventure stories", "Detective and mystery stories",
        "Love stories", "Historical fiction", "Fantasy fiction", "Science fiction", "Horror tales",
        "Humorous stories", "Short stories",
    ]
    private var subjectIndex = 0
    private var offset = 0
    private var seenIDs: Set<String> = []
    private var seenTitles: Set<String> = []
    private let pageSize = 24

    /// Loads the next page that has anything new in it. Safe to call repeatedly.
    func loadMore() async {
        guard !isLoading, !isExhausted else { return }
        isLoading = true
        failed = false
        defer { isLoading = false }

        // Keep going until a page adds something, so a run of duplicates
        // never leaves the stack looking finished.
        while subjectIndex < subjects.count {
            do {
                let page = try await OpenLibrary.fiction(about: subjects[subjectIndex], offset: offset, limit: pageSize)
                offset += pageSize
                if page.books.isEmpty || offset >= page.total {
                    subjectIndex += 1
                    offset = 0
                }
                let fresh = page.books.filter(isNew)
                if !fresh.isEmpty {
                    books.append(contentsOf: fresh)
                    return
                }
            } catch {
                if !Task.isCancelled { failed = true }
                return
            }
        }
        isExhausted = true
    }

    /// Books already in the catalogue, or already loaded under another
    /// edition, aren't shown twice.
    private func isNew(_ book: Book) -> Bool {
        let title = Self.normalized(book.title)
        guard Self.isLatinScript(book.title),
              Catalog.entry(for: book) == nil,
              !seenIDs.contains(book.id),
              !seenTitles.contains(title)
        else { return false }
        seenIDs.insert(book.id)
        seenTitles.insert(title)
        return true
    }

    /// Open Library sometimes lists a work under its original title (the
    /// Iliad as "Ἰλιάς"). Keep titles a reader of the app can read: Latin
    /// letters, with accents.
    private static func isLatinScript(_ title: String) -> Bool {
        title.unicodeScalars.allSatisfy { scalar in
            !scalar.properties.isAlphabetic
                || scalar.value < 0x0250                       // Basic Latin … Latin Extended-B
                || (0x1E00...0x1EFF).contains(scalar.value)    // Latin Extended Additional
        }
    }

    private static func normalized(_ title: String) -> String {
        title.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
