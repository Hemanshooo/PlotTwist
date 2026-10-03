# Plot Twist — Design System

Plot Twist lets you change one moment in any book and read how the story would have gone.
The interface is **paper and ink**; the colour comes from **the books themselves**.

Tokens live in `Otherwise/DesignSystem/Tokens/` (`DS.swift`, `Edition.swift`).
Components live in `Otherwise/DesignSystem/Components/`. Open `DesignSystemGallery.swift`
in the Xcode canvas to see every token and component in light and dark.

## Principles

1. **The story is the interface.** Prose gets the best type, the most space, and nothing competing with it.
2. **Books are objects.** Covers, spines, ribbons, endpapers and page curls behave like the real thing. Delight comes from familiar physical gestures, never from decoration for its own sake.
3. **Colour belongs to the book.** Every book is bound in an *edition*. On a book's screens, its edition colours the header, timeline, buttons, raised capitals and ribbons. The app's own accent appears only on screens that belong to no single book (home, search).
4. **One primary action per screen.**
5. **Say only what's needed.** One sentence of guidance at most. No onboarding.
6. **Nothing raw.** Views use tokens. Cover lettering is the one exception: it is illustration, so it uses fixed sizes like a printed cover.

## Paper & ink

| Token | Light | Dark | Use |
|---|---|---|---|
| `canvas` | `#F4F1EB` | `#111110` | Screen background: soft bone paper |
| `surface` | `#FBFAF7` | `#1B1A19` | Pages, cards, fields |
| `ink` | `#171615` | `#EEEBE5` | Primary text |
| `inkSecondary` | `#6B675F` | `#A6A29B` | Authors, descriptions, guidance |
| `inkTertiary` | `#9C978F` | `#6F6B65` | Placeholders, folios |
| `hairline` | `#E3DED5` | `#2A2927` | Separators, borders, page edges |
| `accent` | `#2B4C8C` | `#8EAAE6` | Ink blue. App-level primary action, the selected top-bar option, destructive actions |
| `shelf` / `shelfEdge` | `#D9CFBE` / `#BBAE98` | `#34302B` / `#24211D` | The shelf plank (gallery only) |
| `fold` | `#E8E3D9` | `#272523` | Dog-ears, page gutters, sealed moments |

Text colours reach at least 4.5:1 on `canvas` and `surface` in both modes (tertiary is for non-essential text only).

## Editions

An edition is `cloth` + `foil` + `pattern`. Cloth and foil are the same in light and dark: a book is an object, not a theme.

- **`ink`** is the edition used on paper: the darker of the pair in light mode, the lighter in dark mode. Every pair is checked to reach at least 4.5:1 against the page in both modes.
- **`onInk`** is the label colour on `ink`: white or ink, whichever contrasts more.
- **Patterns:** dots, waves, lattice, stars, chevrons, leaves, checks, scallops, diamonds. All are drawn in `Canvas`, tiled at a size suited to the object (9pt on a thumbnail, 34pt on a header band).
- The 12 catalogue classics have hand-picked editions. Any other book gets one of 12 palettes and a pattern from a stable hash of its title, so it always looks the same.

## Typography

Two families, each with one job:

- **Newsreader** (serif; files and licence in `Resources/Fonts`, registered at launch by `DS.registerFonts()`) is the type *inside the books*: cover and spine lettering, title strips, title pages, chapter headings, prose, blurbs and folios. It is cut at three optical sizes: *Display* (opsz 72), *Heading* (opsz 28) and *Text* (opsz 12–16).
- **San Francisco** (the system font) is the *interface*: the masthead, top-bar options, lists, controls and metadata.

