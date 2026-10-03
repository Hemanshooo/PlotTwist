import Foundation

/// A turning point in a book: what happened, and what could have happened instead.
struct Moment: Identifiable, Hashable, Codable {
    let id: String
    /// Where it falls, as printed: "Ch. 5", "Act 3, Sc. 1", "Stave 2".
    let chapter: String
    /// How far through the book it falls (0…1). Drives spoiler gating.
    let position: Double
    let title: String
    let happened: String
    let alternatives: [String]
}

/// The shape of a book's plot: a spoiler-free premise and its turning points, in order.
struct StoryMap: Hashable {
    let premise: String
    let moments: [Moment]
    /// Hand-checked (catalogue) or drawn by the model.
    let isCurated: Bool

    /// Moments up to and including `moment`, used as context for the model.
    func moments(before moment: Moment) -> [Moment] {
        moments.filter { $0.position < moment.position }
    }
}

/// How far the reader has got, which decides how much of the map is shown.
enum ReadingProgress: Hashable {
    case notStarted
    case partway(Double)
    case finished

    /// Moments at or before this point are shown; later ones stay sealed.
    /// Readers who haven't started still see the opening set-up.
    var threshold: Double {
        switch self {
        case .notStarted: 0.12
        case .partway(let p): max(0.12, p)
        case .finished: 1
        }
    }

    var fraction: Double {
        switch self {
        case .notStarted: 0
        case .partway(let p): p
        case .finished: 1
        }
    }

    init(fraction: Double) {
        if fraction >= 0.999 { self = .finished }
        else if fraction <= 0.001 { self = .notStarted }
        else { self = .partway(fraction) }
    }
}
