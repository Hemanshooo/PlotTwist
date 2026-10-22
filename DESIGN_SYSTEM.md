# Plot Twist — Design System

Plot Twist lets you change one moment in any book and read how the story would have gone.

**A garden of forking paths, set like a type specimen.** Every story in the app is a fork in a
path, so a garden grows through it: stems, leaves and roses in two flat colours, after Type Garden.
Around the garden everything is quiet: a flat ground, a crisp display serif, small mono labels,
outlined pills and hairlines. There are no gradients, glows or glass, and no drop shadows except
under the books themselves, which are objects.

Tokens live in `Otherwise/DesignSystem/Tokens/` (`DS.swift`, `Palette.swift`, `Edition.swift`).
Components live in `Otherwise/DesignSystem/Components/`. Open `DesignSystemGallery.swift` in the
Xcode canvas to see every token and component, and switch palettes from its top.

## Principles

1. **The story is the interface.** Prose gets the best type, the most space, and nothing competing with it.
2. **Books are objects.** Covers, spines, ribbons, endpapers and page curls behave like the real thing. A book is drawn as one connected 3D object; it never comes apart mid-motion.
3. **The garden means something.** A rose is a moment you've reached, a finished book, the choice you've made. A bud is a moment still ahead. A stem is the path a story takes. Nothing grows for decoration alone.
4. **Two colours, used flat.** Stems and blooms. Everything else is ground and ink.
5. **Type does the work.** Instrument Serif for display, Newsreader for reading, DM Mono for the interface. Sections are separated by an eyebrow and a hairline, not by boxes.
6. **No waiting.** Motion starts the frame you lift your finger, and is driven by one value, so it can't stall between steps.
7. **One primary action per screen.**
8. **Nothing raw.** Views use tokens. Two exceptions: cover lettering is illustration, so it uses fixed sizes like a printed cover; and the palette sheet's swatches draw each palette in its own colours.

## Palettes

Plot Twist can be read in four rooms. **Rose noir** is the default. The reader picks another from
the palette sheet (the two-dot swatch in the top bar), and the whole app recolours at once.

| Palette | Ground | Ink | Stem | Bloom | Petal | System chrome |
|---|---|---|---|---|---|---|
| **Rose noir** | `#000000` | `#FFFFFF` | cobalt `#3257FF` | vermilion `#FF1400` | `#FFB4A8` | dark |
| **Paper** | `#F3EEE4` | `#111111` | navy `#1C2B8F` | vermilion `#FF3B1F` | `#FFD2C4` | light |
| **Midnight** | `#0C1445` | `#F5F2FF` | lavender `#9C8CFF` | coral `#FF6B57` | `#FFD3CB` | dark |
| **Citrus** | `#0E1A12` | `#F4F7EF` | green `#3CC46D` | orange `#FF8A1E` | `#FFE1B5` | dark |

Each palette (`Palette.Scheme`) also defines `surface` and `raised` (one and two steps off the
ground), `inkSecondary` and `inkTertiary`, `hairline`, `caution`, `page` and `pageInk` (the
reader's paper), `shadow`, and two values for the book stack: `fog` (distant books sink into
shadow on dark grounds and into haze on light ones) and `coverFalloff` (how much a lying cover
darkens toward its far edge).

**How it works.** `Theme.shared` is `@Observable` and holds the palette. Every `DS.Colors` token
reads it, so any view whose body reads a colour redraws when the palette changes. The palette is
saved in `UserDefaults`. `dsColorScheme()` sets the system chrome to match, at the root and on
every sheet. UIKit appearance (navigation titles, the search field) is refreshed on each change.

| Token | Use |
|---|---|
| `canvas` | Every screen's ground (`dsScreen()`) |
| `surface` | Panels and fields (`dsPanel()`, `ComposerField`) |
| `raised` | Selected and pressed things, the selected icon's pill, folds, disabled buttons |
| `ink` | Text, the selected pill, the primary button; the tint for system controls |
| `onInk` | Text on `ink` (the ground colour) |
| `inkSecondary` / `inkTertiary` | Supporting text / hints, folios, sealed things, unselected icons |
| `hairline` | Separators and outlines |
| `stem` / `bloom` / `petal` | The garden. `bloom` also marks raised capitals, ribbons, strikethroughs and quote rules |
| `caution` | Destructive actions |
| `page` / `pageInk` | Reader pages and their text |

