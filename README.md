# Endpaper

A reading diary in a garden. Keep track of what you read, rate it in roses, keep the lines that stopped you, show your favourite four, and, for any book, ask "What if": change one moment and read how the story would have gone.

## Run it

1. Open `Otherwise.xcodeproj` in Xcode 26 or later. (The project and target keep their original name, Otherwise; the app is called Endpaper on the Home Screen and everywhere inside it.)
2. Pick an iPhone simulator running iOS 26, or your own iPhone (signing: choose your Team under Signing & Capabilities).
3. Press Run. In the Simulator, a few months of sample reading (diary entries, quotes, a goal) is added once, so every screen has something in it; this never happens on a real iPhone or in a release build.

Everything you keep is stored on the iPhone with SwiftData. Search, book details and page counts come from Open Library. "What if" stories and maps for books outside the catalogue are written on device with Apple's Foundation Models framework, so they need Apple Intelligence; nothing you type leaves the phone.

**Book guides.** The phone's model can hold only about 3,000 words, so it can't read a novel. Instead ChatGPT reads each book once, from its full text on Project Gutenberg, and leaves a guide the app is built with: characters, every chapter summarised, and each turning point with its original passage, cut word-for-word from the book. "What if" stories are written from the original scene, the people in it and what followed. See [Tools/bookguide](Tools/bookguide/README.md) (needs an OpenAI API key, on your Mac only).

## The app

Endpaper is a garden kept between the pages, set like a type specimen (after Type Garden): a flat ground, Instrument Serif titles, small DM Mono labels, outlined pills, and a two-colour garden of stems and roses that grows through it. It can be read in four palettes (Rose noir, Paper, Midnight, Citrus). See DESIGN_SYSTEM.md.

A text tab bar floats at the foot of the main screens: **Shelf · Diary · Quotes · You**, with a search circle for **Discover**.

1. **Shelf.** Your books lie flat in a deep stack, spines toward you, switched between **Reading · To read · Read**. Tap one and, in one continuous motion, it lifts out of the stack, turns upright in your hands, swings its cover open and becomes its own page.
2. **Discover.** Search any book, or browse a stack: twelve classics with hand-drawn story maps, then Open Library's endless run.
3. **A book.** Its title page; your copy (shelf, how far you've read, your rating in roses and the heart); **Log a read** (date, roses, heart, review, spoilers, reread); your diary entries and quotes from it; its **What if** map; and a little about it.
4. **Diary.** Every book you've finished, by month and day, with this year's count and your goal as a vine.
5. **Quotes.** Your commonplace book: every line you kept, on dog-eared slips. Share any of them as a card (post or story) in any palette.
6. **You.** Your name, your favourite four, the year in books, pages and average rating, how your roses fall, your shelves and your "What if" stories.

## How it's organised

```
Otherwise/
  App/             Entry point; sample library for the Simulator
  DesignSystem/    Tokens (palettes, type, editions), the garden, rating, navigation, book components, gallery → DESIGN_SYSTEM.md
  Resources/Fonts/ Instrument Serif, DM Mono, Newsreader (all OFL)
  Resources/Guides/ Book guides built by Tools/bookguide (<slug>.guide.json)
  Models/          Book, Shelf (ShelfEntry + Library, where every change goes), Diary (DiaryEntry, Quote, Profile),
                   Store (the SwiftData container), Story, StoryMap, Catalog, BookGuide, Version
  Services/        OpenLibrary, StoryEngine (Foundation Models + tolerant text parser)
  Features/        Root (tabs), Shelf, Discover, Library (stack, slabs, opening, sheets), Book (page, shelf card,
                   What if map, moment sheet), Diary (diary, entry, log sheet), Quotes (commonplace book, editor,
                   share card), Profile (you, favourites, shelves, What if stories), Story (page-curl reader)
Tools/
  bookguide/       build.py: Gutenberg text → ChatGPT → book guide; books.json; seeds (the hand-written maps)
```

## Data and sync

Every model gives all its properties defaults and has no unique attributes, so the store can sync through iCloud as it is. Turning that on needs a paid Apple Developer account: add the iCloud capability with CloudKit and a container, and Background Modes → Remote notifications. Shelves and stories from Plot Twist carry over; if the store ever can't be opened, the app starts a new one beside it rather than crashing.

## Next

- Lists (ranked or themed), barcode scanning, capturing a quote by photographing the page, and importing from Goodreads and StoryGraph.
- Year in Review, and Home and Lock Screen widgets.
- Accounts, following, a friends' feed, and comments on reviews (needs a backend).

## Known limits

- Apple's on-device model is small (about 3B parameters). "What if" stories are structured reliably but the prose is plain. Hand-written maps and book guides keep the turning points, names and events accurate.
- Page counts come from Open Library (a median across editions) or, for the classics, a typical paperback.
