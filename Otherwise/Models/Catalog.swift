import Foundation

/// A hand-checked book: its edition and its story map.
struct CatalogEntry {
    let book: Book
    let edition: Edition
    let map: StoryMap
}

/// Twelve classics with hand-written story maps. Premises are spoiler-free;
/// moments are ordered and positioned so the map can be gated by reading progress.
enum Catalog {

    static func entry(for book: Book) -> CatalogEntry? {
        if let match = byID[book.id] { return match }
        let title = normalize(book.title)
        for (key, entry) in byTitle where title == key || title.hasPrefix(key + " ") {
            guard let author = book.author, let entryAuthor = entry.book.author else { return entry }
            let surname = normalize(entryAuthor).split(separator: " ").last.map(String.init) ?? ""
            if normalize(author).contains(surname) { return entry }
        }
        return nil
    }

    private static let byID: [String: CatalogEntry] =
        Dictionary(uniqueKeysWithValues: entries.map { ($0.book.id, $0) })

    private static let byTitle: [String: CatalogEntry] =
        Dictionary(uniqueKeysWithValues: entries.map { (normalize($0.book.title), $0) })

    private static func normalize(_ s: String) -> String {
        let lowered = s.lowercased()
            .replacingOccurrences(of: "’", with: "")
            .replacingOccurrences(of: "'", with: "")
        let cleaned = lowered.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : " " }
        var words = String(cleaned).split(separator: " ").map(String.init)
        if words.first == "the" { words.removeFirst() }
        return words.joined(separator: " ")
    }

    private static func moment(_ id: String, _ chapter: String, _ position: Double, _ title: String, _ happened: String, _ alternatives: [String]) -> Moment {
        Moment(id: id, chapter: chapter, position: position, title: title, happened: happened, alternatives: alternatives)
    }

    private static func book(_ slug: String, _ title: String, _ author: String, _ year: Int) -> Book {
        Book(id: "catalog/\(slug)", title: title, author: author, year: year, coverID: nil)
    }

    // MARK: - Entries

    static let entries: [CatalogEntry] = [
        CatalogEntry(
            book: book("pride-and-prejudice", "Pride and Prejudice", "Jane Austen", 1813),
            edition: Edition(cloth: 0xD46A7E, foil: 0x4A1622, pattern: .dots),
            map: StoryMap(
                premise: "In Regency England the five Bennet sisters need to marry well. Elizabeth, the sharp-witted second daughter, takes an instant dislike to the proud and wealthy Mr. Darcy.",
                moments: [
                    moment("pp1", "Ch. 3", 0.05, "Darcy’s snub at the Meryton ball", "Within Elizabeth’s hearing, Darcy calls her “tolerable, but not handsome enough to tempt me.”", ["Darcy asks Elizabeth to dance", "Elizabeth never overhears him", "Bingley never comes to Netherfield"]),
                    moment("pp2", "Ch. 16", 0.15, "Wickham tells his story", "The charming officer Wickham tells Elizabeth that Darcy cheated him of his inheritance, and she believes every word.", ["Elizabeth doubts Wickham from the start", "Wickham never joins the regiment", "Darcy confronts Wickham in public"]),
                    moment("pp3", "Ch. 19", 0.25, "Mr. Collins proposes", "Her pompous cousin proposes. Elizabeth refuses him, and he marries her friend Charlotte instead.", ["Elizabeth accepts Mr. Collins", "Mrs. Bennet forces the marriage", "Charlotte refuses him too"]),
                    moment("pp4", "Ch. 34", 0.45, "Darcy’s first proposal", "At Hunsford, Darcy proposes while insulting her family. Elizabeth refuses and accuses him of ruining Jane’s happiness.", ["Elizabeth says yes", "Darcy proposes humbly", "Darcy never proposes"]),
                    moment("pp5", "Ch. 35", 0.5, "Darcy’s letter", "Darcy hands Elizabeth a letter revealing Wickham’s true character and explaining his part in separating Jane and Bingley.", ["Elizabeth burns the letter unread", "Darcy never writes it", "Jane reads the letter instead"]),
                    moment("pp6", "Ch. 46", 0.7, "Lydia elopes", "Lydia runs off with Wickham, threatening the whole family’s reputation.", ["Lydia stays home at Longbourn", "Elizabeth stops the elopement", "Wickham abandons Lydia in London"]),
                    moment("pp7", "Ch. 52", 0.8, "Darcy’s secret rescue", "Darcy tracks the couple down and pays Wickham to marry Lydia, asking that no one ever know.", ["Darcy refuses to get involved", "Darcy’s part is made public", "Mr. Bennet finds them first"]),
                    moment("pp8", "Ch. 56", 0.9, "Lady Catherine’s visit", "Lady Catherine demands Elizabeth promise never to marry Darcy. Elizabeth refuses.", ["Elizabeth gives her promise", "Lady Catherine never hears the rumour", "Darcy arrives during the visit"]),
                ],
                isCurated: true
            )
        ),
        CatalogEntry(
            book: book("the-great-gatsby", "The Great Gatsby", "F. Scott Fitzgerald", 1925),
            edition: Edition(cloth: 0x10403F, foil: 0xE9C46A, pattern: .diamonds),
            map: StoryMap(
                premise: "Summer, 1922. Nick Carraway rents a cottage on Long Island next to Jay Gatsby, a mysterious millionaire whose lavish parties glitter across the bay from Nick’s cousin Daisy.",
                moments: [
                    moment("gg1", "Ch. 1", 0.08, "The green light", "Nick sees Gatsby alone at night, reaching toward a green light at the end of Daisy’s dock.", ["Gatsby buys the house beside Daisy’s", "Nick never moves to West Egg", "Daisy sees Gatsby that night"]),
                    moment("gg2", "Ch. 3", 0.2, "Gatsby’s party", "Nick finally meets his host at one of the enormous parties and is drawn into his circle.", ["Gatsby never throws his parties", "Nick refuses the invitation", "Daisy comes to the party"]),
                    moment("gg3", "Ch. 5", 0.4, "Tea at Nick’s cottage", "Gatsby and Daisy meet again for the first time in five years, in Nick’s small front room.", ["Daisy never comes to tea", "Tom arrives instead of Daisy", "Gatsby loses his nerve and leaves"]),
                    moment("gg4", "Ch. 7", 0.65, "The Plaza Hotel", "In a sweltering hotel suite Tom exposes Gatsby’s dealings, and Daisy won’t say she never loved Tom.", ["Daisy says she never loved Tom", "Gatsby admits everything first", "Nick stays home that day"]),
                    moment("gg5", "Ch. 7", 0.72, "The yellow car", "Driving Gatsby’s car home, Daisy strikes Myrtle Wilson. Gatsby decides to take the blame.", ["Gatsby is driving the car", "They take a different road home", "Daisy confesses"]),
                    moment("gg6", "Ch. 8", 0.85, "Waiting for the call", "Gatsby waits by his pool for a call from Daisy that never comes, while George Wilson searches for the car’s owner.", ["Daisy calls and they leave together", "Gatsby leaves for Chicago at dawn", "Nick stays with Gatsby all day"]),
                    moment("gg7", "Ch. 9", 0.95, "The funeral", "Almost no one comes to Gatsby’s funeral. Daisy and Tom have already left town.", ["Daisy comes to the funeral", "Gatsby’s father tells everyone his past", "Nick stays in the East"]),
                ],
                isCurated: true
            )
        ),
        CatalogEntry(
            book: book("frankenstein", "Frankenstein", "Mary Shelley", 1818),
            edition: Edition(cloth: 0x34452F, foil: 0xC9E46B, pattern: .chevrons),
            map: StoryMap(
                premise: "On an Arctic voyage, the explorer Robert Walton rescues a dying stranger, Victor Frankenstein, who tells how his obsession with the secret of life led to disaster.",
                moments: [
                    moment("fr1", "Ch. 5", 0.2, "The creature wakes", "Victor brings his creature to life, is horrified by it, and flees, leaving it alone.", ["Victor stays and cares for the creature", "Victor destroys his notes first", "Elizabeth visits that night"]),
                    moment("fr2", "Ch. 8", 0.3, "Justine’s trial", "Victor’s little brother William is found dead. The servant Justine is blamed and executed while Victor stays silent.", ["Victor tells the truth at the trial", "Justine is acquitted", "William is never harmed"]),
                    moment("fr3", "Ch. 15", 0.42, "The cottage in the woods", "The creature tells how the De Lacey family, whom he secretly helped, drove him away in fear.", ["The De Laceys welcome him", "The creature never finds the cottage", "Old De Lacey speaks for him"]),
                    moment("fr4", "Ch. 17", 0.5, "A companion", "The creature asks for a companion and promises to vanish with her forever. Victor agrees.", ["Victor refuses outright", "The creature asks for a friend instead", "Victor tells his father everything"]),
                    moment("fr5", "Ch. 20", 0.65, "The island workshop", "On a Scottish island Victor tears apart the half-made companion as the creature watches.", ["Victor finishes the companion", "The creature stops him in time", "Victor sails away and abandons both"]),
                    moment("fr6", "Ch. 23", 0.82, "The wedding night", "On his wedding night Victor guards himself, but it is Elizabeth who is attacked.", ["Victor stays by Elizabeth’s side", "Elizabeth meets the creature and talks to it", "Victor postpones the wedding"]),
                    moment("fr7", "Ch. 24", 0.95, "Into the ice", "Victor pursues the creature across the frozen north, where Walton finds him.", ["Victor gives up the chase", "The creature turns back to help him", "Walton joins the hunt"]),
                ],
                isCurated: true
            )
        ),
        CatalogEntry(
            book: book("jane-eyre", "Jane Eyre", "Charlotte Brontë", 1847),
            edition: Edition(cloth: 0x2E3A7A, foil: 0xF2B33D, pattern: .lattice),
            map: StoryMap(
                premise: "An orphan raised by a cruel aunt and a harsh charity school, Jane becomes governess at Thornfield Hall and grows close to its brooding master, Mr. Rochester.",
                moments: [
                    moment("je1", "Ch. 2", 0.04, "The red-room", "As punishment, young Jane is locked in the room where her uncle died, and faints in terror.", ["Jane escapes Gateshead that night", "Mrs. Reed relents and keeps her", "Jane is sent to other relatives"]),
                    moment("je2", "Ch. 9", 0.15, "Fever at Lowood", "Typhus sweeps the school, and Jane’s dearest friend Helen dies in her arms.", ["Helen survives the fever", "Jane and Helen leave Lowood together", "Mr. Brocklehurst is exposed early"]),
                    moment("je3", "Ch. 12", 0.25, "A horse on the ice", "On a frozen lane a rider’s horse slips. Jane helps him, not knowing he is her master.", ["Jane walks past without helping", "Rochester is cold and dismissive", "Jane leaves before he returns"]),
                    moment("je4", "Ch. 15", 0.33, "Fire in the night", "Jane wakes to find Rochester’s bed curtains on fire and saves his life.", ["Jane sleeps through the fire", "Jane sees who set it", "Rochester tells her the truth that night"]),
                    moment("je5", "Ch. 23", 0.5, "The orchard proposal", "Under the chestnut tree Rochester asks Jane to marry him, and she says yes.", ["Jane refuses Rochester", "Rochester confesses his secret first", "Rochester marries Blanche Ingram"]),
                    moment("je6", "Ch. 26", 0.56, "The interrupted wedding", "At the altar a lawyer reveals that Rochester is already married to Bertha, who is hidden in the attic.", ["The wedding goes ahead", "Jane discovers Bertha herself first", "Rochester and Jane run away together"]),
                    moment("je7", "Ch. 34", 0.8, "St. John’s proposal", "Her cousin St. John asks Jane to marry him and join his mission in India.", ["Jane marries St. John", "Jane goes to India alone", "Jane never hears Rochester’s voice call"]),
                    moment("je8", "Ch. 36", 0.92, "Return to Thornfield", "Jane returns to find Thornfield a burned ruin, and learns where Rochester has gone.", ["Jane returns before the fire", "Rochester comes looking for Jane", "Thornfield never burns"]),
                ],
                isCurated: true
            )
        ),
        CatalogEntry(
            book: book("romeo-and-juliet", "Romeo and Juliet", "William Shakespeare", 1597),
            edition: Edition(cloth: 0xA3243A, foil: 0xF8C9C4, pattern: .stars),
            map: StoryMap(
                premise: "In Verona two families are locked in an old feud. Romeo, a Montague, slips into a Capulet feast and falls for Juliet, the daughter of his family’s enemies.",
                moments: [
                    moment("rj1", "Act 1, Sc. 5", 0.1, "The masked feast", "Romeo crashes the Capulet party. He and Juliet fall in love before learning who the other is.", ["Romeo stays home that night", "Tybalt throws Romeo out at once", "Juliet learns his name first"]),
                    moment("rj2", "Act 2, Sc. 2", 0.2, "The balcony", "Juliet speaks her love aloud, not knowing Romeo hears. They agree to marry.", ["Juliet calls for the guards", "They decide to wait", "They tell their parents"]),
                    moment("rj3", "Act 2, Sc. 6", 0.3, "The secret wedding", "Friar Laurence marries them in secret, hoping it will end the feud.", ["The Friar refuses to marry them", "They marry in public", "The Nurse tells Lady Capulet"]),
                    moment("rj4", "Act 3, Sc. 1", 0.45, "The street fight", "Tybalt kills Mercutio. Romeo kills Tybalt in revenge and is banished from Verona.", ["Romeo stops the fight", "Romeo walks away from Tybalt", "The Prince arrives in time"]),
                    moment("rj5", "Act 4, Sc. 1", 0.65, "The Friar’s potion", "Facing a forced marriage to Paris, Juliet takes a potion that will make her seem dead.", ["Juliet refuses Paris openly", "Juliet runs to Mantua", "Juliet tells her father the truth"]),
                    moment("rj6", "Act 5, Sc. 1", 0.8, "The letter that never arrives", "The Friar’s letter explaining the plan never reaches Romeo. He hears only that Juliet is dead.", ["The letter reaches Romeo", "Balthasar never brings the news", "Romeo waits a day before leaving"]),
                    moment("rj7", "Act 5, Sc. 3", 0.95, "The tomb", "Romeo reaches the tomb believing Juliet dead, moments before she wakes.", ["Juliet wakes a minute sooner", "Friar Laurence arrives first", "Paris stops Romeo at the door"]),
                ],
                isCurated: true
            )
        ),
        CatalogEntry(
            book: book("dracula", "Dracula", "Bram Stoker", 1897),
            edition: Edition(cloth: 0x241A27, foil: 0xD9483B, pattern: .scallops),
            map: StoryMap(
                premise: "Young solicitor Jonathan Harker travels to Transylvania to help a reclusive count buy a house in England, and slowly realises he is a prisoner in the castle.",
                moments: [
                    moment("dr1", "Ch. 3", 0.08, "A prisoner in the castle", "Harker finds every door locked, then sees the Count crawl head-first down the castle wall.", ["Jonathan escapes in the first week", "Jonathan refuses the journey", "Mina travels with him"]),
                    moment("dr2", "Ch. 7", 0.2, "The ship at Whitby", "A ship drifts into Whitby harbour with its crew gone, and a great dog leaps ashore.", ["The ship sinks at sea", "The captain stops the stowaway", "The dog is caught on the beach"]),
                    moment("dr3", "Ch. 12", 0.35, "Lucy’s decline", "Despite blood transfusions from four men, Lucy grows weaker night after night.", ["Van Helsing arrives a week sooner", "Lucy’s mother leaves the garlic", "Lucy marries Arthur and leaves Whitby"]),
                    moment("dr4", "Ch. 16", 0.45, "The tomb in Hampstead", "Van Helsing leads the men to Lucy’s tomb to set her soul free.", ["Arthur refuses to go", "Lucy is cured instead", "Lucy escapes the tomb"]),
                    moment("dr5", "Ch. 21", 0.6, "Mina is bitten", "The Count visits Mina and binds her to him, linking her mind with his.", ["The men keep Mina with them", "Mina fights the Count off", "Jonathan wakes in time"]),
                    moment("dr6", "Ch. 23", 0.75, "The boxes of earth", "The hunters destroy the Count’s boxes of earth across London, leaving him one refuge.", ["They miss the boxes in Piccadilly", "The Count stays in London", "Renfield warns the Count"]),
                    moment("dr7", "Ch. 27", 0.95, "The race to the castle", "The hunters chase the Count’s cart back to Transylvania, racing the setting sun.", ["The sun sets before they reach him", "Mina goes on alone", "The Count offers a bargain"]),
                ],
                isCurated: true
            )
        ),
        CatalogEntry(
            book: book("the-picture-of-dorian-gray", "The Picture of Dorian Gray", "Oscar Wilde", 1890),
            edition: Edition(cloth: 0x1E5B48, foil: 0xEBCB7B, pattern: .leaves),
            map: StoryMap(
                premise: "The painter Basil Hallward finishes a portrait of the beautiful young Dorian Gray, while the witty Lord Henry fills Dorian’s head with ideas about youth and pleasure.",
                moments: [
                    moment("dg1", "Ch. 2", 0.08, "The wish", "Looking at his portrait, Dorian wishes the painting could grow old instead of him.", ["Dorian never makes the wish", "Basil destroys the painting", "Dorian never meets Lord Henry"]),
                    moment("dg2", "Ch. 7", 0.25, "Sibyl’s performance", "After the actress Sibyl Vane acts badly for love of him, Dorian cruelly rejects her.", ["Dorian forgives Sibyl", "Sibyl performs brilliantly", "Lord Henry never comes to the theatre"]),
                    moment("dg3", "Ch. 8", 0.3, "The portrait changes", "Dorian sees cruelty in the painted face and resolves to make amends, but it is too late for Sibyl.", ["Dorian reaches Sibyl in time", "Dorian shows Basil the change", "Dorian destroys the portrait now"]),
                    moment("dg4", "Ch. 10", 0.4, "Locked in the schoolroom", "Dorian hides the portrait in his old schoolroom and keeps the only key.", ["Dorian hangs the portrait in public", "Lord Henry finds the key", "Dorian gives the portrait away"]),
                    moment("dg5", "Ch. 13", 0.6, "Basil sees the portrait", "Dorian shows Basil what the painting has become, and their meeting ends in violence.", ["Dorian lets Basil pray with him", "Basil never visits that night", "Basil takes the portrait away"]),
                    moment("dg6", "Ch. 18", 0.8, "James Vane’s revenge", "Sibyl’s brother hunts Dorian for years, until a shooting party ends the chase.", ["James confronts Dorian face to face", "James recognises Dorian’s true age", "Dorian confesses to James"]),
                    moment("dg7", "Ch. 20", 0.95, "The knife", "Desperate to be free, Dorian takes a knife to the portrait.", ["Dorian confesses everything", "Dorian leaves the portrait alone", "Lord Henry sees the painting first"]),
                ],
                isCurated: true
            )
        ),
        CatalogEntry(
            book: book("little-women", "Little Women", "Louisa May Alcott", 1868),
            edition: Edition(cloth: 0xE3A53A, foil: 0x3B2C5E, pattern: .checks),
            map: StoryMap(
                premise: "While their father serves in the Civil War, the four March sisters, Meg, Jo, Beth and Amy, grow up in Massachusetts with their mother, Marmee.",
                moments: [
                    moment("lw1", "Ch. 2", 0.05, "Christmas breakfast", "The girls give their Christmas breakfast to the Hummels, a poor family nearby.", ["The girls keep their breakfast", "Laurie joins them that morning", "Aunt March comes for Christmas"]),
                    moment("lw2", "Ch. 8", 0.12, "The burned manuscript", "Angry at being left out, Amy burns the book Jo has been writing for years.", ["Amy goes to the theatre with them", "Jo kept a second copy", "Jo forgives Amy at once"]),
                    moment("lw3", "Ch. 18", 0.3, "Scarlet fever", "Visiting the Hummels while Marmee is away, Beth catches scarlet fever.", ["Jo visits the Hummels instead", "Marmee comes home sooner", "Beth never catches the fever"]),
                    moment("lw4", "Ch. 23", 0.4, "Meg chooses John Brooke", "Meg accepts the poor tutor John Brooke despite Aunt March’s threats.", ["Meg refuses John", "Aunt March approves the match", "Meg marries a rich suitor"]),
                    moment("lw5", "Pt. 2, Ch. 35", 0.6, "Laurie’s proposal", "Laurie proposes to Jo, and she tells him she can’t love him that way.", ["Jo says yes to Laurie", "Laurie never proposes", "Jo goes to Europe instead of Amy"]),
                    moment("lw6", "Pt. 2, Ch. 40", 0.75, "Beth’s last spring", "Beth’s health fades, and the family gathers around her at home.", ["Beth recovers", "Beth goes south for her health", "Jo stays in New York"]),
                    moment("lw7", "Pt. 2, Ch. 46", 0.92, "Under the umbrella", "Professor Bhaer proposes to Jo under an umbrella in the rain.", ["Jo turns Bhaer down", "Bhaer leaves for the West", "Jo becomes a famous novelist alone"]),
                ],
                isCurated: true
            )
        ),
        CatalogEntry(
            book: book("a-christmas-carol", "A Christmas Carol", "Charles Dickens", 1843),
            edition: Edition(cloth: 0x8C2A2A, foil: 0xF5E6C4, pattern: .stars),
            map: StoryMap(
                premise: "On Christmas Eve, the miser Ebenezer Scrooge is visited by the ghost of his old partner, Jacob Marley, who warns him that three spirits are coming.",
                moments: [
                    moment("cc1", "Stave 1", 0.1, "Marley’s warning", "Marley’s chained ghost warns Scrooge to change, or share his fate.", ["Scrooge laughs Marley away", "No spirits follow Marley", "Scrooge goes to Fred’s party that night"]),
                    moment("cc2", "Stave 2", 0.3, "Belle walks away", "The first spirit shows young Scrooge losing his fiancée, Belle, to his love of money.", ["Scrooge chooses Belle over money", "Belle waits for him", "Fezziwig makes Scrooge his partner"]),
                    moment("cc3", "Stave 3", 0.5, "The Cratchits’ dinner", "The second spirit shows the Cratchits’ small Christmas dinner, and frail Tiny Tim.", ["Scrooge visits the Cratchits in person", "Bob asks for a raise", "Tiny Tim is healthy"]),
                    moment("cc4", "Stave 4", 0.75, "The neglected grave", "The last spirit shows Scrooge a lonely, untended grave bearing his own name.", ["Scrooge refuses to look", "The grave belongs to someone else", "Scrooge sees a different future"]),
                    moment("cc5", "Stave 5", 0.92, "Christmas morning", "Scrooge wakes a changed man and sends a prize turkey to the Cratchits.", ["Scrooge wakes unchanged", "Scrooge goes to the Cratchits himself", "Scrooge decides it was all a dream"]),
                ],
                isCurated: true
            )
        ),
        CatalogEntry(
            book: book("alices-adventures-in-wonderland", "Alice’s Adventures in Wonderland", "Lewis Carroll", 1865),
            edition: Edition(cloth: 0x8EC3E6, foil: 0x1C2C4C, pattern: .dots),
            map: StoryMap(
                premise: "On a drowsy summer afternoon, Alice follows a White Rabbit with a pocket watch down a rabbit hole, into a world where nothing makes sense.",
                moments: [
                    moment("aw1", "Ch. 1", 0.05, "Down the rabbit hole", "Alice follows the White Rabbit and tumbles into Wonderland.", ["Alice stays on the riverbank", "Her sister follows her down", "Alice catches the Rabbit first"]),
                    moment("aw2", "Ch. 2", 0.12, "The pool of tears", "Alice grows enormous and cries a pool of tears, then shrinks and nearly drowns in it.", ["Alice stays tiny", "Alice never drinks from the bottle", "Alice keeps hold of the key"]),
                    moment("aw3", "Ch. 6", 0.42, "The Cheshire Cat", "A grinning cat in a tree tells Alice that everyone here is mad.", ["The Cat guides Alice home", "Alice ignores the Cat", "The Cat comes along with Alice"]),
                    moment("aw4", "Ch. 7", 0.5, "The Mad Tea-Party", "Alice joins the Hatter, the March Hare and the Dormouse at a tea-party that never ends.", ["Alice stays at the tea-party", "Time forgives the Hatter", "The Dormouse leads the way"]),
                    moment("aw5", "Ch. 8", 0.62, "The Queen’s croquet", "Alice plays croquet with flamingos while the Queen of Hearts orders heads off.", ["Alice beats the Queen", "The King overrules the Queen", "Alice refuses to play"]),
                    moment("aw6", "Ch. 12", 0.92, "The trial of the Knave", "At the trial over the stolen tarts, Alice grows huge and calls the court “nothing but a pack of cards.”", ["Alice stays small and silent", "The Knave is found innocent", "Alice is put on trial"]),
                ],
                isCurated: true
            )
        ),
        CatalogEntry(
            book: book("the-count-of-monte-cristo", "The Count of Monte Cristo", "Alexandre Dumas", 1844),
            edition: Edition(cloth: 0x1B2B4B, foil: 0xE2B857, pattern: .waves),
            map: StoryMap(
                premise: "Marseille, 1815. Young sailor Edmond Dantès comes home to marry Mercédès and become a captain, unaware that jealous rivals are plotting against him.",
                moments: [
                    moment("mc1", "Ch. 5", 0.03, "Arrest at the betrothal feast", "Framed by Danglars and Fernand as a Bonapartist agent, Edmond is arrested at his own betrothal feast.", ["The letter is never sent", "Villefort sets Edmond free", "Mercédès hides Edmond"]),
                    moment("mc2", "Ch. 8", 0.08, "The Château d’If", "To protect his own family, the prosecutor Villefort buries Edmond in an island prison without trial.", ["Villefort gives him a fair trial", "Edmond escapes on the way", "Monsieur Morrel wins his release"]),
                    moment("mc3", "Ch. 17", 0.15, "The Abbé Faria", "Edmond meets the old prisoner Faria, who educates him and tells him of a hidden treasure.", ["Faria and Edmond escape together", "Faria tunnels the wrong way", "Edmond never meets Faria"]),
                    moment("mc4", "Ch. 20", 0.2, "The escape", "Edmond takes Faria’s place in a burial sack and is thrown into the sea.", ["Edmond is caught in the sack", "Edmond serves out his sentence", "Edmond takes Faria’s map but not his place"]),
                    moment("mc5", "Ch. 39", 0.4, "The Count arrives in Paris", "Rich and transformed, Edmond appears in Paris as the Count of Monte Cristo.", ["Edmond returns to Marseille in peace", "Edmond reveals himself to Mercédès at once", "Edmond helps his enemies instead"]),
                    moment("mc6", "Ch. 89", 0.75, "Mercédès recognises him", "Mercédès, who knew him all along, begs the Count to spare her son Albert in a duel.", ["The Count refuses Mercédès", "Albert wins the duel", "Mercédès tells Albert the truth first"]),
                    moment("mc7", "Ch. 111", 0.92, "Too far", "As Villefort’s family is destroyed, the Count begins to wonder if his revenge has gone too far.", ["The Count shows mercy sooner", "Villefort confesses everything", "The Count abandons his revenge"]),
                ],
                isCurated: true
            )
        ),
        CatalogEntry(
            book: book("wuthering-heights", "Wuthering Heights", "Emily Brontë", 1847),
            edition: Edition(cloth: 0x5A4366, foil: 0xCFE0B0, pattern: .leaves),
            map: StoryMap(
                premise: "On the Yorkshire moors the Earnshaw family takes in a foundling boy, Heathcliff, who forms a fierce bond with the daughter of the house, Catherine.",
                moments: [
                    moment("wh1", "Ch. 4", 0.08, "Heathcliff arrives", "Mr. Earnshaw brings home a ragged orphan from Liverpool and names him Heathcliff.", ["Mr. Earnshaw leaves him in Liverpool", "Hindley welcomes Heathcliff", "Heathcliff is raised at Thrushcross Grange"]),
                    moment("wh2", "Ch. 6", 0.15, "Five weeks at the Grange", "Bitten by a dog, Catherine stays with the Lintons and comes home a fine lady.", ["Heathcliff stays at the Grange with her", "Catherine never goes near the Grange", "Catherine runs back to the Heights"]),
                    moment("wh3", "Ch. 9", 0.3, "“I am Heathcliff”", "Catherine tells Nelly she will marry Edgar. Heathcliff overhears only part of it, and vanishes.", ["Heathcliff hears the whole speech", "Catherine chooses Heathcliff", "Nelly stops Heathcliff leaving"]),
                    moment("wh4", "Ch. 10", 0.4, "Heathcliff returns", "Three years later he returns, wealthy and bent on revenge.", ["Heathcliff never returns", "Heathcliff returns and forgives", "Catherine leaves Edgar for him"]),
                    moment("wh5", "Ch. 12", 0.48, "Isabella elopes", "Heathcliff elopes with Edgar’s sister Isabella to wound the Lintons.", ["Isabella refuses Heathcliff", "Edgar stops the elopement", "Heathcliff marries for love"]),
                    moment("wh6", "Ch. 16", 0.55, "Catherine’s last night", "After a last stormy meeting with Heathcliff, Catherine dies giving birth to a daughter.", ["Catherine survives", "Heathcliff takes Catherine away", "Edgar lets Heathcliff visit freely"]),
                    moment("wh7", "Ch. 27", 0.8, "Young Cathy is trapped", "Heathcliff traps Catherine’s daughter at the Heights and forces her to marry his son, Linton.", ["Nelly helps young Cathy escape", "Edgar rescues his daughter", "Linton refuses to marry her"]),
                    moment("wh8", "Ch. 34", 0.95, "The open window", "Haunted by Catherine, Heathcliff stops eating and is found by the open window.", ["Heathcliff sets young Cathy free", "Heathcliff leaves the moors", "Heathcliff makes peace with Hareton"]),
                ],
                isCurated: true
            )
        ),
    ]
}
