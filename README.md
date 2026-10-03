# Plot Twist

Change one moment in any book, and read how the story would have gone.

## Run it

1. Open `Otherwise.xcodeproj` in Xcode 26 or later. (The project and target keep their original name, Otherwise; the app is called Plot Twist on the Home Screen and everywhere inside it.)
2. Pick an iPhone simulator running iOS 26, or your own iPhone (signing: choose your Team under Signing & Capabilities).
3. Press Run. Writing stories needs Apple Intelligence: on the Simulator it uses your Mac's, so turn it on in System Settings.

Stories and maps for books outside the catalogue are written on device with Apple's Foundation Models framework. There are no API keys, and nothing the reader types leaves the phone. Search and book details come from Open Library.

## The flow

1. **Home.** A stack of books to pick from, switchable between **Library** (12 classics with hand-written story maps, anything you've logged, then an endless run of books from Open Library) and **Read** (only the books you've logged). Your saved versions sit behind "Twisted" in the top bar. Search for any other book.
   Pick a book and it slides out of the stack and opens like a real book, to its title page.
2. **Book.** The cover stands on a band of its own patterned cloth; tap it to turn it over. Say how far you've read (*Finished*, *Partway*, *Not yet*). The story map shows the premise and the turning points you've reached. Later ones stay sealed until you choose to reveal them.
3. **Moment.** What happened, on a dog-eared page, then three alternatives or "Something else". The app repeats your change back in one line before writing.
4. **Story.** A clothbound cover swings open as the first words arrive. Turn the pages with a real page curl: the title page, the "edit" page, chapters with raised capitals, how it ends, and a closing bookplate. It's saved automatically; a ribbon drops to show it.

## How it's organised

```
Otherwise/
  App/             Entry point
  DesignSystem/    Tokens (paper, ink, type, editions), book components, gallery → DESIGN_SYSTEM.md
  Resources/Fonts/ Newsreader (OFL), the serif used inside the books
  Models/          Book, Story, StoryMap, Catalog (12 hand-written maps), Version & ShelfEntry (SwiftData)
  Services/        OpenLibrary, StoryEngine (Foundation Models + tolerant text parser)
  Features/        Library, Book (progress, story map, moment sheet), Story (page-curl reader)
```

## Known limits

- Apple's on-device model is small (about 3B parameters). The structure, titles and chapters work reliably, but the prose is plain and sometimes drifts from the change. Hand-written maps for the classics keep the turning points accurate.
- For noticeably better stories, replace `StoryEngine.write` with a call to a larger cloud model. Nothing else depends on Foundation Models.
