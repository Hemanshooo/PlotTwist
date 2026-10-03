import Foundation

/// An alternate version of a book, as the interface displays it.
/// Kept independent of the model framework so views and storage never depend on it.
struct Story: Hashable, Codable {
    var title: String = ""
    var chapters: [Chapter] = []
    var ending: String = ""

    struct Chapter: Hashable, Codable {
        var heading: String
        var text: String
    }

    var isEmpty: Bool { title.isEmpty && chapters.isEmpty && ending.isEmpty }

    /// Plain-text version for sharing.
    func shareText(book: Book, change: String) -> String {
        var lines: [String] = []
        lines.append(title.isEmpty ? book.title : title)
        lines.append("\(book.title), otherwise: “\(change)”")
        lines.append("")
        for chapter in chapters {
            if !chapter.heading.isEmpty { lines.append(chapter.heading) }
            lines.append(chapter.text)
            lines.append("")
        }
        if !ending.isEmpty {
            lines.append(ending)
            lines.append("")
        }
        lines.append("Written with Plot Twist")
        return lines.joined(separator: "\n")
    }
}

/// What the reader asked for. Drives a new story.
struct StoryRequest: Identifiable, Hashable {
    let id = UUID()
    let book: Book
    /// The turning point being changed. `nil` for a change that isn't on the map.
    let moment: Moment?
    let change: String
    /// The premise and the moments leading up to the change, used to ground the model.
    let premise: String
    let earlierMoments: [Moment]
}
