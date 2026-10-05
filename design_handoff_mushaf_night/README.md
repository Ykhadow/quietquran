# Handoff: Mushaf · Night (Quran reader redesign)

## Overview
A visual and interaction redesign for **Mushaf**, a free, open-source Quran reader (no ads, no tracking, no accounts) built in **Flutter** for Android and iOS first, with tablet and desktop next. The main idea: **the Quran is the interface.** The reader is immersive by default, and chrome only appears when the user asks for it. This package is the chosen final direction, **"Night"**. It has a dark mode (default) and a light "Day" mode.

The full product brief is in `DESIGN_BRIEF.md`. It is the source of truth for scope, editions, accessibility and breakpoints. This README covers the visual and interaction decisions made on top of the brief.

## About the design files
The files in `design/` are **design references built in HTML**. They are prototypes that show the intended look and behavior, not production code to copy. The task is to **recreate these designs in the Flutter app**, using its existing structure (the current build uses stock Material 3). Map the tokens below onto a `ThemeData` / `ThemeExtension`, and build the widgets natively.

To view them, open `design/Mushaf Night.dc.html` in a browser, keeping `support.js` and `MushafPage.dc.html` in the same folder. It needs internet access for the Google Fonts and the Quran fonts.

## Fidelity
**High-fidelity** for colors, type, spacing, radii and component shapes on the screens shown. Recreate those closely.

**Placeholders:** the Quran line breaks and page contents in the mocks are approximate. Real pages must come from the app's existing per-edition line and page data, with exact printed lines. Do not copy the mock text layout.

## Screens covered
In `screenshots/dark.png` and `screenshots/light.png`, each theme shows:
1. Home (phone, 390×844)
2. Reader · immersive
3. Reader · overlay in a session
4. Reader · scrubbing
5. Tablet landscape · two-page spread (1180×820)

**Not yet designed** (build from the brief using this system): onboarding, the New session sheet, the Bookmarks empty state, Settings (including the palette editor and downloads manager), reflow mode, the printed-page loading/offline states, the ayah long-press sheet, the Browsing reader state (a free read with a "Save as session" action) and the app icon.

---

## Concept: Sessions
Home is built around **reading sessions**, not a single "Continue reading" item.
- A session is a named place to resume from, for example "Daily reading", "Night · Al-Mulk" or "Friday · Al-Kahf". Each one stores its own last page and ayah.
- One session is the **current session**, shown as the raised card at the top of Home.
- **Other sessions** are listed below it, with a **+ New** action.
- Opening the Quran from Browse (a surah or juz) starts a **Browsing** read, which is not tied to any session. The reader's title then says "Browsing", and the user can save the read as a session.
- The reader title always shows the active session's name, or "Browsing".

---

## Screen specs (phone, 390 wide)

### Home
A column on `bg`. The status bar is 44px tall.

**App bar** (padding 4px 10px 0 22px)
- Wordmark "Mushaf": Newsreader italic 22px, color `ink`.
- On the right, two 48×48 icon buttons in `mut`:
  - Go to page (a `#` glyph, stroke 1.75, 21px)
  - Settings (a sliders icon, 22px)

**Daily reading card (current session)**
- Margin 10px 16px 0, padding 18px 20px, radius 22, fill `surf`, 1px inset border `line2`. Children are 10px apart.
- Eyebrow: a refresh icon (13px, stroke 2.4) plus "DAILY READING". Source Sans 3, 600, 12px, letter-spacing 0.12em, uppercase, color `acc`.
- Last-read line: the final line the user read, in Quran script (UthmanicHafs, 32px, line-height 1.9, RTL, right-aligned). It ends with an ayah marker (see Components). **This line is the resume point.**
- Bottom row, space-between:
  - Left: "An-Nas" in Newsreader 20px, then "114:6" in `mut` 15px. Below that, "Page 604 · Juz 30" at 13px in `mut`.
  - Right: a **Resume** pill, 48px tall, radius 24, fill `acc`, text `onAcc` 15px/600, padding 0 24px.

**Other sessions**
- Header row (padding 22px 16px 6px 24px):
  - "OTHER SESSIONS" eyebrow in `mut`.
  - "+ New" on the right: 14px/600 `acc`, 36px tall hit area. It opens the New session sheet.
- Grouped card: margin 0 16px, radius 18, `surf`, inset `line2`, padding 0 6px 0 16px.
- Each row is at least 56px tall with a 12px gap. Rows are separated by a 1px divider (`rgba(128,120,108,0.22)`); the last row has none. A row contains:
  - a refresh icon, 15px, `mut`
  - the name in Newsreader 17px, taking the remaining width
  - meta text such as "p. 562", 13px `mut`
  - a chevron in a 36×44 hit area

