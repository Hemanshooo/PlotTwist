import Foundation

/// What ChatGPT found when it read a whole book from Project Gutenberg, built
/// once by `Tools/bookguide/build.py` and bundled with the app: the main
/// characters, a summary of every chapter, and the turning points, each with
/// the original passage cut word for word from the book.
///
/// The on-device model can only hold about 3,000 words at a time, so it never
/// sees the book itself. Each twist gets just the part of the guide it needs
/// (see `grounding(for:)`).
struct BookGuide: Decodable, Hashable {
    let slug: String
    let gutenbergID: Int
    let book: Book
    let premise: String
    let characters: [Person]
    let chapters: [Chapter]
    let moments: [GuidedMoment]

    struct Person: Decodable, Hashable {
        let name: String
        let aliases: [String]
        let description: String
    }

    struct Chapter: Decodable, Hashable {
        let label: String
        let summary: String
    }

    struct GuidedMoment: Decodable, Hashable {
        let id: String
        let chapter: String
        let position: Double
        let title: String
        let happened: String
        let alternatives: [String]
        let characters: [String]
        /// The original scene, word for word. Missing if the builder couldn't find it.
        let passage: String?
        /// What this led to later in the original. Spoilers: only the model sees it.
        let aftermath: String
    }

    var map: StoryMap {
        StoryMap(
            premise: premise,
            moments: moments.map {
                Moment(id: $0.id, chapter: $0.chapter, position: $0.position, title: $0.title,
                       happened: $0.happened, alternatives: $0.alternatives)
            },
            isCurated: true
        )
    }

    // MARK: Grounding a twist

    /// For a change at a turning point: the scene as written, who's in it, and what followed.
    func grounding(for moment: Moment) -> Grounding? {
        guard let guided = moments.first(where: { $0.id == moment.id }) else { return nil }
        let people = guided.characters.compactMap { name in characters.first { $0.name == name } }
        return Grounding(
            passage: guided.passage.map { Self.trim($0, to: Budget.passage) },
            people: Self.describe(people),
            aftermath: Self.trim(guided.aftermath, to: Budget.aftermath),
            context: []
        )
    }

    /// The opening lines of the moment's scene, to show the reader.
    func excerpt(for moment: Moment) -> String? {
        guard let passage = moments.first(where: { $0.id == moment.id })?.passage,
              let first = passage.components(separatedBy: "\n\n").first
        else { return nil }
        return Self.trim(first, to: 240)
    }

    /// For a change off the map: the characters it names, and the chapters it seems to be about.
    func grounding(forChange change: String) -> Grounding {
        let words = Self.keywords(change)
        var people = characters.filter { person in
            ([person.name] + person.aliases).contains { Self.mentions(change, name: $0) }
        }
        // Nobody named: the leads, so the model knows whose story it is.
        if people.isEmpty { people = Array(characters.prefix(2)) }

        let names = Set(people.flatMap { ([$0.name] + $0.aliases).flatMap(Self.keywords) })
        let scored = chapters.enumerated().map { index, chapter -> (Int, Int) in
            let summary = Self.keywords(chapter.summary)
            let topic = words.subtracting(names)
            // Words of the change count most; the characters it names break ties.
            return (index, summary.intersection(topic).count * 3 + summary.intersection(names).count)
        }
        let chosen = scored
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map(\.0)
            .sorted()
        var context: [String] = []
        var used = 0
        for index in chosen {
            let line = "\(chapters[index].label): \(chapters[index].summary)"
            guard used + line.count <= Budget.context else { break }
            context.append(line)
            used += line.count
        }
        return Grounding(passage: nil, people: Self.describe(people), aftermath: nil, context: context)
    }

    /// How much of each part the prompt can carry, in characters (about four to a token).
    /// Together with the instructions and a 1,100-token answer they stay well inside
    /// the on-device model's 4,096 tokens.
    private enum Budget {
        static let passage = 1_600
        static let person = 240
        static let people = 4
        static let aftermath = 450
        static let context = 1_200
    }

    private static func describe(_ people: [Person]) -> [String] {
        people.prefix(Budget.people).map { trim("\($0.name): \($0.description)", to: Budget.person) }
    }

    /// Cut at the last sentence that fits, so the model never reads half a thought.
    static func trim(_ text: String, to limit: Int) -> String {
        guard text.count > limit else { return text }
        let cut = String(text.prefix(limit))
        if let end = cut.lastIndex(where: { ".!?”\"".contains($0) }), cut.distance(from: cut.startIndex, to: end) > limit / 2 {
            return String(cut[...end])
        }
        return cut.trimmingCharacters(in: .whitespaces) + "…"
    }

    /// Whether `text` names someone: "Darcy" finds Mr. Darcy, "Elizabeth" finds
    /// Elizabeth Bennet (but "Bennet" alone doesn't pick out one sister), and
    /// "Jo" finds Jo but not Joe.
    static func mentions(_ text: String, name: String) -> Bool {
        let core = name.split(separator: " ").map(String.init)
            .filter { !stopwords.contains($0.lowercased().trimmingCharacters(in: .punctuationCharacters)) }
        guard let given = core.first else { return false }
        let candidates = Set([name, core.joined(separator: " "), given]).filter { $0.count >= 2 }
        return candidates.contains { candidate in
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: candidate) + "\\b"
            return text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    private static let stopwords: Set<String> = [
        "a", "an", "and", "the", "of", "to", "in", "on", "at", "for", "with", "by", "from", "her", "his", "him",
        "she", "he", "they", "them", "their", "is", "was", "were", "be", "been", "are", "instead", "never",
        "does", "did", "not", "no", "what", "if", "who", "that", "this", "it", "its", "as", "into", "after",
        "before", "than", "then", "so", "but", "or", "would", "could", "mr", "mrs", "miss", "sir", "lady", "lord",
    ]

    static func keywords(_ text: String) -> Set<String> {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        let words = folded.split { !$0.isLetter && $0 != "'" && $0 != "’" }
            .map { $0.replacingOccurrences(of: "’", with: "'") }
            .map { $0.hasSuffix("'s") ? String($0.dropLast(2)) : $0 }
            .filter { $0.count > 2 && !stopwords.contains($0) }
        return Set(words)
    }
}

/// The parts of a guide a twist is written from.
struct Grounding: Hashable {
    /// The original scene, word for word.
    var passage: String?
    /// "Name: who they are", for the characters involved.
    var people: [String]
    /// What happened next in the original.
    var aftermath: String?
    /// Chapter summaries an off-map change seems to be about.
    var context: [String]
}

/// Every guide bundled with the app.
enum Guides {
    static let all: [BookGuide] = {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "Guides") ?? [])
        let decoder = JSONDecoder()
        var guides: [String: BookGuide] = [:]
        for url in urls where url.lastPathComponent.hasSuffix(".guide.json") {
            do {
                let guide = try decoder.decode(BookGuide.self, from: Data(contentsOf: url))
                guides[guide.slug] = guide
            } catch {
                print("[PlotTwist] Couldn't read \(url.lastPathComponent): \(error)")
            }
        }
        return guides.values.sorted { $0.book.title < $1.book.title }
    }()

    static func guide(slug: String) -> BookGuide? {
        all.first { $0.slug == slug }
    }
}
