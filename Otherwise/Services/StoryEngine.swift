import Foundation
import FoundationModels

/// Writes alternate stories, and draws story maps for books outside the
/// catalogue, on device with Apple Intelligence (Foundation Models).
/// Nothing the reader writes leaves the phone.
enum StoryEngine {

    // MARK: Availability

    struct Notice: Equatable {
        let symbol: String
        let title: String
        let message: String
    }

    /// `nil` when the model is ready; otherwise what to tell the reader.
    static var unavailableNotice: Notice? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.appleIntelligenceNotEnabled):
            return Notice(
                symbol: "apple.intelligence",
                title: "Turn on Apple Intelligence",
                message: "Plot Twist writes every story on your iPhone. Turn on Apple Intelligence in Settings to begin."
            )
        case .unavailable(.modelNotReady):
            return Notice(
                symbol: "arrow.down.circle",
                title: "Almost ready",
                message: "Apple Intelligence is still getting ready on this iPhone. Try again in a few minutes."
            )
        case .unavailable(.deviceNotEligible):
            return Notice(
                symbol: "iphone.slash",
                title: "Not available on this iPhone",
                message: "Plot Twist needs an iPhone that supports Apple Intelligence."
            )
        case .unavailable:
            return Notice(
                symbol: "exclamationmark.circle",
                title: "Unavailable right now",
                message: "Apple Intelligence can’t be reached at the moment. Try again later."
            )
        }
    }

    // MARK: Story maps

    /// Draws a story map for a book that isn't in the catalogue.
    static func storyMap(for book: Book, context: String?) async throws -> StoryMap {
        let session = LanguageModelSession(instructions: StoryInstructions.map)
        let response = try await session.respond(
            to: Prompts.book(book, context: context),
            generating: GeneratedMap.self,
            options: GenerationOptions(temperature: 0.4)
        )
        // Small models sometimes repeat a moment; keep the first of each title.
        var seen = Set<String>()
        let generated = response.content.moments.filter { seen.insert($0.title.lowercased()).inserted }
        let moments = generated.enumerated().map { index, m in
            Moment(
                id: "gen-\(index)",
                chapter: m.chapter,
                position: (Double(index) + 0.5) / Double(max(generated.count, 1)),
                title: m.title,
                happened: m.happened,
                alternatives: m.alternatives.filter { !$0.isEmpty }
            )
        }
        return StoryMap(premise: response.content.premise, moments: moments, isCurated: false)
    }

    // MARK: Stories

    /// Streams the story as it is written. Each element is the whole story so far.
    ///
    /// Generated as plain text with permissive content guardrails: classic novels
    /// are full of duels, deaths and betrayals, and the default guardrails refuse
    /// too many legitimate retellings.
    static func write(_ request: StoryRequest) -> AsyncThrowingStream<Story, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
                    let session = LanguageModelSession(model: model, instructions: StoryInstructions.story)
                    let stream = session.streamResponse(
                        to: Prompts.story(request),
                        // Capped so a rambling answer stops instead of overflowing the 4K context window.
                        options: GenerationOptions(temperature: 0.7, maximumResponseTokens: 1100)
                    )
                    var raw = ""
                    for try await snapshot in stream {
                        raw = snapshot.content
                        continuation.yield(StoryParser.parse(raw))
                    }
                    #if DEBUG
                    print("[PlotTwist] Story text:\n\(raw)")
                    #endif
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: Errors

    static func notice(for error: Error) -> Notice {
        if let error = error as? LanguageModelSession.GenerationError {
            switch error {
            case .guardrailViolation, .refusal:
                return Notice(
                    symbol: "hand.raised",
                    title: "This change can’t be written",
                    message: "Apple Intelligence declined this one. Try a different change."
                )
            case .exceededContextWindowSize:
                return Notice(
                    symbol: "text.badge.xmark",
                    title: "Too much to hold at once",
                    message: "Try a shorter change."
                )
            case .unsupportedLanguageOrLocale:
                return Notice(
                    symbol: "globe",
                    title: "Language not supported",
                    message: "Try writing your change in English."
                )
            default:
                break
            }
        }
        return Notice(
            symbol: "exclamationmark.circle",
            title: "The story stopped",
            message: "Something interrupted the writing. Try again."
        )
    }
}

// MARK: - Prompting

private enum StoryInstructions {
    static let story = """
    You write alternate versions of classic novels. You are given one change to the original plot. \
    The change is now true and replaces what happened in the original: never describe the original event happening. \
    The first chapter opens with the change itself. Then follow its consequences: what the characters do next, \
    what the change makes impossible, and what it makes possible, all the way to a new ending. \
    Keep the original characters, setting, era and voice. Write vivid third-person prose in the past tense, \
    with specific details. Keep any violence offstage and understated.
    """

    static let map = """
    You know the plots of well-known books. Describe a book's premise without spoilers, \
    then list its main turning points in the order they happen. For each, say what happens \
    and suggest three different things that could have happened instead.
    """
}

