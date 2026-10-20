# Plot Twist — Design System

Plot Twist lets you change one moment in any book and read how the story would have gone.

**The room is dark; the light comes from the books.** Plot Twist is dark only. Its language is
borrowed from Opal: a near-black room with light falling in from the top, frosted glass cards
with a lit top edge, capsule controls, light numerals, an arc that fills with light, and a
bracket that splits one thing into several. Two sources of light, and only two: the app's own
**twilight** gradient, and each book's **edition**.

Tokens live in `Otherwise/DesignSystem/Tokens/` (`DS.swift`, `Edition.swift`).
Components live in `Otherwise/DesignSystem/Components/`. Open `DesignSystemGallery.swift`
in the Xcode canvas to see every token and component.

## Principles

1. **The story is the interface.** Prose gets the best type, the most space, and nothing competing with it.
2. **Books are objects.** Covers, spines, ribbons, endpapers and page curls behave like the real thing. A book is drawn as one connected 3D object; it never comes apart mid-motion.
3. **Light means something.** Glow marks what's selected, what's primary, and which book you're in. Nothing glows for decoration.
4. **Colour belongs to the book.** On a book's screens, its edition lights the room, gauge, timeline, buttons, raised capitals and ribbons. Twilight belongs to screens that belong to no single book.
5. **No waiting.** Motion starts the frame you lift your finger, and is driven by one value, so it can't stall between steps.
6. **One primary action per screen. One sentence of guidance at most.**
7. **Nothing raw.** Views use tokens. Cover lettering is the one exception: it's illustration, so it uses fixed sizes like a printed cover.

## The room

| Token | Value | Use |
|---|---|---|
| `canvas` | `#030404` | Screen background |
| `surface` | `#111414` | Glass at rest: cards, fields, capsules |
| `surfaceRaised` | `#1B1F1F` | Lifted glass: pressed and selected states, folds |
| `glassTop` → `glassBottom` | `#181C1C` → `#0C0F0F` | A glass card's fill, lit from above (`Gradients.glass`) |
| `rim` | white 16% | The lit top edge of glass (`Gradients.glassEdge` fades it to 2%) |
| `hairline` | white 9% | Separators and quiet outlines |
| `ink` | `#F2F5F4` | Primary text and icons |
| `inkSecondary` | `#A2A9A7` | Authors, descriptions, guidance, unselected icons |
| `inkTertiary` | `#646B69` | Placeholders, footnotes, tracks |
| `accent` | `#CDBEFF` | Pale lavender: numerals, selection, tints off a book |
| `accentDeep` | `#8F72FF` | The glow behind the accent |
| `positive` / `caution` | `#57D9B7` / `#FF7383` | Good news / destructive actions |
| `page` / `pageInk` | `#0D0E0F` / `#E8E4DC` | Reader pages and their warm cream text |
| `fold` | `#1A1C1D` | Dog-ears and gutters |

**Twilight gradient** (`Gradients.twilight`, `twilightSweep` for arcs): periwinkle `#A9B8FF` → violet `#9B8CFF` → orchid `#D58BF2` → rose `#FFA9C7`, the sky just after sunset.

**Ambient light** (`AmbientBackground`): an elliptical glow from the top of the screen, 34% of the tint at the edge of the screen falling to nothing ~60% of the way down. Off a book it's `roomGlow`, a deep violet (`#6A4CFF`); in a book it's the edition's `glow`. Every screen gets it through `.dsScreen(glow:tint:)`.

The whole app runs dark: `UIUserInterfaceStyle = Dark` in the Info.plist and `.dsDarkOnly()` at the root.

## Editions

An edition is `cloth` + `foil` + `pattern`: a book is an object, not a theme.

- **`ink`** is the edition's light on black: the brighter of cloth and foil, mixed toward white until it reaches a luminance of 0.2. Numerals, rules, nodes, raised capitals.
- **`glow`** is the cloth itself (or the foil, if the cloth is nearly black): the ambient light of the book's screens and the pool of light under its spine in the stack.
- **`gradientColors`** = `[glow, ink]`: the book's arcs and glowing buttons.
- **Patterns:** dots, waves, lattice, stars, chevrons, leaves, checks, scallops, diamonds, drawn in `Canvas`.
- The 12 catalogue classics have hand-picked editions; any other book gets one of 12 palettes from a stable hash of its title.

