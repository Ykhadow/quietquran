<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/brand/mark_night.svg">
    <img src="assets/brand/mark_day.svg" alt="Quiet Quran logo" width="96">
  </picture>
</p>

<h1 align="center">Quiet Quran</h1>

<p align="center">
  <a href="https://quietquran.com">quietquran.com</a> ·
  <a href="https://github.com/Ykhadow/quietquran/releases/latest">Download</a>
</p>

A calm Quran reader for IndoPak and Madani readers. Each Mushaf is shown in its own line layout, page for page, as it is printed. It is free, with no ads and no tracking, and it always will be: it is made as sadaqah jariyah.

Built with Flutter for Android, iOS, Windows, macOS and Linux. Website: [quietquran.com](https://quietquran.com).

## What it does

- **Text pages** (bundled, fully offline) draw each edition line for line in its own layout:

  | Edition | Lines | Pages |
  |---|---|---|
  | IndoPak Qudratullah | 15 | 610 |
  | IndoPak Taj Company | 16 | 548 |
  | IndoPak Qudratullah | 13 | 849 |
  | IndoPak Taj Company | 13 | 847 |
  | IndoPak Gaba (large print) | 9 | 1890 |
  | Madani 1405H (KFGQPC V1) | 15 | 604 |
  | Madani 1421H (KFGQPC V2) | 15 | 604 |

  Lines are justified, or centred where the print centres them. **Easy read** (called reflow in the code) flows the same text at any size, framed like the page with its running head, surah headers and page number.
- **Printed pages:** the King Fahd Complex's own Mushaf pages, extracted unchanged from the Complex's PDFs and served exactly as extracted from pages.quietquran.com. They are fetched as you read and can be saved for offline reading.

  | Set | Follows layout | Source |
  |---|---|---|
  | IndoPak 15-line, King Fahd Complex | Qudratullah 15 | The Complex's IndoPak Mushaf PDF (`tool/kfgqpc_indopak15.py`) |
  | Madani 15-line, King Fahd Complex | Madani 1405H, page for page | The Complex's Mumtaz Mushaf PDF (`tool/kfgqpc_madani.py`) |

  Each set's address is in `lib/data/image_editions.dart`.
- **Recitation**, ayah by ayah, with the translation read after each ayah if you like.
- **Translations** of the meanings in English and Urdu, under each ayah or for the ayah you hold.
- **Sessions:** your daily reading, plus separate places for other readings (Al-Kahf on Fridays, Al-Mulk at night), with optional reminders. Bookmarks with notes. Export and import from Settings.
- **Your place is kept by ayah**, so changing edition, script or reading style never loses it.
- Pages turn right to left, wide windows show two pages side by side, and the keyboard works (`←` `→` `PgUp` `PgDn` `Space` `Home` `End`).
- **Languages:** the app's own words are in English, Urdu or Arabic (`lib/l10n/app_*.arb`). The Urdu and Arabic still need review by native speakers.

## Sources

The Quran text, layouts and metadata come from **QUL** (qul.tarteel.ai), a proofread source. Every source is listed file by file in **[SOURCES.md](SOURCES.md)**, with its credit and terms, and the database's `sources` table records the same list. Nothing from a source is altered.

## How it was made

The Quran text and page images are never generated or changed: they come from proofread sources (QUL and the King Fahd Complex) and are used exactly as published, checked against their sources by the tests and tools in this repository. The app's code was written with the help of an AI assistant (Claude), and reviewed and tested by the developer.

## Building

```bash
flutter pub get
flutter run -d windows        # or an Android device, macos, linux
flutter build appbundle       # Play Store (signing: see below)
flutter build apk --release --split-per-abi
```

iOS and macOS builds need a Mac.

### The IndoPak font

The default IndoPak typeface is **"AlQuran IndoPak by QuranWBW"** by Ayman Siddiqui, QuranWBW ([quranwbw.com](https://quranwbw.com)), based on the Al Qalam Quran Majeed fonts. It is included, unmodified, as `assets/fonts/IndoPakNastaleeq.ttf`, used with QuranWBW's written permission (`docs/permissions/quranwbw-font.md`).

**It is not covered by this project's GPL licence.** Its terms are in [`assets/fonts/IndoPakNastaleeq-LICENSE.md`](assets/fonts/IndoPakNastaleeq-LICENSE.md): free, sadaqah jariyah projects only, with no ads, nothing behind a paywall and no commercial use; unmodified; everyone credited; digital use only. The permission was given to Quiet Quran, so a fork or any other project that uses the font needs its own permission from QuranWBW.

### Signing

Release builds are signed with the key in `android/upload-keystore.jks`, whose password is in `android/key.properties`. Neither is in the repository. Without them, release builds use the debug key.

### Releasing

1. Set `version:` in `pubspec.yaml`, commit, and push a tag: `git tag v1.2.3 && git push origin v1.2.3`.
2. `.github/workflows/release.yml` builds Windows and Linux and puts them on a draft GitHub Release, after checking that the IndoPak font is exactly the permitted file.
3. Build the Android APKs locally (`flutter build apk --release --split-per-abi`), name them `QuietQuran-android-arm64.apk` and `QuietQuran-android-arm32.apk`, add them and a `SHA256SUMS` file to the draft, and publish it. The website's download buttons always point at the latest release.

## Tests

```bash
flutter analyze
flutter test
```

The checks on GitHub (`.github/workflows/checks.yml`) run the analyzer and every test on Windows, where the golden images were drawn. Tests that need the IndoPak font itself are tagged `indopak-font`, so they can be left out (`--exclude-tags indopak-font`) if the font is ever replaced by a stand-in.

- `test/word_order_test.dart` measures right-to-left word order on rendered pages. Never judge it from a screenshot.
- After font or layout changes, `INK_AUDIT=1 flutter test test/ink_bounds_test.dart` checks that no word's ink leaves its line.
- To look at rendered pages: `flutter test --update-goldens`, then `test/goldens/*.png`.

## Data

`assets/db/quran.db` is generated by `tool/build_quran_db.py` from QUL downloads in `tool/qul/` (a free login is needed; not committed): the layout SQLite files, `scripts/` (word-by-word text; every script shares word ids 1–83668), `metadata/` and `fonts/`.

```bash
python tool/build_quran_db.py
```

If you change the schema, bump `QuranDb._schemaVersion` so existing installs copy the new file.

The printed page sets are made by `tool/kfgqpc_indopak15.py` and `tool/kfgqpc_madani.py`, which check each PDF against its recorded fingerprint and save the pages untouched to `hosting/` (not committed) for upload.

## Code layout

```
lib/
  core/       settings (persisted choices), theme, formatting
  data/       QuranDb (bundled SQLite), page images, library (sessions,
              bookmarks), recitation, reminders
  features/
    onboarding/  script and reading-mode choice
    home/        sessions, surah / juz lists, bookmarks
    reader/      Mushaf text page, Easy read, printed page, reader screen
    audio/       recitation player
    settings/
  widgets/    shared building blocks of the design system
  l10n/       English, Urdu and Arabic strings
tool/         database and page-set builders
website/      quietquran.com
```

The design system ("Night", with a Day mode) is described in `design_handoff_mushaf_night/`. Its colour and type roles are in `lib/core/theme.dart` and its components in `lib/widgets/night.dart`.

## Website

`website/` is quietquran.com: plain HTML and CSS, a little JavaScript for the theme switch and the layout switcher, and nothing loaded from other servers. It is deployed as a Cloudflare Pages project with `website` as the output folder and no build step. Its screenshots are drawn from the app itself: `SITE_SHOTS=website/img flutter test test/site_screenshots_test.dart`.

## Licence

The code is licensed under the **GNU General Public License v3.0** ([LICENSE](LICENSE)). Anyone may use, study, change and share it, and anything built from it must stay open under the same licence.

The licence covers this project's own code. The Quran text, fonts (including the IndoPak font, see above), translations, recitations and page images keep their own terms, listed in [SOURCES.md](SOURCES.md).
