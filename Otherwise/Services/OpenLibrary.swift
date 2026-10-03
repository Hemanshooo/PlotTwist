import Foundation

/// Book search and details from Open Library (openlibrary.org). Free, no key.
enum OpenLibrary {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "PlotTwist/1.0 (iOS)"]
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    // MARK: Search

    static func search(_ query: String) async throws -> [Book] {
        var components = URLComponents(string: "https://openlibrary.org/search.json")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "fields", value: "key,title,author_name,first_publish_year,cover_i"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        return response.docs.map {
            Book(id: $0.key, title: $0.title, author: $0.author_name?.first, year: $0.first_publish_year, coverID: $0.cover_i)
        }
    }

    // MARK: Browse

    /// One page of English-language novels and stories in a subject, the most
    /// often published first, and how many there are in all. Children's books
    /// and anything without an author are left out.
    static func fiction(about subject: String, offset: Int, limit: Int = 24) async throws -> (books: [Book], total: Int) {
        var query = "subject:\"\(subject)\" AND subject:Fiction AND language:eng"
        query += " AND NOT subject:\"Juvenile fiction\" AND NOT subject:\"Picture books\""
        var components = URLComponents(string: "https://openlibrary.org/search.json")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "sort", value: "editions"),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "fields", value: "key,title,author_name,first_publish_year,cover_i"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        let books = response.docs.compactMap { doc -> Book? in
            // A book needs an author to be told again.
            guard let author = doc.author_name?.first else { return nil }
            return Book(id: doc.key, title: doc.title, author: author, year: doc.first_publish_year, coverID: doc.cover_i)
        }
        return (books, response.numFound ?? 0)
    }

    // MARK: Details

    /// A short summary of the book (description + subjects), cleaned for display and for the model.
    struct Details {
        let summary: String?
        let subjects: [String]

        /// Grounding text for the model, capped to protect its context window.
        var modelContext: String? {
            var parts: [String] = []
            if let summary { parts.append(String(summary.prefix(900))) }
            if !subjects.isEmpty { parts.append("Subjects: " + subjects.prefix(8).joined(separator: ", ")) }
            return parts.isEmpty ? nil : parts.joined(separator: "\n")
        }
    }

    static func details(for book: Book) async throws -> Details {
        let url = URL(string: "https://openlibrary.org\(book.id).json")!
        let (data, _) = try await session.data(from: url)
        let work = try JSONDecoder().decode(Work.self, from: data)
        return Details(summary: work.description.map { clean($0.text) }, subjects: work.subjects ?? [])
    }

    /// Open Library descriptions often carry source links and footnotes. Keep the prose.
    private static func clean(_ text: String) -> String {
        var result = text
        for marker in ["----------", "([source]", "(Source:", "\r\n\r\n**"] {
            if let range = result.range(of: marker) { result = String(result[..<range.lowerBound]) }
        }
        return result
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Wire types

    private struct SearchResponse: Decodable {
        let numFound: Int?
        let docs: [Doc]
        struct Doc: Decodable {
            let key: String
            let title: String
            let author_name: [String]?
            let first_publish_year: Int?
            let cover_i: Int?
        }
    }

    private struct Work: Decodable {
        let description: TextValue?
        let subjects: [String]?
    }

    /// Open Library returns descriptions either as a string or as `{ "value": "…" }`.
    private enum TextValue: Decodable {
        case plain(String)
        case typed(String)

        var text: String {
            switch self {
            case .plain(let s), .typed(let s): s
            }
        }

        private struct Typed: Decodable { let value: String }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .plain(string)
            } else {
                self = .typed(try container.decode(Typed.self).value)
            }
        }
    }
}
