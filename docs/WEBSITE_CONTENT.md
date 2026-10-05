# Quiet Quran website: what it needs to include

This lists what the website for Quiet Quran has to contain. How it looks and how it is organised is left entirely to the designer.

## The app in one line

Quiet Quran is a free, calm Quran reader for IndoPak and Madani readers. It shows each printed Mushaf line for line as it was printed. It has no ads, no purchases, no accounts and no tracking.

## Who it is for

- Readers of the **IndoPak** (Nastaliq) script, the script of South Asia's printed Mushafs.
- Readers of the **Madani** (Uthmani) script, the King Fahd Complex's Mushaf.
- People who want to read without distractions, including those memorising (hifz) and those who need larger text.

## Platforms

- Android
- iOS (iPhone and iPad)
- Windows
- macOS
- Linux (a download from the website; a Flathub listing will follow)

Each platform needs a place to get the app. The store links aren't available yet.

## Principles

- **Free forever.** No ads, no in-app purchases, no subscriptions. The app is not sold and earns nothing.
- **No account needed.** Nothing to sign up for.
- **Private.** No tracking and no analytics. Reading positions, sessions, bookmarks and settings stay on the device.
- **Faithful.** The Quran text is never altered. Every page layout, font and text comes from a proofread, credited source.
- **Open source.** The code is public. The repository link will follow.
- **Made to run on modest phones,** with the whole text built in and nothing to set up.

## Features

### Reading
- **Three ways to read:**
  - **Easy read:** the Quran text at any size, flowing to fit the screen, still framed as a page with the surah, juz and page number, and each surah opening with its Mushaf header. This is the default.
  - **Mushaf:** each page line for line, exactly as the printed Mushaf lays it out.
  - **Printed pages:** images of real printed Mushaf pages.
- **Printed Mushaf layouts built in** (text, fully offline):
  - IndoPak: 15-line (610 pages), 16-line Taj Company (548 pages), 13-line Qudratullah (849 pages), 13-line Taj Company (847 pages), 9-line Gaba large print (1,890 pages).
  - Madani: 1405H (604 pages) and 1421H (604 pages), from the King Fahd Complex's fonts.
- **Printed page sets:**
  - The King Fahd Complex's IndoPak 15-line Mushaf, taken from the Complex's own files.
  - The King Fahd Complex's Madinah Mushaf (Mumtaz print, 604 pages), taken from the Complex's own files.
- **Your place is kept by ayah,** so changing layout, script or reading style never loses it.
- **Pinch to zoom** on Mushaf and printed pages.
- **Two pages side by side** like an open book on tablets and desktops, which can be turned off.
- **Pages turn right to left.** Keyboard page turning on desktop.
- **Printed pages download once** to be read offline. They can also load page by page.

### Translation
- **Translations of the meanings** in English and Urdu, shown under each ayah or opened for a single ayah.
- **Long-press any ayah** to see its translation and actions, in every reading style.
- The Quran text itself is never translated or replaced.

### Recitation
- **Listen ayah by ayah** from nineteen renowned reciters (Mishary Alafasy by default; Abdul Basit, Al-Husary, Al-Minshawi, As-Sudais, Maher Al-Muaiqly and more), each heard exactly as they recorded.
- **The page follows along:** the ayah being recited is highlighted, and pages turn with the recitation.
- **Translation read aloud** after each ayah, if wanted, in English or Urdu.
- **Repeat each ayah** any number of times, for memorising.
- **Keeps playing with the screen off,** with controls on the lock screen and in notifications.
- Ayahs already heard are kept on the phone, so they play again without a connection.

### Sessions and bookmarks
- **Reading sessions:** keep several readings going at once, such as a daily reading, a surah being memorised, or a khatm. Each resumes where it was left, or restarts at the start of its surah.
- **Reading reminders** (Android and iOS): per session, at a chosen time, every day or on chosen days. Tapping one opens that session.
- **Bookmarks** with notes. Bookmarked ayahs are softly highlighted as you read.
- **Save your places to a file,** and open it on any device, to keep a copy or move to a new phone or computer. No account needed.

### Finding your way
- Browse by **surah** or **juz**, and search surah names in English, Arabic, Urdu or transliteration.
- A **scrubber** to move quickly through the Mushaf by page, surah or juz.

### Look and comfort
- **Themes:** Night, Day, Sepia, Green and High contrast, following the device's light or dark mode if wanted.
- **Custom colours**, with a live preview and a readability check.
- Printed pages can **follow the theme** (e.g. dimmed at night) or keep their original look.
- **Adjustable text size**, chosen during setup and changeable anytime.

### Languages
- The app itself is in **English, Urdu and Arabic**, with right-to-left layout for Urdu and Arabic.

### Getting started
- A short **first-run setup:** language, script, reading style, Mushaf layout, text size and translation. Everything can be changed later.

### Coming later
- **Offline recitation downloads:** a surah, or a reciter's whole recitation, kept on the device.

## Sources and credits

The site needs a sources and credits section. The app has the same list on its Sources page, and `SOURCES.md` in the repository has every detail.

- **Quran text, page layouts and metadata:** the Quranic Universal Library (QUL, qul.tarteel.ai), a proofread source.
- **Quran fonts:** the King Fahd Glorious Quran Printing Complex (KFGQPC) and the other fonts credited on the Sources page.
- **IndoPak 15-line printed pages:** the King Fahd Glorious Quran Printing Complex, Madinah.
- **Madani printed pages:** the King Fahd Complex's own Mumtaz Mushaf pages, served unchanged from pages.quietquran.com.
- **Translations:** Saheeh International (English), and Fateh Muhammad Jalandhari (Urdu).
- **Recitations:** each reciter's own recordings, ayah by ayah, from EveryAyah (everyayah.com).
- **App fonts:** Newsreader, Source Sans 3, Amiri, Noto Naskh Arabic and Noto Nastaliq Urdu (SIL Open Font License).

## Pages and information the site must have

- **Downloads** for every platform listed above.
- **Privacy policy.** Both app stores require one. In short: the app collects nothing, has no accounts or analytics, keeps everything on the device, and Android may back up settings through the user's own Google backup. Reminders are local notifications. Printed pages are downloaded from our hosting, and those requests carry nothing about the reader.
- **Sources and credits** (above).
- **Contact:** support@quietquran.com, for feedback, corrections and permissions.
- A way to **report a mistake** in text or layout, taken seriously for a Quran app.
- **Open source:** a link to the code repository, once public.

## Brand assets

- **Name:** Quiet Quran.
- **Domain:** quietquran.com.
- **Logo:** a closed Mushaf in three-quarter view, with an almond medallion on its cover. It comes in a Night (dark) and a Day (light) version. The source is `design/logo/make_logos.py`.
- **App palettes:**
  - Night: background `#151614`, text `#E4DDD0`, accent `#D98E70`
  - Day: background `#F4F0E8`, text `#211F1B`, accent `#A9532F`
- **App fonts:** Newsreader and Source Sans 3 (Latin), Noto Naskh Arabic and Noto Nastaliq Urdu (Arabic and Urdu).
- **Screenshots** of the app can be supplied.