| Token | Face | Use |
|---|---|---|
| `display` | Newsreader Display, 30 | A book's or story's title page |
| `title` | Newsreader Heading Medium, 22 | Book title, moment titles |
| `chapter` | Newsreader Heading Medium, 20 | Chapter headings; the endpaper bookplate |
| `reading` (+7pt leading) | Newsreader Text, 17 | Generated prose |
| `raisedCap` | Newsreader Display, 40 | A chapter's opening initial, in the edition's ink |
| `quote` | Newsreader Text Italic, 17 | Your change; a book's blurb |
| `folio` | Newsreader Text Italic, 12 | Running heads and page numbers |
| `stamp(_:)`, `stampItalic(_:)`, `stampDisplay(_:)` | Newsreader, fixed size | Lettering on covers, spines and labels |
| `masthead` | SF Subheadline semibold, tracked 2.4, uppercase | The app's name at the top of home |
| `subtitle` | SF Caption 2 medium, tracked 1.2, uppercase | One line under the masthead |
| `heading` | SF Headline | Sheet, card and message titles |
| `rowTitle` | SF Subheadline semibold | Moments, choices, list titles |
| `quoteSmall` / `compose` | SF Footnote italic / Callout | Your change on a card / while writing it |
| `body` / `label` / `emphasis` | SF Subheadline / semibold / semibold | Interface text / buttons / notice titles |
| `meta` / `metaEmphasis` | SF Footnote / medium | Authors, years, progress |
| `caption` / `captionEmphasis` | SF Caption / medium | Small print |
| `eyebrow` | SF Caption 2 semibold, tracked 1.2, uppercase | Section labels, top-bar options |

Views never apply `.weight()`, `.bold()`, `.italic()` or `.fontDesign()` to a token: each variant is its own token.

## Space, shape, size

- **Space:** a 4pt grid (`xxs 4 · xs 8 · s 12 · m 16 · l 24 · xl 32 · xxl 48`). Screen margin is 20, page margin 28, and the reading column is at most 620.
- **Radius:** `cover 3` (books are nearly square-cornered), `s 10`, `m 18`, always continuous.
- **Covers** are always 2:3: 44×66, 104×156, 150×225 and the hero 232×348 (set down at 0.8× to open, so the spread fits the screen). Three medium covers fit across any iPhone. `ScaledBookCover` draws the hero cover scaled to any frame, so lettering keeps its proportions.
- **Stack:** each book takes a 92pt stride; its 30pt title strip faces you and its cover lies back under the next. Covers are inset 40pt from each side, at most 340pt wide. Perspective is `Depth.stack` (0.32).
- **Spines** vary between 34–46pt wide and 148–184pt tall, per book.
- **Touch targets** are never smaller than 44pt.

## Motion

| Token | Use |
|---|---|
| `standard` | State changes |
| `quick` | Taps and selections |
| `reveal` | Generated text arriving |
| `ribbon` | A bookmark ribbon dropping into place (springy) |
| `flip` | Turning a cover over |
| `slide` | A book sliding up out of the stack, or back into it |
| `coverOpen` / `coverClose` | A cover swinging open on its spine / shut again |
| `tilt` | A book tipping up toward you under your finger |
| `pullOut` | A book standing up in your hands |
| `unfold` | A first page coming up to fill the screen |

Page turns use the system page curl. Every custom animation falls back to a fade under Reduce Motion.

## Book elements

