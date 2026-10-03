import SwiftUI

/// Everything the reader shows, shared by every page so pages update live
/// while the story is being written.
@Observable
final class ReaderModel {
    enum Phase: Equatable {
        case writing
        case finished
        case failed(StoryEngine.Notice)
        case unavailable(StoryEngine.Notice)
    }

    enum Page: Hashable {
        case title, divergence, chapter(Int), ending, writing, colophon
    }

    let book: Book
    let edition: Edition
    let change: String
    let momentChapter: String?
    let momentHappened: String?

    var story = Story()
    var phase: Phase = .writing
    var isSaved = false

    init(request: StoryRequest) {
        book = request.book
        edition = Edition.of(request.book)
        change = request.change
        momentChapter = request.moment?.chapter
        momentHappened = request.moment?.happened
    }

    init(version: Version) {
        book = version.book
        edition = Edition.of(version.book)
        change = version.change
        momentChapter = version.momentChapter
        momentHappened = version.momentHappened
    }

    /// The book's pages, in order. A "writing" page stands at the end while
    /// the model is still writing; a colophon closes the book when it's done
    /// (or explains why the writing stopped).
    var pages: [Page] {
        var pages: [Page] = [.title, .divergence]
        pages += story.chapters.indices.map { .chapter($0) }
        if !story.ending.isEmpty { pages.append(.ending) }
        switch phase {
        case .writing: pages.append(.writing)
        case .finished, .failed: pages.append(.colophon)
        case .unavailable: break
        }
        return pages
    }

    func page(at index: Int) -> Page {
        let pages = pages
        return pages.indices.contains(index) ? pages[index] : .writing
    }

    /// True once there's something worth opening the cover for.
    var hasOpening: Bool {
        !story.title.isEmpty || !story.chapters.isEmpty
    }

    var shareText: String {
        story.shareText(book: book, change: change)
    }
}
