# Design brief: Mushaf (working title)

A free, open-source Quran reader. It is non-commercial, with no ads, no tracking and no accounts. It serves readers who want a Mushaf that looks like the one they learned from, especially IndoPak readers from South Asia and its diaspora, who find few clean options today. It is built in Flutter for Android and iOS first, with tablet and desktop (Windows, macOS, Linux) support.

This brief asks for a visual and interaction design. The current build is functional and uses stock Material 3 with a teal accent. Treat it as a reference for structure only, not for style.

---

## 1. The one principle

**The Quran is the interface. Everything else stays out of the way.**

- Reading is where the user spends 95% of their time. In that mode the screen should show the page and nothing else until the user asks for something.
- Every choice about script, edition and display is made **once**, during first-run setup. After that it lives quietly in Settings. Nothing in the reader nudges, badges, pops up or asks for attention.
- The mood is calm and reverent: modern, but not flashy, gamified or "social". Think of a well-printed book, not a feed.

Avoid: streaks, badges, notifications prompts, rating prompts, banners, carousels, promotional cards, confetti, mascots, and heavy gradients or glassmorphism.

---

## 2. Users

| Who | Needs |
|---|---|
| **Daily reader** (the main user) | Opens the app, continues where they left off, reads a few pages. Wants zero friction. |
| **Hifz student / hafiz** | Must see the *exact* page layout of their printed Mushaf (same lines, same page breaks), because memory is visual. Often reads in printed-page image mode. |
| **Older reader or weak eyesight** | Large text, high contrast, big touch targets. Uses the "reflow" text view at large sizes. |
| **Desktop or tablet user** | Reads two pages side by side like an open book. Uses the keyboard to turn pages. |

The audience is multilingual. The UI is in English for now, and the Quran text is Arabic, which reads right to left. Design so that Urdu and Arabic UI translations could come later.

---

## 3. What the user chooses (first run, then Settings)

The app supports several editions. Each edition keeps its own native page layout, so line counts and page counts differ.

**Script and edition (text layouts):**

| Script | Edition | Lines per page | Pages |
|---|---|---|---|
| IndoPak | Qudratullah 15-line (hifz edition) | 15 | 610 |
| IndoPak | Taj Company 16-line | 16 | 548 |
| IndoPak | Qudratullah 13-line | 13 | 849 |
| IndoPak | Taj Company 13-line | 13 | 847 |
| Madani (Uthmani) | Madinah 1405H (KFGQPC V1) | 15 | 604 |
| Madani (Uthmani) | Madinah 1421H (KFGQPC V2) | 15 | 604 |

**Reading mode:**