**Browse**
- "BROWSE" eyebrow (padding 22px 24px 8px).
- **Segmented control**: 3 equal columns (Surahs / Juz / Bookmarks), padding 4, radius 22, fill `surf`, inset `line2`, 14px text.
  - Each segment is 40px tall.
  - Selected segment: radius 18, fill `bg`, shadow `0 1px 3px shadow`, weight 600.
  - Unselected segments are `mut`.
- **Surah list rows** (padding 6px 22px 0): a grid with columns `32px 1fr auto`, gap 12, at least 64px tall, bottom border 1px `line`.
  - Number: a 32×32 square, radius 10, 1px inset `line`, 13px tabular figures in `mut`.
  - Middle: English name in Newsreader 18px/1.2. Below it, "{verses} verses · p. {page}" at 13px `mut`.
  - Arabic name: Amiri 23px, RTL.
  - The brief also lists meaning and Meccan/Medinan. Add them to the subline if space allows.
- The Juz tab uses the same row shape: juz number square, starting surah and ayah, page, and the Arabic juz name.

### Reader · immersive
Full-bleed page (see Page), with no chrome. Tap to toggle the overlay. The overlay auto-hides after about 3 seconds without interaction.

### Reader · overlay in a session
Both bars are solid `bg`, never translucent.

**Top bar**: 64px tall, sits below the status bar, border-bottom 1px `line2`. A 3-column grid: `56px 1fr 56px`.
- Left: back arrow, 48×48 hit area.
- Center: session title, 14px/600, with an `acc` refresh icon (14px) in front. Shows the session name, or "Browsing".
- Right: bookmark toggle, 48×48.

**Bottom sheet**: border-top 1px `line2`, padding 16px 16px 30px 22px, gap 14.
- Row 1:
  - Surah name in Newsreader 17px, with "Juz 30 · 604 of 604" at 13px `mut` below it.
  - Then two 48px round buttons, fill `surf`:
    - **Aa**: Newsreader 18px. It opens display options: Mushaf ↔ Reflow, text size, and Text ↔ Printed, shown only when the edition has both.
    - **Settings**
- Row 2: the **juz scrubber** (see Components).
- Row 3: end labels "Juz 30" on the left and "Juz 1" on the right, 12px `mut`. They sit this way round because the strip runs RTL.

### Reader · scrubbing
Shown while the user drags the scrubber handle.
- The page is covered by a `veil`.
- Preview block, centered at about 260px from the top:
  - "JUZ 29" eyebrow in `acc`
  - the juz name in Arabic, Amiri 64px (for example تبارك الذي)
  - the surah name in Newsreader 22px
  - "Page 562 of 604" at 14px `mut`
- The scrubber moves to the bottom (padding 0 22px 40px), with a larger handle: 18×36, radius 9, and a 4px ring in `ring`.
- Labels below it: 30 / 15 / 1.
- On release, jump to the first page of that juz. Haptic tick on each juz boundary.

### Tablet landscape · spread
- The canvas is `bg`. Two pages of 474×740 each (about 0.64 aspect ratio), 28px apart, divided by a 1px `line` spine that is 620px tall.
- **The odd page is on the right and the even page is on the left.**
- A subtle gutter shadow falls on each page's inner edge. It is 7% of the page width: `rgba(0,0,0,0.4)` → 0 on dark, about 0.16 alpha warm brown on light.
- Page turns run right to left.
- Keyboard: ← → / PgUp / PgDn / Space / Home / End.

---

## Components

### Page (Mushaf text page, "Margin" style)
Built as `MushafPage`, variant `d` for dark and `e` with tone `day` for light. The page has **no frame**, just wide margins. All sizes are relative to the page box (cqw = % of page width, cqh = % of page height).
- **Padding**: 6cqh top, 8cqw sides, 3.5cqh bottom.
- **Running head** (RTL, space-between, padding-bottom 1.5cqh):
  - the surah name(s) on this page in Noto Naskh Arabic 3.4cqw, color `acc`
  - "JUZ N" in Source Sans 3 2.6cqw, letter-spacing 0.12em, `mut`