| Component | Behaviour |
|---|---|
| `BookCover` | A clothbound cover: patterned cloth, a stamped label panel with a double rule, and a hinge shadow. Titles are set in balanced lines and never break mid-word. |
| `FlippableCover` | Tap to turn the book over and read the blurb on the back. |
| `BookStack` (home) | Books laid back in a deep stack, like records in a crate. Each shows a cloth title strip (title, author, and a bookmark if you're partway or a seal if you've finished) above its cover. Covers lie back 50–76°, flattest just above the middle of the screen and opening up toward the edges as you scroll. |
| Home header | A masthead. Row one: PLOT TWIST (`masthead`) at the left, LIBRARY  READ  TWISTED at the right. Row two: the guidance line in `subtitle` capitals ("Pick a book to change its story." / "Pick a book you’ve read to change its story."), then a hairline rule across the page. |
| Library / Read | "LIBRARY  READ  TWISTED" at the top right of the navigation bar, set straight on the paper (no pill) in `eyebrow` capitals with `Tracking.eyebrow`. The collection you're in is in the accent; the other, and TWISTED, are in `inkSecondary`. Each keeps a 44pt touch height. **Library** is endless: every mapped classic, any other book you've logged, then more books from Open Library (English-language fiction for adults: classics first, then a run of genres, the most-published books first), loaded a page at a time as you near the bottom, with no duplicates. A small spinner shows below the last book while more load, or a quiet "Try again" if they can't; **Read** is only the books you've logged, most recent first. Read starts empty, with one button back to the library. Hidden while searching. |
| Stack press | While your finger is down, the cover tips up a further 20° toward you and grows 3%, with a light haptic. A tap takes the book out; holding it (0.45s, a firmer haptic) opens its manage sheet instead. Sliding off cancels. |
| Taking a book out | On release, the book slides up out of the stack while the others wait a beat and then fade. It stands up in your hands, is set down with its spine at the centre of the screen, and its cover swings open to the left, showing the endpaper on its inside. The first page (a half-title) comes up to fill the screen as the title page: title, author, blurb, your bookmark (a ribbon drops in if you're partway), and "Open the book". Swipe down or tap × and it closes, stands up, and slides back into its place. Under Reduce Motion it is a simple fade. |
| Twisted | Your saved versions sit behind TWISTED in the navigation bar, after Library / Read (shown once you have one). It opens the "Twisted books" sheet. Tap a story to read it; hold it to open its manage sheet ("Read this story", "Remove from Twisted"). "Clear all" at the top right empties the section after one confirmation, and the sheet closes when nothing is left. |
| Manage sheets | Bottom sheets opened by holding a book or a story: the book's small cover, a title and a line of detail, a close button, then `ActionRow`s grouped under eyebrows. A book's sheet offers **Remove from Read** (if you've logged it; its later turning points seal again) and lists each **twisted version** of it to remove. If there is nothing to manage it says so in one line. Removing a story always asks once, since it can't be undone; removing a read tag doesn't, since it's easy to redo. |
| `BookSpine` + `Shelf` | Spines on a shelf plank, with press tilt. Kept in the gallery; no longer on home. |
| `BookmarkRibbon` | A satin ribbon with a swallow-tail end. It drops onto the chosen alternative, and onto the reader when a version is saved. |
| `PageCard` | A dog-eared page that holds "what happened in the book". |
| `Endpaper` | The inside of a cover with an *Ex libris* bookplate, shown as the cover swings open. The story's last page is the back endpaper. |
| `Ornament` | A printer's rule and lozenge between sections. |
| `RaisedCapText` | A chapter's opening paragraph, with its initial set in the edition's ink. |
| Sealed moment | Turning points beyond your reading progress are sealed with wax. Tapping one asks before revealing spoilers. |
| Reader pages | Running head, folio, gutter shading, the page curl and a soft haptic on each turn. The "edit" page strikes through what happened in the book. |

## Interface components

`PrimaryButton` (accent, or `edition:` for a book's colours), `SecondaryButton`, `ActionRow` (an icon, title and detail on a paper card; destructive actions in the accent), `ChoiceRow`, `ComposerField`,
`GroupedSurface`, `InlineNotice`, `MessageView`, `WritingIndicator`, `Eyebrow`, `QuoteBlock`, `Hairline`,
`BookRow`, `VersionCard` (marked with `TwistMark`: the `arrow.triangle.branch` symbol in the edition's ink on a tinted disc), `ReadingProgressCard` / `ReadingProgressChip`.

## Voice

- Sentence case. Short, plain, second person.
- Buttons are verbs: "Open the book", "Open the story map", "Rewrite from here", "Change another moment".
- Errors say what happened and what to do, in two sentences at most.
- Generated text is always labelled as imagined, never presented as the original book.