- **Text.** The page is drawn live from text and fonts, so it is crisp at any size. The user can:
  - switch between **Mushaf page** (the exact printed lines) and **Reflow** (the same page's text at any font size, scrolling)
  - adjust text size in Reflow
  - use light/dark themes and **custom colour palettes** (see §6).
- **Printed pages.** Downloaded page images of a real print. They look exactly like the physical Mushaf and can be pinch-zoomed. They are downloaded per edition (about 100–300 MB) or fetched page by page as the user reads. Custom palettes do **not** apply to images; dark mode only dims them.
  - Page editions include plain black-and-white prints (the default) and optional colour-coded tajweed prints.

**Other settings:** theme (System / Light / Dark / custom palette), text size, the page-image downloads manager, and an About screen with credits.

---

## 4. Screens to design

Please design each screen on **phone (portrait)** first, then show how it adapts to **tablet** (portrait and landscape) and **desktop** (resizable window).

### 4.1 First-run setup (3–4 short steps)
1. **Welcome.** One sentence about what the app is: free, no ads, no tracking. One button.
2. **Choose your script.** Two large choices, IndoPak and Madani. Each shows a **live sample of real Quranic text in that script** (for example Al-Fatihah verses 2–4), a one-line description of who typically reads it, and 2–3 short benefit points.
3. **Choose your edition.** A list of editions for the chosen script, each showing its line count and page count. A small page thumbnail or a "lines per page" visual would help users recognise their Mushaf.
4. **Choose how to read.** Two choices, **Text** and **Printed pages**, each with benefit bullets:
   - Text: adjustable size, themes and palettes, fully offline, tiny download.
   - Printed pages: looks exactly like your Mushaf, keeps the visual memory hifz relies on, pinch to zoom, needs a download.
   - If the user picks Printed pages, show the download size and let them choose **Download now** or **Download as I read**.

Every step says "You can change this later in Settings." A progress indicator and a Back action are needed. It must work one-handed on a phone.

### 4.2 Home (library)
- The main element is **Continue reading**: surah name, page number and edition, one tap to resume.
- Navigation into the Quran:
  - **Surahs** (114): number, English name, meaning, verse count, Meccan/Medinan, starting page, and the Arabic name.
  - **Juz** (30): number, starting surah and ayah, starting page.
  - **Go to page** (numeric input).
- Settings entry point.
- Room for **Bookmarks** later (designing an empty state now would help). **Search** comes later too.
- Keep it quiet: no hero images and no daily-verse cards unless they can be switched off and are very restrained.

### 4.3 Reader (the most important screen)
- **Immersive by default.** The page fills the screen. A single tap reveals a minimal overlay; another tap, or a few seconds of inactivity, hides it.
- **The overlay contains:**
  - Back to home.
  - Current surah name(s), juz, and page "N of total".
  - Quick toggles: Mushaf page ↔ Reflow (text mode only), text size (reflow only), and **Text ↔ Printed pages**, but only if that edition has both.
  - Settings shortcut.
  - A **page scrubber**: drag to jump through pages, with a surah/juz preview while dragging.
- **Page turning** runs right to left, like a Mushaf: swipe to the right for the next page. On desktop, the ← → arrows, PgUp/PgDn, Space, Home and End keys work.
- **Two-page spread** on landscape tablets and desktop. The odd page sits on the right and the even page on the left, like an open book, with a subtle spine or gutter.
- **Mushaf page (text) rendering:**
  - Fixed lines, each justified to the full page width.
  - Surah header bands with the Arabic surah name, verse count and Meccan/Medinan label.
  - A bismillah line under each header.
  - Ornamented ayah-end markers containing the verse number.
  - Please design the **surah header band**, **ayah marker**, **page frame or border**, and page-edge/margin treatment. These are the few decorative elements the app has.
- **Reflow rendering:** justified Arabic paragraphs at the user's size, with the same surah header and bismillah treatment. It scrolls vertically within a page, and pages still turn horizontally.
- **Printed-page rendering:** the image on a neutral ground, zoomable, with states for **loading**, **not downloaded / offline** (with a retry) and **download failed**.
- Later, **long-press on an ayah** could offer actions (bookmark, copy, share). Please sketch a restrained ayah-selection highlight and action sheet.

### 4.4 Settings
Grouped, calm and scannable:
- **Mushaf:** script, edition, reading mode.
- **Display:**
  - theme (System / Light / Dark / Custom)
  - palette picker and editor (§6)
  - reflow text size, with a live preview line of Quranic text
- **Downloads:** each printed-page edition with its size, progress (0–N pages), pause/resume and delete.
- **About:** mission (free, no ads, no tracking, open source), credits for data, fonts and page sources, and a link to the source code.

### 4.5 Download manager states
Not downloaded, downloading (progress, pause), paused, complete, error (retry), and a storage-space warning.

---

## 5. Layout and breakpoints

| Class | Width | Behaviour |
|---|---|---|
| Phone | < 600 dp | Single page. Bottom-anchored controls within thumb reach. |
| Tablet portrait | 600–900 dp | Single page, larger margins. Lists can use two columns. |
| Tablet landscape / desktop | ≥ 600 dp and landscape | **Two-page spread.** On Home, a list-and-detail layout or navigation rail, not a stretched phone layout. |
| Large desktop | > 1200 dp | Page(s) keep their print proportions, centred. Chrome stays minimal. |

- Respect safe areas and notches.
- In the reader, the page should use as much of the screen as possible while keeping print proportions (about 0.64 width/height per page).

---

## 6. Theming and custom palettes

There are **light** and **dark** modes, plus **user palettes** for text mode.

- **A palette is a small set of named colours:**
  - page background
  - text (ink)
  - ayah markers
  - surah header fill
  - header text
  - frame/border accent
  - UI accent
- **Include 4–6 presets**, for example:
  - Paper (warm off-white)
  - Night (dark, low-contrast ink, never pure white on pure black)
  - Sepia
  - Green
  - High contrast
- **A palette editor** lets the user adjust those colours, with a **live preview of a Mushaf line** and a contrast warning if the ink and background contrast is too low.
- **Palettes apply only to text rendering and app chrome.** Printed page images keep their own colours; they can only be dimmed in dark mode. The design should make that distinction clear without cluttering the UI.

Please deliver the design as **tokens** (colour roles, type scale, spacing, radii, elevation) so they map cleanly onto a Flutter theme.

---

## 7. Typography

- **Quranic text** uses fixed fonts that the design must not replace: *IndoPak Nastaleeq* for IndoPak and *KFGQPC Uthmanic Hafs* for Madani. Use real Arabic sample text in mock-ups; the Quran.com IndoPak and Uthmani fonts are fine for mock-ups.
- **UI font:** your choice. It should be highly legible, neutral and humanist, and pair well with Arabic. If possible, suggest a companion Arabic/Urdu UI face for future localisation.
- Arabic text is always right to left. Numbers inside Arabic use Arabic-Indic digits (IndoPak uses the Urdu forms ۱۲۳).

---

## 8. Accessibility

- Touch targets are at least 48 dp.
- Text contrast is at least WCAG AA in all presets; custom palettes show a warning instead of blocking.
- The UI respects the system font scale; reflow has its own size control.
- Screen-reader labels are needed for all controls.
- Every reader action must be reachable by keyboard on desktop.
- Reduced-motion setting: no page-curl animation needed. A simple slide or crossfade is preferred.

---

## 9. What we'd like back

1. The first-run setup flow (phone), all steps.
2. Home (phone and tablet/desktop).
3. The reader in its various states:
   - immersive
   - overlay shown
   - scrubber in use
   - two-page spread
   - reflow
   - printed page with loading and offline states
4. Settings, including the palette editor and the downloads manager.
5. Components:
   - surah header band
   - ayah-end marker
   - page frame
   - list rows
   - choice cards
   - download row
6. Design tokens for light, dark and 4–6 palette presets.
7. An app icon concept: simple and calligraphic or geometric, not a photo of a book.

Short notes explaining the reasoning behind key choices are welcome.

---

## 10. Reference: what exists today

- Onboarding with script choice (live font samples) and reading-mode choice.
- Home with Continue reading and Surah/Juz tabs.
- Reader:
  - Mushaf text pages with justified lines
  - reflow
  - printed pages (downloaded on demand)
  - two-page spread
  - keyboard navigation
  - tap to hide the chrome
- Settings with segmented controls and a downloads list.

It works well; this exercise is to explore a more refined visual direction.