- **Body**: 15 lines (or the edition's line count), each flex:1 with equal height.
  - Text lines are justified across the full width (`text-align: justify` plus a last-line rule). Real line breaks come from the edition data.
  - Font size is about 5.6cqw for Madani and 5.3cqw for IndoPak, and 4.9cqw on pages 1 and 2, which are centered.
- **Page number**: Latin digits, Source Sans 3 2.8cqw, `mut`, centered, padding-top 1.5cqh.
- **Quran fonts** (fixed; never substitute):
  - Madani: KFGQPC Uthmanic Hafs (`UthmanicHafs1Ver18.woff2` in the mock)
  - IndoPak: IndoPak Nastaleeq (`indopak-nastaleeq-waqf-lazim-v4.2.1.woff2`)
  - In the mocks, both are loaded from verses.quran.foundation.

### Surah header band
A single row, RTL, gap 2.5cqw. From right to left:
- Meccan/Medinan label: Noto Naskh 2.8cqw, `mut`
- a flexible 1px rule in `rule`
- the surah name (for example سُورَةُ النَّاسِ): Quran font 5.4cqw, `acc`
- another flexible 1px rule
- the verse count (for example آياتها ٦): 2.8cqw `mut`

The **bismillah** line sits directly below it, centered, at body size.

### Ayah-end marker
An inline circle, 1.1em × 1.1em, with a 0.06em border in `acc`. It holds the verse number in Arabic-Indic digits: Noto Naskh 0.78em, with the digit scaled to 0.85em, color `acc`.
- It sits on the vertical middle of the line.
- IndoPak uses the Urdu digit forms (۱۲۳).

### Juz scrubber
- A **30-cell strip laid out RTL**, so Juz 1 is on the right. Cells have flex:1, a 2px gap, radius 2, and are 22px tall.
- Cell colors (dark / light):
  - normal cells: `#3a3b35` / `#d9d1c3`
  - **every 5th juz** (5, 10, 15…), darker as a landmark: `#4a4b44` / `#c9bfae`
  - current juz: `acc`
- Handle at rest: 14×36, radius 7, fill `ink`, with a 3px ring in `bg`.
- Handle while dragging: 18×36, radius 9, with a 4px `ring`.
- The whole strip is draggable. It snaps by page and shows the juz preview while dragging. Target height is at least 48dp including padding.

### List row, segmented control, grouped card, pill button
Specified under Home above.

---

## Interactions and behavior
- **Reader tap**: toggles the overlay. Fade it in over 150ms and out over 200ms (ease-out). Auto-hide after about 3s, but not while scrubbing or while a sheet is open.
- **Page turn**: a horizontal slide, right to left (swipe right for the next page). Under reduced motion, use a crossfade. No page curl.
- **Resume**: opens the reader at the session's saved page and ayah.
- **Session row tap**: switches the current session and opens the reader.
- **+ New**: opens the New session sheet (not yet designed): name the session, pick a starting surah, juz or page.
- **Browse → surah/juz**: opens the reader as "Browsing". Saving the read turns it into a session.
- **Bookmark icon**: toggles a bookmark on the current page. Bookmarks appear under the Browse › Bookmarks segment.
- **Aa**: a sheet with Mushaf/Reflow, text size (reflow only) and Text/Printed (only when available).
- **Scrubber**: while dragging, show the scrubbing state. On release, navigate there and return to the overlay.
- **Keyboard (desktop)**: every reader action must be reachable, as listed in the brief §8.
- **Screen-reader labels** on every icon button. The mocks' `aria-label`s are "Go to page", "Settings", "Back to home", "Bookmark this page" and "Display: Mushaf or Reflow, text size, Text or Printed".

## State
- `sessions[]`: id, name, lastPage, lastSurah, lastAyah, lastLineText, updatedAt
- `currentSessionId`
- `readerContext`: either a session id or "browsing"
- `overlayVisible`, `scrubbing`, and `scrubJuz` / `scrubPage`
- `browseTab`: surahs, juz or bookmarks
- `bookmarks[]`
- Settings: script, edition, reading mode, theme and palette. These are chosen once at first run (brief §3).

---

## Design tokens

### Color roles
| Role | Dark · Night | Light · Day | Use |
|---|---|---|---|
| `bg` | `#151614` | `#f4f0e8` | App and page background, bars |
| `surf` | `#20211d` | `#ebe5da` | Cards, segmented track, round buttons |
| `ink` | `#e4ddd0` | `#211f1b` | Primary text, Quran text, handle |
| `mut` | `#9a9387` | `#6e675c` | Secondary text, icons, page number |
| `acc` | `#d98e70` | `#a9532f` | Accent: markers, surah names, CTA, current juz |
| `onAcc` | `#151614` | `#fbf8f2` | Text on `acc` |
| `line` | `rgba(228,221,208,0.16)` | `rgba(33,31,27,0.16)` | List dividers, number squares, spine |
| `line2` | `rgba(228,221,208,0.10)` | `rgba(33,31,27,0.10)` | Card borders, bar borders |
| `rule` (page) | `rgba(228,221,208,0.20)` | `rgba(33,31,27,0.16)` | Surah header rules |
| `shadow` | `rgba(0,0,0,0.5)` | `rgba(33,31,27,0.16)` | Selected segment |
| `veil` | `rgba(12,12,11,0.90)` | `rgba(244,240,232,0.94)` | Scrubbing overlay |
| `ring` | `rgba(228,221,208,0.18)` | `rgba(33,31,27,0.12)` | Active handle ring |
| `juzCell` | `#3a3b35` | `#d9d1c3` | Scrubber cell |
| `juzCell5` | `#4a4b44` | `#c9bfae` | Every 5th cell |

Night is never pure white on pure black (brief §6).

For **palette presets** (Paper, Night, Sepia, Green, High contrast), each preset defines the brief's palette roles: page bg, ink, ayah marker, header fill, header text, frame accent and UI accent. These map onto `bg`, `ink` and `acc`, with `mut`, `surf` and `line` derived from them. **Palettes apply only to text rendering and chrome.** Printed page images are only dimmed in dark mode.

### Typography
| Token | Family | Size / weight | Use |
|---|---|---|---|
| wordmark | Newsreader italic | 22 / 400 | "Mushaf" |
| title-lg | Newsreader | 20–22 / 400 | Card surah, scrub surah |
| title | Newsreader | 17–18 / 400, lh 1.2 | Row names, overlay surah |
| body | Source Sans 3 | 15 / 400–600 | Buttons, body |
| label | Source Sans 3 | 14 / 600 | Segments, bar title, "+ New" |
| caption | Source Sans 3 | 13 / 400 | Meta lines |
| eyebrow | Source Sans 3 | 12 / 600, +0.12em, uppercase | Section labels |
| small | Source Sans 3 | 12 / 400 | Scrubber labels |
| arabic-ui | Amiri | 23 (rows), 64 (scrub preview) | Surah and juz names |
| arabic-small | Noto Naskh Arabic | 400/600 | Running heads, marker digits |
| quran | UthmanicHafs / IndoPak Nastaleeq | 32 (card); page-relative in reader | Quran text only |

For a future Urdu/Arabic UI font, **Noto Naskh Arabic** is recommended, with Noto Nastaliq Urdu for Urdu. The UI should respect the system font scale.

### Spacing
- A 4-based scale: 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 28, 32.
- Screen gutter: 16 for cards, 22–24 for lists and labels.
- Section spacing: 22 above each eyebrow.

### Radii
| Value | Use |
|---|---|
| 2 | Juz cells |
| 7 / 9 | Scrubber handle (rest / active) |
| 10 | Number squares |
| 18 | Grouped list card, selected segment |
| 22 | Hero card, segmented track |
| 24 | Pill and round buttons (fully rounded) |

### Elevation
The design is essentially flat; separation comes from `surf` fills and 1px inset borders.
- Only shadow: the selected segment (`0 1px 3px shadow`).
- Bars are solid `bg` with 1px `line2` borders. No blur, no glass.

### Touch targets
Every interactive element is at least 48dp (the icon buttons are 48×48, the pill is 48 tall).

## Assets
- **Icons**: Lucide-style line icons (stroke 1.75, and 2–2.4 when small): hash, sliders-horizontal, rotate-cw (session), chevron-right, arrow-left, bookmark. Use `lucide_icons` for Flutter, or an equivalent set.
- **Fonts**: Newsreader, Source Sans 3, Amiri, Noto Naskh Arabic (all Google Fonts, OFL); KFGQPC Uthmanic Hafs and IndoPak Nastaleeq (bundle these with the app).
- There are no images. The app icon is still to be designed.

## Files
- `design/Mushaf Night.dc.html`: all Night screens, dark and light. Theme tokens are in the `themes` array in its script.
- `design/MushafPage.dc.html`: the page renderer. Variants `d` (dark) and `e` + `tone="day"` (light) are the Night pages; the other variants are rejected directions and can be ignored.
- `design/support.js`: runtime needed to open the HTML files in a browser. It is not part of the design.
- `screenshots/dark.png`, `screenshots/light.png`: full boards.
- `DESIGN_BRIEF.md`: the original product brief.
