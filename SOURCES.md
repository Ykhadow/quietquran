# Sources

Every piece of Quranic content in this app comes from a named, proofread source. The build script (`tool/build_quran_db.py`) records the same list in the `sources` table of `assets/db/quran.db`.

## Quran text, layouts and metadata: QUL

All Quran text, all Mushaf layouts and all Quran metadata come from **QUL, the Quranic Universal Library** by Tarteel AI: https://qul.tarteel.ai. QUL publishes proofread data. The files are downloaded by hand (a free login is needed) into `tool/qul/`, which is not committed.

### Word-by-word Quran text

| Database column | QUL resource | Used for |
|---|---|---|
| `words.indopak` | [Indopak Nastaleeq – Word by Word (quran-script/59)](https://qul.tarteel.ai/resources/quran-script/59) | IndoPak Nastaleeq typeface |
| `words.qpc_nastaleeq` | [QPC Nastaleeq – Word by Word (quran-script/52)](https://qul.tarteel.ai/resources/quran-script/52) | KFGQPC Nastaleeq typeface |
| `words.madani` | [KFGQPC Hafs – Word by word (quran-script/312)](https://qul.tarteel.ai/resources/quran-script/312) | Madani (Uthmani) text |

The text is used exactly as published, with one exception: whitespace at the start or end of a word is trimmed. In practice this affects a single word, 6:1:1 in QPC Nastaleeq, which ends in two non-breaking spaces.

### Mushaf layouts

| Edition | QUL resource |
|---|---|
| IndoPak 15-line, Qudratullah | [mushaf-layout/12](https://qul.tarteel.ai/resources/mushaf-layout/12) |
| IndoPak 16-line, Taj Company | [mushaf-layout/11](https://qul.tarteel.ai/resources/mushaf-layout/11) |
| IndoPak 13-line, Qudratullah | [mushaf-layout/236](https://qul.tarteel.ai/resources/mushaf-layout/236) |
| IndoPak 13-line, Taj Company | [mushaf-layout/313](https://qul.tarteel.ai/resources/mushaf-layout/313) |
| IndoPak 9-line, Gaba | [mushaf-layout/571](https://qul.tarteel.ai/resources/mushaf-layout/571) |
| Madani 1405H (KFGQPC V1) | [mushaf-layout/15](https://qul.tarteel.ai/resources/mushaf-layout/15) |
| Madani 1421H (KFGQPC V2) | [mushaf-layout/10](https://qul.tarteel.ai/resources/mushaf-layout/10) |

### Metadata

| Data | QUL resource |
|---|---|
| Surah names (Arabic and transliterated), revelation place, verse counts | [quran-metadata/70](https://qul.tarteel.ai/resources/quran-metadata/70) |
| Ayah list | [quran-metadata/69](https://qul.tarteel.ai/resources/quran-metadata/69) |
| Juz | [quran-metadata/68](https://qul.tarteel.ai/resources/quran-metadata/68) |
| Hizb | [quran-metadata/67](https://qul.tarteel.ai/resources/quran-metadata/67) |
| Rub al-hizb | [quran-metadata/63](https://qul.tarteel.ai/resources/quran-metadata/63) |
| Manzil | [quran-metadata/66](https://qul.tarteel.ai/resources/quran-metadata/66) |
| Ruku | [quran-metadata/65](https://qul.tarteel.ai/resources/quran-metadata/65) |
| Sajdah (15 places, including 22:77) | [quran-metadata/64](https://qul.tarteel.ai/resources/quran-metadata/64) |

### Fonts (`assets/fonts/`)

| File | QUL resource |
|---|---|
| `IndoPakNastaleeq.ttf` | [font/242, Indopak Nastaleeq](https://qul.tarteel.ai/resources/font/242): "AlQuran IndoPak by QuranWBW" v2.100 by Ayman Siddiqui ([quranwbw.com](https://quranwbw.com)), based on the Al Qalam Quran Majeed fonts. © Al Qalam © Ghandhara © KFGQPC © Ayman Siddiqui. Credits: Abdul Majeed Khan, Arif Karim, Shakir-ul-Qadree, Jawad. **Used with written permission from QuranWBW (October 2026)**, on their terms: the app stays free (sadaqah jariyah), with no ads and nothing behind a paywall; the font and its matching IndoPak text are used unmodified; everyone above is credited; digital use only, no printing or commercial use. See `docs/permissions/quranwbw-font.md`. |
| `KFGQPCNastaleeq.ttf` | [font/462, KFGQPC Nastaleeq](https://qul.tarteel.ai/resources/font/462) |
| `UthmanicHafs.ttf` | [font/245, QPC Hafs (UthmanicHafs V22)](https://qul.tarteel.ai/resources/font/245) |
| `SurahNameV2.ttf` | [font/455, Surah name font v2](https://qul.tarteel.ai/resources/font/455): surah titles in the headers (the text `surahNNN` draws surah NNN's name) |

### Translations of the meanings

Shown with the Arabic text (when an ayah is held, and under each ayah in Reflow), never instead of it. Each is used exactly as QUL publishes it, without footnotes. The build checks that every translation covers exactly the app's 6,236 ayahs.

| Translation | Language | QUL resource | Rights |
|---|---|---|---|
| Saheeh International | English | [translation/193](https://qul.tarteel.ai/resources/translation/193) | © Dar Abul-Qasim / Al-Muntada Al-Islami. Used non-commercially with credit; **confirm the publisher's permission before any public release.** |
| Fateh Muhammad Jalandhari | Urdu | [translation/218](https://qul.tarteel.ai/resources/translation/218) | Translator died 1940; believed to be in the public domain. |

## Recitation audio

Streamed from [EveryAyah](https://everyayah.com), one file per ayah, exactly as each reciter recorded it and EveryAyah publishes it: nothing is cut, joined or altered. Each ayah is saved on the device as it streams (`<app support>/audio/<folder>/<sssaaa>.mp3`), so it plays again without a connection. The Bismillah heard before a surah (all but Al-Fatihah and At-Tawbah) is the reciter's own Al-Fatihah 1:1. The reciters and folders are listed in `lib/data/recitation.dart`. All are served from `https://everyayah.com/data/<folder>/`, and each was checked to have 1:1, 2:255 and 114:6.

EveryAyah shares its recordings for non-commercial use with credit. Quiet Quran is free with no ads, and credits EveryAyah and every reciter on its Sources page.

| Reciter | EveryAyah folder |
|---|---|
| Mishary Rashid Alafasy (default) | `Alafasy_128kbps` |
| Abdul Basit Abdus Samad (Murattal) | `Abdul_Basit_Murattal_192kbps` |
| Abdul Basit Abdus Samad (Mujawwad) | `Abdul_Basit_Mujawwad_128kbps` |
| Mahmoud Khalil Al-Husary | `Husary_128kbps` |
| Al-Husary (teaching) | `Husary_Muallim_128kbps` |
| Muhammad Siddiq Al-Minshawi | `Minshawy_Murattal_128kbps` |
| Abdur-Rahman As-Sudais | `Abdurrahmaan_As-Sudais_192kbps` |
| Saud Ash-Shuraim | `Saood_ash-Shuraym_128kbps` |
| Maher Al-Muaiqly | `MaherAlMuaiqly128kbps` |
| Saad Al-Ghamdi | `Ghamadi_40kbps` |
| Abu Bakr Ash-Shaatree | `Abu_Bakr_Ash-Shaatree_128kbps` |
| Ali Al-Hudhaify | `Hudhaify_128kbps` |
| Muhammad Ayyoub | `Muhammad_Ayyoub_128kbps` |
| Yasser Ad-Dossary | `Yasser_Ad-Dussary_128kbps` |
| Nasser Al-Qatami | `Nasser_Alqatami_128kbps` |
| Hani Ar-Rifai | `Hani_Rifai_192kbps` |
| Muhammad Jibreel | `Muhammad_Jibreel_128kbps` |
| Abdullah Basfar | `Abdullah_Basfar_192kbps` |
| Ahmed Al-Ajamy | `Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net` |

### Translations, read aloud

Optional: after each ayah, its translation is read, in the translation the app shows.

| Voice | Reads | EveryAyah folder | Rights |
|---|---|---|---|
| Ibrahim Walk | Saheeh International (English) | `English/Sahih_Intnl_Ibrahim_Walk_192kbps` | The recording is EveryAyah's; the text is © Dar Abul-Qasim / Al-Muntada Al-Islami (see above). |
| Shamshad Ali Khan | Fateh Muhammad Jalandhari (Urdu) | `translations/urdu_shamshad_ali_khan_46kbps` | Reads Jalandhari's translation, the text the app shows (confirmed by ear). |

## Not from QUL

None of the following is Quran text.

| What | Source | Why |
|---|---|---|
| English meanings of surah names ("The Opener") | Quran.com API v4, `/chapters?language=en` | QUL's surah metadata has no English meanings. Shown only in the surah list. |
| The labels "سُورَةُ", "آياتها", "مكية" and "مدنية" in surah headers | Written in the app code | Header decoration |
| Ayah markers for the KFGQPC Nastaleeq typeface | Drawn by the app: the font's own U+06DD ornament with the ayah's digits from QUL on top | The QPC Nastaleeq text ends each ayah with bare digits |

## Printed page images

These are scans or renders of physical Mushaf prints, so their accuracy rests on the printed edition. They are loaded from third-party hosts for now; each set is defined in `lib/data/image_editions.dart`.

| Set | Host |
|---|---|
| IndoPak 15-line, King Fahd Complex | The King Fahd Glorious Quran Printing Complex's own Mushaf PDF (`qurancomplex.gov.sa/wp-content/uploads/isdarat/hafs/nastaleeq.pdf`, via the Internet Archive; see below). With thanks to Lucid ([github.com/1uc1d23](https://github.com/1uc1d23/IndoPak-15-Line-Naskh-Mushaf-Page-Images)), whose page collection led us to it. Served unchanged from `pages.quietquran.com/indopak-15-kfgqpc/`. |
| IndoPak 16-line, Taj Company | GitHub `legeRise/quran-indopak-ayah-coordinates` |
| IndoPak 13-line, Qudratullah | archive.org `AlQuran13LinesQudratUllahCompany` |
| IndoPak 15-line colour-coded | archive.org `quran_202301` |
| Madani 15-line, King Fahd Complex | The Complex's own Mushaf PDF of its Mumtaz print (`qurancomplex.gov.sa/wp-content/uploads/isdarat/hafs/mumtaz.pdf`, via the Internet Archive; see below). Served unchanged from `pages.quietquran.com/madani-15-kfgqpc/`. |

### The King Fahd Complex IndoPak 15-line pages

The Complex published this Mushaf as `isdarat/hafs/nastaleeq.pdf` on qurancomplex.gov.sa, which can't be reached from outside Saudi Arabia. The Internet Archive keeps the file exactly as published (snapshot of 26 January 2025, SHA-1 in base 32 `YXOJYSGFSJGO7VH3NRYRIXMIEZZNRCSK`). It was made on 20 January 2020 with Esko prepress software and holds 624 pages, one lossless image each; PDF page N+5 is page N of the app's layout.

`tool/kfgqpc_indopak15.py extract` checks the file against that SHA-1 and saves the 610 Quran pages untouched (no resizing or colour changes) to `hosting/indopak-15-kfgqpc/`. `tool/kfgqpc_indopak15.py mapping` matches every mark on every page against Quran for Android's independent copy of the same page and of the pages either side. Checked on 30 September 2026: every page matches its own page best (typically 4% of marks unmatched, against 45–65% for a neighbouring page). Pages 1 and 2, whose ornate frames differ between the copies, and the seven closest calls (68, 69, 274, 316, 329, 330, 342) were also compared by eye: same text, same lines, same printed page number.

### The King Fahd Complex Madani 15-line pages

The Complex published its Mumtaz print as `isdarat/hafs/mumtaz.pdf`. The Internet Archive keeps the file exactly as published (snapshot of 16 August 2024, 359,883,829 bytes, SHA-1 in base 32 `T7RNGUE4TCV257RPYQROJCTDZAPVETYB`). It holds 640 pages, one lossless image each (1816 × 2609); PDF page N+3 is page N of the 604-page Madani layout.

This is the Complex's revised print (1421H on), not the 1405H one: every page begins and ends at the same ayah as the 1405H layout, but some lines break at different words (page 318, line 2, for example). The pages are served as their own set, following the 1405H layout's page numbering.

`tool/kfgqpc_madani.py extract` checks the file against that SHA-1 and saves the 604 Quran pages untouched to `hosting/madani-15-kfgqpc/`. Checked on 4 October 2026: the Complex's own table of contents for these PDFs puts all 114 surah openings at PDF page N+3; pages 1, 50, 293 and 604 were compared by eye (Al-Fatihah, Al-Imran, Al-Kahf and the last three surahs); and `tool/kfgqpc_madani.py numbers` showed the printed page number of every 13th page, and of pages 603 and 604, matching its file number. The uploaded files were compared with the extracted ones byte for byte.

The Complex's usage-rights statement for its digital Mushaf al-Madinah (dm.qurancomplex.gov.sa) allows free use in websites and computer software.

### Bundled preview crops (`assets/samples/`)

The first-run "How would you like to read?" step shows the top of page 562 (Surah Al-Mulk) from each script's default printed set, so the preview works offline. The crops are the top 36% of these pages, flattened onto white, converted to greyscale and resized to 800 px wide:

| File | Cut from |
|---|---|
| `printed_indopak.webp` | IndoPak 15-line, King Fahd Complex, page 562 (PDF page 567), cropped to the page frame at 800 × 460 |
| `printed_madani.webp` | Madani 15-line, King Fahd Complex, page 562 (PDF page 565), the whole page resized to 700 × 1006 |

## App fonts

Newsreader, Source Sans 3, Amiri, Noto Naskh Arabic and Noto Nastaliq Urdu (for Urdu translations), from Google Fonts under the SIL Open Font License (the licences are next to the files in `assets/fonts/ui/`). These are used for the app's own words only, never for Quran text.

The app also shows these sources on its own **Settings → About → Sources** page. Quran text, layouts and metadata there are read from the database's `sources` table.