## Editions

An edition is `cloth` + `foil` + `pattern`: a book is an object, not a theme. Editions colour the
books themselves (covers, spines, endpapers, the cover that swings open over a story). The rest of
the app takes its colour from the palette.

- **`lettering`** is the foil, pushed lighter or darker until it reads against the cloth at 4.5:1. It's used for spine titles and authors, ribbons, and the rose stamped on a finished book's spine.
- **Patterns:** dots, waves, lattice, stars, chevrons, leaves, checks, scallops, diamonds, drawn in `Canvas`.
- The 12 catalogue classics have hand-picked editions. Any other book gets one of 12 palettes from a stable hash of its title.

## Typography

Three families, each with one job, all bundled in `Resources/Fonts` (OFL) and registered at launch.

| Token | Face | Use |
|---|---|---|
| `display` | Instrument Serif, 46 | Title pages (a book's, a story's) |
| `title` | Instrument Serif, 32 | Moment and sheet titles, "The End", "How far have you read?" |
| `chapter` | Instrument Serif, 28 | Chapter headings, the bookplate |
| `heading` | Instrument Serif, 24 | Titles in lists: moments, twisted stories, search results |
| `numeral` | Instrument Serif, 84 | The reading numeral |
| `raisedCap` | Instrument Serif, 62 | A chapter's opening initial, in `bloom` |
| `wordmark(_:)` | Instrument Serif, fixed (22 in the top bar) | The wordmark, drawn with its garland |
| `reading` (+7 leading) | Newsreader Text, 17 | Prose |
| `blurb` | Newsreader Text, 15 | Descriptions, choices, messages |
| `quote` / `quoteSmall` | Newsreader Italic, 17 / 15 | Your change, premises |
| `compose` | Newsreader Text, 17 | The field where you write your change |
| `label` | DM Mono Medium, 13 | Buttons and pills |
| `tab` | DM Mono Medium, 12 | The tabs in the top bar |
| `meta` | DM Mono, 12 | Bylines, metadata |
| `caption` | DM Mono, 11 | Hints (`Hint`, lowercase) |
| `eyebrow` | DM Mono Medium, 11, caps, tracked 1.3 | Section labels (`Eyebrow`) |
| `folio` | DM Mono, 10 | Running heads and page numbers |
| `stamp…(_:)` | Newsreader, fixed | Lettering on covers and spines |

`dsDisplay(_:)` sets a display font with its tracking (−0.4) and the ink. Every style scales with Dynamic Type.

## The garden

`Garden.swift` draws everything from a handful of paths (`Botany`):