private enum Prompts {
    static func book(_ book: Book, context: String?) -> String {
        var lines = ["Book: \(book.title)"]
        if let author = book.author { lines.append("Author: \(author)") }
        if let year = book.year { lines.append("First published: \(year)") }
        if let context { lines.append("About the book:\n\(context)") }
        return lines.joined(separator: "\n")
    }

    static func story(_ request: StoryRequest) -> String {
        // Just the book and the moment: a premise or earlier events pull a small model
        // back into retelling the opening. The premise is only used for off-map changes.
        var lines = [book(request.book, context: nil)]
        if request.moment == nil { lines.append("Premise: \(request.premise)") }
        if let moment = request.moment {
            lines.append("In the original book (\(moment.chapter), \(moment.title)): \(moment.happened)")
            lines.append("THE CHANGE: \(request.change). This replaces what happened in the original.")
        } else {
            lines.append("THE CHANGE: \(request.change).")
        }

        lines.append("""

        Write the alternate version, starting from the change. Begin your answer with the title line, \
        and use exactly this format:
        Title: <a new title for this version, 2 to 6 words>
        # <a chapter heading of 2 to 5 words>
        <one paragraph of 80 to 120 words that shows the change happening>
        # <a chapter heading of 2 to 5 words>
        <one paragraph of 80 to 120 words about what follows>
        (four chapters in total, each with its own # heading)
        # How it ends
        <one paragraph of 60 to 100 words>
        """)
        return lines.joined(separator: "\n")
    }
}

// MARK: - Parsing

/// Turns the model's lightly formatted text into a `Story`, tolerating the
/// small deviations an on-device model makes, and partial text while streaming.
enum StoryParser {
    private enum Line {
        case title(String)
        case chapter(String)
        case ending(String)
        case text(String)
    }

    static func parse(_ raw: String) -> Story {
        var story = Story()
        var inEnding = false

        for rawLine in raw.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = clean(String(rawLine))
            guard !line.isEmpty else { continue }

            switch classify(line) {
            case .title(let title):
                story.title = unquote(title)
            case .chapter(let heading):
                inEnding = false
                story.chapters.append(.init(heading: heading, text: ""))
            case .ending(let rest):
                inEnding = true
                append(rest, to: &story.ending)
            case .text(let text):
                if inEnding {
                    append(text, to: &story.ending)
                } else if let last = story.chapters.indices.last {
                    append(text, to: &story.chapters[last].text)
                } else if story.title.isEmpty {
                    story.title = unquote(text)
                } else {
                    story.chapters.append(.init(heading: "", text: text))
                }
            }
        }
        return story
    }

    /// Recognises the heading styles a small model actually produces:
    /// "# Heading", "Chapter 2: Heading", "Chapter Two – Heading", "How it ends: …".
    private static func classify(_ line: String) -> Line {
        let lower = line.lowercased()

        if lower.hasPrefix("title:") {
            return .title(clean(String(line.dropFirst(6))))
        }

        var heading = line
        let isHash = line.hasPrefix("#")
        if isHash {
            heading = clean(line.trimmingCharacters(in: CharacterSet(charactersIn: "# ")))
        }
        let headingLower = heading.lowercased()

        if headingLower.hasPrefix("how it ends") || headingLower == "ending" || headingLower.hasPrefix("ending:")
            || headingLower == "the ending" {
            let rest = heading.firstIndex(of: ":").map { String(heading[heading.index(after: $0)...]) } ?? ""
            return .ending(clean(rest))
        }

        if headingLower.hasPrefix("chapter"), heading.count <= 60 {
            // Drop "Chapter 1" / "Chapter One" and any separator; a bare number leaves no heading.
            let words = heading.split(separator: " ", maxSplits: 2).map(String.init)
            let rest = words.count > 2 ? words[2] : ""
            return .chapter(rest.trimmingCharacters(in: CharacterSet(charactersIn: ":-–—. ")))
        }

        if isHash {
            return .chapter(heading)
        }
        return .text(line)
    }

    private static func append(_ text: String, to target: inout String) {
        guard !text.isEmpty else { return }
        target += target.isEmpty ? text : "\n\n" + text
    }

    private static func clean(_ s: String) -> String {
        s.replacingOccurrences(of: "**", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Titles sometimes arrive wrapped in quotes; prose keeps its quotes.
    private static func unquote(_ s: String) -> String {
        s.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”"))
    }
}

// MARK: - Generable schema

@Generable
struct GeneratedMap {
    @Guide(description: "Two sentences that set up the book's premise without any spoilers")
    var premise: String

    @Guide(description: "The book's turning points in the order they happen", .count(6))
    var moments: [GeneratedMoment]
}

@Generable
struct GeneratedMoment {
    @Guide(description: "Where it happens in the book, such as 'Ch. 4' or 'Part 2'")
    var chapter: String

    @Guide(description: "A title for the moment, 3 to 6 words")
    var title: String

    @Guide(description: "One sentence saying what happens in the book")
    var happened: String

    @Guide(description: "Things that could have happened instead, each under 10 words", .count(3))
    var alternatives: [String]
}
