#if DEBUG && targetEnvironment(simulator)
import Foundation
import SwiftData

/// A few months of reading, for designing and testing in the Simulator only:
/// diary entries, ratings, hearts, a reread, a spoiler, and quotes from the
/// public-domain classics. Added once per Simulator; never on a real iPhone,
/// and never in a release build.
@MainActor
enum SampleLibrary {
    private static let key = "debug.sampleLibrary.v1"

    static func addIfNeeded(to context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let calendar = Calendar.current
        func day(_ month: Int, _ day: Int, _ year: Int = 2026) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
        }
        func book(_ slug: String) -> Book? {
            Catalog.entries.first { $0.book.id == "catalog/\(slug)" }?.book
        }

        let reads: [(String, Date, Double, Bool, String, Bool, Bool)] = [
            ("jane-eyre", day(11, 2), 5, true,
             "Fierce and strange and far funnier than I expected. Jane argues with everyone, including God, and wins most of it.", false, false),
            ("the-great-gatsby", day(10, 24), 4.5, true,
             "Every sentence is doing two things at once. The green light lands differently once you know how it ends.", true, true),
            ("frankenstein", day(10, 9), 4, false,
             "The creature is the most eloquent person in the book, which is the whole tragedy.", false, false),
            ("a-christmas-carol", day(9, 28), 3.5, false, "", false, false),
            ("the-picture-of-dorian-gray", day(9, 12), 4, true,
             "Lord Henry should not be allowed to speak. I underlined half of what he said.", false, false),
            ("wuthering-heights", day(12, 18, 2025), 3, false,
             "Everyone is awful and I couldn’t stop reading.", false, false),
        ]
        for (slug, date, rating, liked, review, spoilers, reread) in reads {
            guard let book = book(slug) else { continue }
            Library.log(
                DiaryEntry(book: book, readOn: date, rating: rating, liked: liked, review: review,
                           hasSpoilers: spoilers, isReread: reread),
                in: context
            )
        }
        if let alice = book("alices-adventures-in-wonderland") {
            Library.shelve(alice, as: .toRead, in: context)
        }
        if let dracula = book("dracula") {
            Library.shelve(dracula, as: .reading, in: context)
            Library.setProgress(0.38, for: dracula, in: context)
        }

        let lines: [(String, String, String)] = [
            ("jane-eyre", "I am no bird; and no net ensnares me: I am a free human being with an independent will.", "284"),
            ("the-great-gatsby", "So we beat on, boats against the current, borne back ceaselessly into the past.", "180"),
            ("frankenstein", "Beware; for I am fearless, and therefore powerful.", "201"),
            ("the-picture-of-dorian-gray", "The only way to get rid of a temptation is to yield to it.", "21"),
            ("pride-and-prejudice", "I declare after all there is no enjoyment like reading! How much sooner one tires of any thing than of a book!", "54"),
        ]
        for (slug, text, page) in lines {
            guard let book = book(slug) else { continue }
            context.insert(Quote(book: book, text: text, page: page))
        }
        Profile.current(in: context).readingGoal = 24
        Library.save(context)
    }
}
#endif