## Typography

- **Newsreader** (bundled, registered by `DS.registerFonts()`) is the type *inside the books*: covers, spines, title pages, chapters, prose, folios.
- **San Francisco** is the *interface*: masthead, lists, controls, numerals, metadata.

| Token | Face | Use |
|---|---|---|
| `display` | Newsreader Display, 34 | Title pages (a book's, a story's) |
| `title` | Newsreader Heading, 24 | Moment titles |
| `chapter` | Newsreader Heading, 20 | Chapter headings, the bookplate |
| `reading` (+7 leading) | Newsreader Text, 17 | Prose |
| `raisedCap` | Newsreader Display, 44 | A chapter's opening initial |
| `quote` / `folio` | Newsreader Italic, 17 / 12 | Your change, blurbs / running heads |
| `stamp…(_:)` | Newsreader, fixed | Lettering on covers and spines |
| `masthead` | SF Subheadline semibold, tracked 2.4, caps | PLOT TWIST |
| `subtitle` / `eyebrow` | SF Caption 2, tracked 1.2, caps | Guidance line / section labels |
| `gauge` | SF 52 light, monospaced digits | The reading gauge |
| `stat` | SF Subheadline semibold, monospaced digits | Numbers in pills |
| `screenTitle` / `heading` / `rowTitle` | SF Title 2 semibold / Headline / Subheadline semibold | Titles |
| `body` / `label` / `meta` / `caption` (+ emphasis) | SF | Interface text |

Views never apply `.weight()`, `.bold()`, `.italic()` or `.fontDesign()` to a token: each variant is its own token.

## Space, shape, size, depth

- **Space:** a 4pt grid (`xxs 4 · xs 8 · s 12 · m 16 · l 24 · xl 32 · xxl 48`). Screen margin 20, page margin 28, reading column ≤ 620.
- **Radius:** `cover 3`, `s 14`, `m 24` (glass cards), `l 32`; capsules for every control. Always continuous.
- **Covers** are 2:3: 44×66, 104×156, 150×225, hero 232×348.
- **Slabs** (home): a book lying flat, `slabInset` 22 from each side, its spine `slabSpine` 34 tall, one book every `slabStride` 104.
- **Gauge:** 220 across, 7pt line, a 220° arc open at the bottom.
- **Touch targets** ≥ 44pt; primary buttons 54pt.
- **Depth:** `Depth.stack` 0.42 for slabs and the lifted book, `Depth.cover` 0.35 for a cover swinging open.

## Elevation and light

- `dsGlass()` / `dsGlassCapsule()` — the glass fill and lit edge.
- `dsGlow(color, radius:, strength:)` — light spilling onto the black. Used only for: selected items, the primary button, gauge and nodes, book glows.
- `dsCoverShadow()` — a book on the black: a deep shadow and a faint rim of light.

## Motion

| Token | Use |
|---|---|
| `standard` / `quick` | State changes / taps |
| `select` | The lit pill sliding between icons (springy) |
| `arrive(n)` | Content arriving on a new screen, each piece 60ms after the last |
| `reveal` | Generated text arriving |
| `ribbon` / `flip` | A ribbon dropping / a cover turning over |
| `coverOpen` | A story's cover swinging open |
| `openBook` | Taking a book from the stack and opening it (1.05s, linear; phases eased inside) |
| `handOver` | The opened book fading into the book's screen |
| `gauge` | The arc filling to your progress |
| `lift` / `settle` | Books lifting as the stack starts to move / settling back with a soft wobble when it stops |

Page turns use the system page curl. Every custom motion falls back to a fade under Reduce Motion.

## Home

