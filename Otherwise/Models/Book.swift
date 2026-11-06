import Foundation

/// A book as the app knows it: enough to show it, log it and ground a "What if".
struct Book: Identifiable, Hashable, Codable {
    /// Open Library work key, e.g. "/works/OL66554W".
    let id: String
    let title: String
    let author: String?
    let year: Int?
    let coverID: Int?
    /// Pages in a typical edition, when Open Library knows (for reading stats).
    var pages: Int? = nil

    enum CoverSize: String { case medium = "M", large = "L" }

    func coverURL(_ size: CoverSize) -> URL? {
        guard let coverID else { return nil }
        // `default=false` returns 404 instead of a blank image, so the cloth cover shows.
        return URL(string: "https://covers.openlibrary.org/b/id/\(coverID)-\(size.rawValue).jpg?default=false")
    }

    /// "Jane Austen · 1813"
    var byline: String? {
        let parts = [author, year.map(String.init)].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
