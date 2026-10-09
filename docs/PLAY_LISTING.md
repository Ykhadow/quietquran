# Google Play listing and forms

Everything Play Console asks for, ready to paste. Developer: **Quietworks** (personal account).

## Store listing

**App name** (30 max): `Quiet Quran: IndoPak & Madani`

**Short description** (80 max):

```
No ads, no tracking. A calm Quran reader with real IndoPak and Madani pages.
```

**Full description** (4,000 max):

```
Quiet Quran is a calm, free Quran reader for IndoPak and Madani readers. Each Mushaf is shown in its own line layout, page for page, the way it is printed, so the page you read on your phone looks like the Mushaf you learned from.

There are no ads, no purchases and no tracking, and there never will be. Quiet Quran is made as sadaqah jariyah.

THE MUSHAF YOU KNOW
• IndoPak: 15-line (610 pages), 16-line Taj Company, 13-line, and 9-line large print
• Madani: the 15-line 604-page Mushaf (1405H and 1421H)
• Lines are justified as in print, with the surah headers and page numbers in their places
• Easy read: the same text in a larger size, flowing to fit your screen
• Printed pages: the King Fahd Complex's own IndoPak and Madani Mushaf pages, unchanged, saved for offline reading if you like

LISTEN, AYAH BY AYAH
• Recitations by Mishary Alafasy, Abdul Basit, Al-Husary, Al-Minshawi, As-Sudais, Ash-Shuraim, Al-Muaiqly, Al-Ghamdi and others
• Repeat each ayah to memorise, and hear the translation after each ayah
• Plays with the screen off, with controls on your lock screen

TRANSLATION OF THE MEANINGS
• English (Saheeh International) and Urdu (Fateh Muhammad Jalandhari)
• Under every ayah, or just for the ayah you hold

YOUR READINGS, KEPT
• Your daily reading always keeps your place
• Separate sessions for other readings: Al-Kahf on Fridays, Al-Mulk at night
• Gentle reminders, bookmarks with notes, and export of everything to a file
• Your place is kept by ayah, so changing Mushaf or reading style never loses it

COMFORTABLE TO READ
• Day, Night, Sepia, Green and High contrast themes, or your own colours
• Text size and word spacing to suit your eyes
• Share an ayah as a beautiful image or as text
• In English, Urdu and Arabic

FROM TRUSTED SOURCES
Every page, font and word comes from reputable, proofread sources and is used exactly as published: the Quran text from QUL (Tarteel), the printed pages from the King Fahd Glorious Quran Printing Complex, and the recitations from EveryAyah. Every source is credited inside the app.

PRIVATE AND OPEN
Quiet Quran collects nothing. Your reading stays with you. The code is open source, so anyone can see exactly what it does: github.com/Ykhadow/quietquran

Website: quietquran.com
```

**Category:** Books & Reference
**Tags** (pick up to 5 that Play offers): Religion, Books & Reference, Reading, Education
**Contact email:** support@quietquran.com
**Website:** https://quietquran.com
**Privacy policy:** https://quietquran.com/privacy

**Graphics:** app icon 512 × 512 PNG; feature graphic 1024 × 500; 2 to 8 phone screenshots (made from the app; see `website/img` and `test/site_screenshots_test.dart`).

## App content forms

**Privacy policy:** https://quietquran.com/privacy

**App access:** All functionality is available without special access (no login).

**Ads:** No, the app does not contain ads.

**Content rating** (IARC questionnaire):
- Category: Reference, News, or Educational
- Violence, sexuality, language, controlled substances, gambling, fear: all **No**
- Users interact or exchange content with each other in the app: **No** (sharing an ayah hands it to another app the user chooses)
- Shares the user's location with others: **No**
- Digital purchases: **No**
- Unrestricted internet access (e.g. a web browser): **No**

**Target audience:** 13–15, 16–17 and 18+. Not designed for children. "Could the app unintentionally appeal to children?" No (a reference app with no characters, games or child-directed content).

**News app:** No. **Government app:** No. **Financial features:** None. **Health app:** No.

**Data safety:**
- Does the app collect or share any of the required user data types? **No.**
- The app downloads page images (pages.quietquran.com) and recitation audio (everyayah.com) over HTTPS. These requests carry no identifier and nothing about the reader; the developer neither collects nor uses them.
- Settings, sessions and bookmarks stay on the device. Android's own system backup can copy them to the user's Google account if the user has backups on; that is Android's feature, not the app sending data to the developer.
- Encrypted in transit: yes (all downloads use HTTPS).
- Account creation: none, so no deletion request is needed.

**Foreground service declaration** (Android 14+):
- Type: **Media playback** (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`)
- Use: "Plays Quran recitation chosen by the user, ayah by ayah, so it continues with the screen off or while using other apps. It starts only when the user presses play and shows a notification with playback controls on the lock screen."
- If a video is asked for: a short screen recording of starting a recitation and the notification controls appearing.

**Notifications permission:** used for reading reminders set by the user, for the recitation player's controls, and for the progress of saving printed pages for offline reading.

## Closed test

New personal accounts need **12 or more testers opted in for 14 days in a row** before applying for production.
1. Create a Google Group (for example quietquran-testers@googlegroups.com).
2. In Play Console, Testing → Closed testing → create a track, and add the group as the testers list.
3. Upload the App Bundle, and send testers the opt-in link.
4. Ask testers to keep the app installed for the whole 14 days.