| Element | Behaviour |
|---|---|
| Top bar | PLOT TWIST (`masthead`) on the left; on the right a glass capsule of three custom icons (`GlyphSwitcher`), like Opal's tab bar: **Library** (books on a shelf, one leaning), **Read** (a ribbon bookmark), **Twisted** (a path forking into two beads). The selected icon is filled with twilight and glows; a lit pill slides to it. Hidden while searching. |
| Masthead | One block at the top left, level with the icons: PLOT TWIST, and under it, in `subtitle` capitals, where you are: "Pick a book to twist" / "Books you’ve read" / "Stories you’ve changed". It cross-fades when you switch. |
| `BookStack` | Full-width slabs, after the Dumbling.FM stack: each book lies flat with its spine toward you and its cover tipping into view behind. The spine is panelled like a real one: the pattern on two end panels, foil bands, and a plain centre panel where the title and author are stamped in `Edition.lettering` (the foil, pushed lighter or darker until it reads at 4.5:1). A ribbon lies across the spine if you're partway, a seal if you've finished; nothing hangs outside the book. Books near the top lie flat (spine only); lower books show more cover; distant books sit in shadow. Each pools its colour on the black beneath it. **Library** is endless (classics, your books, then Open Library); **Read** is your books. |
| Scrolling | The books answer the scroll: as the stack starts to move on, their covers lift open a few degrees (as if riffled); moving back, they lie flatter; when it comes to rest they settle with a soft wobble. Each book moves on its own beat, top to bottom, so the lift and the settle ripple down the stack. Off under Reduce Motion. |
| Press / hold | A finger down brightens the book and its glow, with a light haptic. A tap opens it; holding (0.45s, firmer haptic) opens its manage sheet. |
| **Opening a book** | `BookOpening`, one motion from one value: the slab rises toward you, stands up and turns upright in your hands (spine swinging out of sight) while the room fills with the book's light; the cover swings open onto its endpaper; the first page comes up to fill the screen and becomes the book's screen, whose content arrives beneath it. Both drawings of the book (lying and upright) are identical at the hand-off, so nothing jumps. |
| Twisted | Your stories as glass cards: the book's cover, its title in its ink, your change, and the lit `TwistMark`. Tap to read; hold to read or remove; "Clear all" at the end, after one confirmation. |
| Manage sheets | The book's cover, title and detail, a glass close button, then `ActionRow`s. Removing a story asks once; removing a read tag doesn't. |

## A book

| Element | Behaviour |
|---|---|
| Title page | The book's title in `display`, an ornament, the byline, and the premise in italics. The room glows in the book's cloth. |
| `ReadingGauge` | Opal's score, for reading: an `ArcGauge` that fills to your progress (100% when finished) with a light numeral, a `BracketShape` splitting it into three `GlowPill`s — **Finished · Partway · Not yet**. Choosing saves straight away; Partway adds a slider in a glass card. |
| Story map | A timeline of glowing nodes in the edition's ink, with glass cards for turning points. Moments beyond your progress are sealed with wax and ask before revealing spoilers. A dashed card at the end for a change that isn't on the map. |
| Moment sheet | What happened, on a dark dog-eared page; then the alternatives, each **branching off one line** (`BranchRow`) — the chosen branch and card light up in the edition. Your change is said back in one line above **Rewrite from here**. |
| Reader | Dark pages (`page`) with cream prose, raised capitals in the edition's ink, the page curl, a ribbon when saved, and a bookplate at the end. |

## Components

`PrimaryButton` (glass lit from inside by twilight or an edition: `GlowButtonStyle`), `SecondaryButton`, `GlassIconButton`, `PressableButtonStyle`,
`GlyphView` / `GlyphSwitcher`, `ArcGauge`, `GlowPill`, `BracketShape`, `BranchRow`,
`ActionRow`, `ChoiceRow`, `ComposerField`, `GroupedSurface`, `InlineNotice`, `MessageView`, `WritingIndicator`,
`Eyebrow`, `QuoteBlock`, `Hairline`, `AmbientBackground`, `BookRow`, `VersionCard`, `TwistMark`,
`BookCover`, `FlippableCover`, `Endpaper`, `SlabBook` (`SlabCoverFace` + `SlabSpineFace`), `BookmarkRibbon`, `PageCard`, `Ornament`, `RaisedCapText`.

## App icon

After San Francisco Design Week's 2023 "Plot Twist" mark: **Plot** sits upright and **Twist** hangs upside down from the same line, its T under the P, so the words turn back on themselves, the way a plot twist does. Set in a bold grotesk (Inter Bold).

- **Light** (the default home screen): the twilight gradient edge to edge, type in near-black `#0E0A1C`.
- **Dark** (dark home screens): the black room with its violet glow, **Plot** in white and **Twist** lit with twilight.

## Voice

- Sentence case. Short, plain, second person.
- Buttons are verbs: "Rewrite from here", "Change another moment".
- Errors say what happened and what to do, in two sentences at most.
- Generated text is always labelled as imagined, never presented as the original book.