- a **rose** seen three-quarters on: a wide head with a scalloped edge, tipped a few degrees, with a loose spiral at its heart and two wavy petal edges drawn in `petal` (after Type Garden's roses);
- a pointed **leaf**, with a vein cut in the ground colour;
- a closed **bud** with two sepals;
- a **tendril** that curls in on itself;
- smooth **stems** through points.

`GraphicsContext` helpers (`drawRose`, `drawLeaf`, `drawBud`, `drawStem`) take a `GardenInk`
(stem, bloom, petal, ground) that a view reads once in its body.

Every drawing is `Animatable` with a `progress` (0…1), so it can **grow**. Stems draw themselves
(trimmed paths), leaves unfurl as the stem passes them, and roses open last with a little
overshoot (`Ease.opening`). `Growing { progress in … }` grows a drawing once, when it first
appears; under Reduce Motion it appears fully grown. Each rose takes a `seed`, so no two roses
are alike but each one is always the same.

| Drawing | Where |
|---|---|
| `Wordmark` | "Plot Twist" set plainly in Instrument Serif, with a garland grown around it: two vines winding through the words (in front of some letters, behind others) and curling at their ends, leaves along them, and roses before Plot, over the T, in a pair after Twist and one below. `WordmarkGarland` draws it from ems of the type size, so it scales. It grows when the library opens (vines, then leaves, then roses); tapping it grows it again. |
| `Flourish` | A printer's flourish: a rose at the heart of a short stem, leaves either side, tendrils at both ends. Under titles and in the reader. |
| `VineGauge` | How far you've read: a dotted path for the whole book, the stem grown along it, leaves as it passes, a bud at the tip while you're partway, and a rose when you've finished. |
| Story map vine | One stem winding down the map; each row's stretch bows once, alternately left and right. A curl and a seed where the story begins, a rose at every moment you've reached, a muted bud at each moment still sealed, and a curl at the end. |
| `BranchRow` | The alternatives branching off a moment. Every branch carries a leaf, and the chosen one opens a rose. |
| `TwistMark` | One stem forking in two, a leaf on one branch and a rose on the other. On every twisted story. |
| `Sprig` | A stem rising with leaves and a rose. Used in empty states. |
| `Rose` / `Bud` | On their own. |

## Space, shape, size, depth

- **Space:** a 4pt grid (`xxs 4 · xs 8 · s 12 · m 16 · l 24 · xl 32 · xxl 48`). Screen margin 20, page margin 28, reading column ≤ 620.
- **Radius:** `cover 3`, `s 12` (cards, fields, choices), `m 18` (swatches), `l 28`. Every control is a capsule. Corners are always continuous.
- **Covers** are 2:3: 44×66, 104×156, 150×225, and hero 232×348.
- **Slabs** (home): a book lying flat, `slabInset` 22 from each side, its spine `slabSpine` 34 tall, one book every `slabStride` 104.
- **Garden:** stems are `1.8`, and roses on the map are `20`. The story map's vine grows in a `34` gutter, and the reading vine is `56` tall.
- **Top bar:** the wordmark is set at `wordmark` 22 (its garland makes it about 105 × 41); tabs are `tab` 32 tall; the palette swatch is `navItem` 38.
- **Touch targets** are at least 44pt; primary buttons are 52pt; pills are 36pt.
- **Depth:** `Depth.stack` 0.42 for slabs and the lifted book, `Depth.cover` 0.35 for a cover swinging open.

## Surfaces

- `dsScreen()`: the flat ground, the reading face as default text, and ink as the tint.
- `dsPanel()`: `surface` with a hairline. Used for notices.
- `dsOutline(isSelected:)`: a hairline on the ground. Selected, it fills with `raised` and takes a 1.2pt ink edge. Used for choices, moment cards and action rows.
- `Hairline`: under every `Eyebrow` that opens a section.
- `dsCoverShadow()`: books only. A fine edge, a contact shadow and a soft one, in the palette's `shadow`. Turned off (`BookCover(isShadowed: false)`) where a cover is one face of a 3D book.

## Motion

| Token | Use |
|---|---|
| `standard` / `quick` | State changes / taps |
| `select` | A pill sliding between options (springy) |
| `arrive(n)` | Content arriving on a new screen, each piece 60ms after the last |
| `reveal` | Generated text arriving |
| `ribbon` / `flip` | A ribbon dropping / a cover turning over |
| `coverOpen` | A story's cover swinging open |
| `openBook` | Taking a book from the stack and opening it (1.05s, linear; phases eased inside) |
| `handOver` | The opened book fading into the book's screen |
| `grow` | A stem drawing itself |
| `bloom(n)` | A rose or leaf opening, staggered |
| `palette` | The whole app changing palette |
| `lift` / `settle` | Books lifting as the stack starts to move / settling back with a soft wobble when it stops |

Page turns use the system page curl. Under Reduce Motion, every custom motion falls back to a fade, or to the finished drawing.

## Home

| Element | Behaviour |
|---|---|
| Top bar | The `Wordmark` sits on the left. On the right are the palette swatch (`PaletteButton`: the current bloom and stem as two overlapping dots) and the `TabSwitcher`: **Library · Read · Twisted** in mono, in an outlined capsule, the chosen one in a solid ink pill that slides between them, like Type Garden's Type / Poster toggle. The tabs are hidden while searching. |
| `BookStack` | Full-width slabs, after the Dumbling.FM stack. Each book lies flat with its spine toward you and its cover tipping into view behind. The spine is panelled like a real one: the pattern on two end panels, foil bands, and a plain centre panel where the title and author are stamped in `Edition.lettering`. A ribbon lies across the spine if you're partway, and a rose is stamped in foil if you've finished. Books near the top lie flat (spine only), lower books show more cover, and distant books recede by the palette's `fog`. **Library** is endless (classics, your books, then Open Library); **Read** is your books. |
| Scrolling | The books answer the scroll. As the stack starts to move on, their covers lift open a few degrees (as if riffled); moving back, they lie flatter; when it comes to rest they settle with a soft wobble. Each book moves on its own beat, top to bottom, so the lift and the settle ripple down the stack. Off under Reduce Motion. |
| Press / hold | A finger down brightens the book and deepens its shadow, with a light haptic. A tap opens it; holding for 0.45s (firmer haptic) opens its manage sheet. |
| **Opening a book** | `BookOpening`, one motion driven by one value. The slab rises toward you, stands up and turns upright in your hands (its spine swinging out of sight) while the rest of the library falls away. The cover swings open onto its endpaper. The first page comes up to fill the screen and becomes the book's screen, whose content arrives beneath it. The lying and upright drawings of the book are identical at the hand-off, so nothing jumps. |
| Twisted | Your stories as index entries between hairlines: the book's cover, its title in mono capitals, the story's title in the display serif, your change in italics, and the `TwistMark`. Tap to read; hold to read or remove. "Clear all" sits at the end and asks once. |
| Palette sheet | "Pick a room to read in": four swatches, each drawn in its own palette (its ground, a rose and a leaf, and "Aa" in its ink). Tapping one recolours the app behind the sheet at once. |
| Manage sheets | The book's cover, title and detail, an outlined close button, then `ActionRow`s. Removing a story asks once; removing a read tag doesn't. |

## A book

| Element | Behaviour |
|---|---|
| Title page | The byline in mono, the title in `display`, a `Flourish` that grows, and the premise in italics. |
| `ReadingGauge` | "Your reading" over a hairline, then the numeral (or "How far have you read?" before you've said), the `VineGauge`, and `ChoicePills` (**Finished · Partway · Not yet**), with the chosen one a solid ink pill. Choosing saves straight away; Partway adds a slider in an outline. |
| Story map | The vine, with outlined cards for turning points (mono chapter, serif title, a two-line summary). Moments beyond your progress are still in bud, with dashed outlines, and ask before revealing spoilers. A dashed card at the end is for a change that isn't on the map. |
| Moment sheet | The chapter and title, then what happened on a dog-eared page, then the alternatives branching off one stem (`BranchRow` + `ChoiceRow`); the chosen branch opens a rose. Your change is said back in one line above **Rewrite from here**. |
| Reader | Pages in the palette's `page` and `pageInk`, with mono running heads and folios, chapter labels in `bloom`, serif chapter headings, flourishes, and raised capitals in `bloom`. Pages turn with the page curl, a ribbon drops when the story is saved, and a bookplate closes the book. |

## Components

- **Buttons:** `PrimaryButton` (solid ink capsule, mono label), `SecondaryButton` (outlined capsule), `CircleButton`, `PressableButtonStyle`.
- **Navigation and choice:** `TabSwitcher`, `PaletteButton`, `ChoicePills`, `VineGauge`, `BranchRow`.
- **Rows and fields:** `ActionRow`, `ChoiceRow`, `ComposerField`, `InlineNotice`, `MessageView`, `WritingIndicator`.
- **Text:** `Eyebrow`, `Hint`, `QuoteBlock`, `Hairline`.
- **Lists:** `BookRow`, `VersionCard`, `TwistMark`.
- **Garden:** `Rose`, `Bud`, `Flourish`, `Sprig`, `Growing`, `Wordmark` / `WordmarkGarland`.
- **Book objects:** `BookCover`, `FlippableCover`, `Endpaper`, `SlabBook` (`SlabCoverFace` + `SlabSpineFace`), `BookmarkRibbon`, `PageCard`, `Ornament` (on covers), `RaisedCapText`.

## App icon

The wordmark with its garland: "Plot Twist" in Instrument Serif on one line, two vines winding through it, roses at both ends and over the T.

- **Light** home screens get **Paper**: cream ground, black type, navy vines, vermilion roses.
- **Dark** home screens get **Rose noir**: black ground, white type, cobalt vines, vermilion roses.

## Voice

- Sentence case for titles and buttons; lowercase for hints ("tap to read · hold to manage").
- Short, plain, second person.
- Buttons are verbs: "Rewrite from here", "Change another moment".
- Errors say what happened and what to do, in two sentences at most.
- Generated text is always labelled as imagined, never presented as the original book.
