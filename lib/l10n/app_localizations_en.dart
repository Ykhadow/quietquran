// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Quiet Quran';

  @override
  String get back => 'Back';

  @override
  String get settings => 'Settings';

  @override
  String get save => 'Save';

  @override
  String get continueLabel => 'Continue';

  @override
  String get startReading => 'Start reading';

  @override
  String get changeLater => 'You can change this any time in Settings.';

  @override
  String get scriptTitle => 'Which script do you read?';

  @override
  String get scriptSubtitle =>
      'Choose the style of Mushaf you learned from. Next you can pick the exact printed edition.';

  @override
  String get indopakTitle => 'IndoPak (Nastaliq)';

  @override
  String get indopakTagline =>
      'Common in Pakistan, India, Bangladesh and South Africa';

  @override
  String get madaniTitle => 'Madani (Uthmani)';

  @override
  String get madaniTagline =>
      'The King Fahd Complex Mushaf, standard across the Arab world';

  @override
  String get scriptIndopak => 'IndoPak';

  @override
  String get scriptMadani => 'Madani';

  @override
  String get modeTitle => 'How would you like to read?';

  @override
  String modeSubtitle(String script) {
    return 'Read the Quran as live text drawn with Quranic fonts, or as pictures of a printed $script Mushaf.';
  }

  @override
  String get modeText => 'Text';

  @override
  String get modeTextTagline =>
      'Adjustable size, theme aware, and crisp at any resolution';

  @override
  String get modeTextCaption => 'Your Mushaf\'s exact lines, drawn as text';

  @override
  String get modeTextPoint1 =>
      'Adjustable text size, with an Easy read view for large print';

  @override
  String get modeTextPoint2 =>
      'Light and dark themes that are easy on the eyes';

  @override
  String get modeTextPoint3 =>
      'Crisp at any size, including tablets and desktop';

  @override
  String get modeTextPoint4 => 'Included in the app: nothing to download';

  @override
  String get modePages => 'Printed pages';

  @override
  String get modePagesTagline => 'Pages of a real printed Mushaf';

  @override
  String get modePagesCaption => 'The page exactly as printed';

  @override
  String get modePagesPoint1 => 'Looks exactly like the Mushaf you are used to';

  @override
  String get modePagesPoint2 =>
      'Keeps the visual page memory that hifz depends on';

  @override
  String get modePagesPoint3 => 'Pinch to zoom';

  @override
  String get modePagesFootnote =>
      'Pages download as you read, or save a whole edition for offline use in Settings.';

  @override
  String get editionTitle => 'Which Mushaf do you read from?';

  @override
  String get editionSubtitleText =>
      'Pick the edition you learned from. Every line and page break follows that print.';

  @override
  String get editionSubtitlePages => 'Pick the printed edition you know best.';

  @override
  String editionDetailText(int lines, int pages) {
    return '$lines lines per page · $pages pages';
  }

  @override
  String editionDetailPages(String description, int mb) {
    return '$description About $mb MB to save the full set.';
  }

  @override
  String get dailyReading => 'Daily reading';

  @override
  String get otherSessions => 'Other sessions';

  @override
  String get newLabel => 'New';

  @override
  String get sessionsHint =>
      'Keep separate places for other readings — Al-Kahf on Fridays, Al-Mulk at night — without losing your daily page.';

  @override
  String get browse => 'Browse';

  @override
  String get surahs => 'Surahs';

  @override
  String get juz => 'Juz';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get searchHint => 'Search surahs — name, meaning or number';

  @override
  String noSurahMatches(String query) {
    return 'No surah matches \"$query\".';
  }

  @override
  String opensAtStart(int page) {
    return 'Opens at the start · Page $page';
  }

  @override
  String pageJuz(int page, int juz) {
    return 'Page $page · Juz $juz';
  }

  @override
  String get open => 'Open';

  @override
  String get resume => 'Resume';

  @override
  String get sessionStart => 'start';

  @override
  String pageShort(int page) {
    return 'p. $page';
  }

  @override
  String versesPage(int count, int page) {
    return '$count verses · p. $page';
  }

  @override
  String juzN(int n) {
    return 'Juz $n';
  }

  @override
  String surahN(int n) {
    return 'Surah $n';
  }

  @override
  String get noBookmarks => 'No bookmarks yet';

  @override
  String get noBookmarksHint =>
      'Bookmark a page or an ayah to find it again here.';

  @override
  String get editSession => 'Edit session';

  @override
  String get name => 'Name';

  @override
  String get eachTimeOpen => 'Each time you open it';

  @override
  String get startOfSurah => 'Start of surah';

  @override
  String get deleteSession => 'Delete session';

  @override
  String tapAgainDelete(String name) {
    return 'Tap again to delete \"$name\"';
  }

  @override
  String get note => 'Note';

  @override
  String get optional => 'Optional';

  @override
  String get removeBookmark => 'Remove bookmark';

  @override
  String get newSession => 'New session';

  @override
  String get newSessionHint =>
      'A place to come back to, separate from your daily reading.';

  @override
  String get nameExample => 'e.g. Night · Al-Mulk';

  @override
  String get startsAt => 'Starts at';

  @override
  String get createSession => 'Create session';

  @override
  String get browsing => 'Browsing';

  @override
  String continueFromHere(String name) {
    return 'Continue $name from here';
  }

  @override
  String movesTo(String name, String place) {
    return 'Moves $name to $place';
  }

  @override
  String get saveAsNew => 'Save as a new session';

  @override
  String get saveAsNewHint => 'Name it, and come back to it from Home';

  @override
  String get backToHome => 'Back to home';

  @override
  String get saveAsSession => 'Save this place as a session';

  @override
  String get bookmarkPage => 'Bookmark this page';

  @override
  String readerMeta(int juz, String pages, int total) {
    return 'Juz $juz · $pages of $total';
  }

  @override
  String get displayTooltip =>
      'Quick settings: view, text size, translation and theme';

  @override
  String get showTranslation => 'Show translation';

  @override
  String get hideTranslation => 'Hide translation';

  @override
  String pageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String scrubberLabel(String unit, int current, int count) {
    return '$unit $current of $count. Drag to jump.';
  }

  @override
  String get surah => 'Surah';

  @override
  String runningHeadJuz(int juz) {
    return 'JUZ $juz';
  }

  @override
  String get display => 'Display';

  @override
  String get readAs => 'Read as';

  @override
  String get printed => 'Printed';

  @override
  String get layout => 'Layout';

  @override
  String get mushafPage => 'Mushaf page';

  @override
  String get reflow => 'Easy read';

  @override
  String get textSize => 'Text size';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get bookmarked => 'Bookmarked';

  @override
  String get copy => 'Copy';

  @override
  String copied(String reference) {
    return 'Copied $reference';
  }

  @override
  String get offline => 'You\'re offline';

  @override
  String get pageFailed => 'This page didn\'t load';

  @override
  String offlineDetail(int page) {
    return 'Page $page hasn\'t been saved to this device yet. Connect to the internet, or save the full set in Settings to read offline.';
  }

  @override
  String failedDetail(int page) {
    return 'Something went wrong fetching page $page.';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String pageN(int page) {
    return 'Page $page';
  }

  @override
  String get loadingPage => 'Loading the printed page…';

  @override
  String get appearance => 'Appearance';

  @override
  String get mushaf => 'Mushaf';

  @override
  String get edition => 'Edition';

  @override
  String get typeface => 'Typeface';

  @override
  String get textLayout => 'Text layout';

  @override
  String get reflowTextSize => 'Easy read text size';

  @override
  String get reader => 'Reader';

  @override
  String get scrubberHint => 'The strip at the bottom of the reader jumps by';

  @override
  String get offlinePages => 'Printed pages for offline use';

  @override
  String get about => 'About';

  @override
  String get aboutText =>
      'Free and open source, with no ads, no tracking and no accounts.';

  @override
  String linesPages(int lines, int pages) {
    return '$lines lines · $pages pages';
  }

  @override
  String get system => 'System';

  @override
  String get custom => 'Custom';

  @override
  String swatchLabel(String label) {
    return '$label colours';
  }

  @override
  String downloadStopped(String error) {
    return 'Download stopped: $error';
  }

  @override
  String downloadProgress(int cached, int total, int mb) {
    return '$cached of $total pages · about $mb MB';
  }

  @override
  String get pause => 'Pause';

  @override
  String get downloadAll => 'Download all';

  @override
  String get deleteSaved => 'Delete saved pages';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageHint => 'The app\'s language.';

  @override
  String get paletteNight => 'Night';

  @override
  String get paletteDay => 'Day';

  @override
  String get paletteSepia => 'Sepia';

  @override
  String get paletteGreen => 'Green';

  @override
  String get paletteContrast => 'High contrast';

  @override
  String get typefaceIndopak => 'IndoPak Nastaleeq';

  @override
  String get typefaceIndopakDesc => 'The classic Subcontinent style';

  @override
  String get typefaceQpcNastaleeq => 'KFGQPC Nastaleeq';

  @override
  String get typefaceQpcNastaleeqDesc =>
      'IndoPak style by the King Fahd Complex';

  @override
  String get typefaceQpcHafs => 'KFGQPC Hafs';

  @override
  String get typefaceQpcHafsDesc => 'Uthmani script by the King Fahd Complex';

  @override
  String get customColours => 'Custom colours';

  @override
  String contrastGood(String ratio) {
    return 'Contrast $ratio:1 — easy to read.';
  }

  @override
  String contrastBad(String ratio) {
    return 'Contrast $ratio:1 — text may be hard to read. 4.5:1 or more is recommended.';
  }

  @override
  String get background => 'Background';

  @override
  String get textColour => 'Text';

  @override
  String get accent => 'Accent';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get suggestedColour => 'Suggested colour';

  @override
  String get editionIndopak15Qudratullah => '15-line · Qudratullah';

  @override
  String get editionIndopak16Taj => '16-line · Taj Company';

  @override
  String get editionIndopak13Qudratullah => '13-line · Qudratullah';

  @override
  String get editionIndopak13Taj => '13-line · Taj Company';

  @override
  String get editionIndopak9Gaba => '9-line · Gaba (large print)';

  @override
  String get editionMadani1405 => '1405H · KFGQPC V1';

  @override
  String get editionMadani1421 => '1421H · KFGQPC V2';

  @override
  String get imageIndopak15Plain => '15-line · King Fahd Complex';

  @override
  String get imageIndopak15PlainDesc =>
      'The King Fahd Complex\'s IndoPak 15-line Mushaf (610 pages).';

  @override
  String get imageIndopak16Taj => '16-line · Taj Company';

  @override
  String get imageIndopak16TajDesc =>
      'Scan of the Taj Company 16-line print (548 pages).';

  @override
  String get imageIndopak13Qudratullah => '13-line · Qudratullah';

  @override
  String get imageIndopak13QudratullahDesc =>
      'Scan of the Qudratullah 13-line print (849 pages).';

  @override
  String get imageIndopak15Colour => '15-line · colour-coded tajweed';

  @override
  String get imageIndopak15ColourDesc =>
      'Tajweed rules in colour on every page (610 pages).';

  @override
  String get imageMadani15 => '15-line · King Fahd Complex';

  @override
  String get imageMadani15Desc =>
      'The King Fahd Complex\'s Madinah Mushaf, Mumtaz print (604 pages).';

  @override
  String get sources => 'Sources';

  @override
  String get sourcesHint =>
      'Where the Quran text, layouts, fonts and page images come from';

  @override
  String get sourcesIntro =>
      'Every word of Quran text, every Mushaf layout and all Quran data in this app come from QUL, the Quranic Universal Library by Tarteel AI, which publishes proofread data. The text is used exactly as published, apart from trimming stray spaces at the edges of words.';

  @override
  String get srcText => 'Quran text, word by word';

  @override
  String get srcLayouts => 'Mushaf layouts';

  @override
  String get srcLayoutsNote =>
      'Which words sit on each line of each page, for each printed edition.';

  @override
  String get srcFonts => 'Quran fonts';

  @override
  String get srcMetadata => 'Quran data';

  @override
  String get metaSurahs => 'Surah names, revelation places and verse counts';

  @override
  String get metaAyahs => 'Ayah list';

  @override
  String get metaJuz => 'Juz';

  @override
  String get metaHizb => 'Hizb';

  @override
  String get metaRub => 'Rub al-hizb';

  @override
  String get metaManzil => 'Manzil';

  @override
  String get metaRuku => 'Ruku';

  @override
  String get metaSajda => 'Places of sajdah';

  @override
  String get srcPrinted => 'Printed page images';

  @override
  String get srcPrintedNote =>
      'The King Fahd Complex\'s own Mushaf pages, taken unchanged from its files, so their accuracy rests on the print itself. They download from our own hosting as you read.';

  @override
  String imageThanks(String name) {
    return 'With thanks to $name, whose page collection led us to this original.';
  }

  @override
  String get srcOther => 'Not Quran text';

  @override
  String get srcOtherNote =>
      'These parts are made or taken outside QUL. None of them is Quran text.';

  @override
  String get otherMeanings =>
      'English meanings of surah names (used in search)';

  @override
  String get otherHeaders =>
      'The words آياتها, مكية and مدنية in surah headers';

  @override
  String get writtenInApp => 'Written in the app';

  @override
  String get otherMarkers => 'Ayah markers for the KFGQPC Nastaleeq typeface';

  @override
  String get otherMarkersSource =>
      'Drawn by the app: the font\'s own ayah ornament, with QUL\'s ayah numbers';

  @override
  String get otherLineFit => 'Text size of each edition';

  @override
  String get otherLineFitSource =>
      'Measured with HarfBuzz from the bundled fonts, so every line fits';

  @override
  String get srcAppFonts => 'App fonts';

  @override
  String get appFontsSource => 'Google Fonts · SIL Open Font License';

  @override
  String get openLink => 'Open link';

  @override
  String get languageStepSubtitle =>
      'Choose the language for the app\'s menus and buttons.';

  @override
  String get languageSystemHint => 'Follow the phone\'s language';

  @override
  String get colourBrightness => 'Brightness';

  @override
  String get hexCode => 'Hex code';

  @override
  String get editionBigTextIndopak =>
      'Want bigger letters? The 13-line and 9-line editions have larger text, and in the reader you can pinch to zoom or switch to Easy read, which shows the text at any size.';

  @override
  String get editionBigTextMadani =>
      'Want bigger letters? In the reader you can pinch to zoom, or switch to Easy read, which shows the text at any size.';

  @override
  String get displayBigTextIndopak =>
      'Want bigger text? Pinch the page to zoom, choose Easy read, or pick the 13- or 9-line edition in Settings.';

  @override
  String get displayBigTextMadani =>
      'Want bigger text? Pinch the page to zoom, or choose Easy read.';

  @override
  String get translation => 'Translation';

  @override
  String get translationNone => 'None';

  @override
  String get translationAuto => 'Match app language';

  @override
  String get translationHint =>
      'Shown when you hold an ayah, and under each ayah in Easy read. The Mushaf page itself stays Quran only.';

  @override
  String translationBy(String translator) {
    return 'Translation: $translator';
  }

  @override
  String get srcTranslations => 'Translations of the meanings';

  @override
  String get srcTranslationsNote =>
      'Shown with the Arabic, never instead of it, exactly as each translator published it (without footnotes).';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUrdu => 'Urdu';

  @override
  String get translationStepTitle => 'Would you like a translation?';

  @override
  String get translationStepSubtitle =>
      'The meaning of each ayah in your language. Press and hold any ayah while reading to see its translation.';

  @override
  String get theme => 'Theme';

  @override
  String get themeAuto => 'Auto';

  @override
  String get pagesLabel => 'Pages';

  @override
  String get onePage => 'One';

  @override
  String get twoPagesLabel => 'Two';

  @override
  String get twoPagesSetting => 'Two pages side by side';

  @override
  String get twoPagesHint =>
      'On tablets, computers and phones held sideways, like an open book.';

  @override
  String get onePageTip => 'One page';

  @override
  String get twoPagesTip => 'Two pages side by side';

  @override
  String get textSizeStepTitle => 'Choose a comfortable text size';

  @override
  String get textSizeStepSubtitle =>
      'Choose the size you\'d like to read at. You can change it any time while reading.';

  @override
  String get viewLabel => 'View';

  @override
  String get printedFollowTheme => 'Printed pages follow the theme';

  @override
  String get printedFollowThemeHint =>
      'Printed pages take your paper and text colours. Turn off to see them exactly as printed, in their own colours.';

  @override
  String get remindMe => 'Remind me';

  @override
  String get reminderBody => 'Time for your reading';

  @override
  String get everyDay => 'Every day';

  @override
  String get reminderPermissionOff =>
      'Notifications are turned off for this app. Allow them in your phone\'s settings to get reminders.';

  @override
  String reminderAt(String time) {
    return 'Reminder at $time';
  }

  @override
  String get share => 'Share';

  @override
  String get shareImage => 'Share image';

  @override
  String get shareText => 'Share text';

  @override
  String get saveImage => 'Save image';

  @override
  String get copyText => 'Copy text';

  @override
  String get cardPost => 'Post';

  @override
  String get cardStory => 'Story';

  @override
  String imageSaved(String path) {
    return 'Image saved to $path';
  }

  @override
  String get wordSpacing => 'Word spacing';

  @override
  String get surahTitles => 'Surah titles';

  @override
  String get verticalScrollSetting => 'Scroll pages vertically';

  @override
  String get verticalScrollHint =>
      'One continuous scroll, top to bottom, instead of turning pages sideways. Pages show one at a time.';

  @override
  String get listen => 'Listen';

  @override
  String get previousAyah => 'Previous ayah';

  @override
  String get nextAyah => 'Next ayah';

  @override
  String get stopRecitation => 'Stop';

  @override
  String get recitation => 'Recitation';

  @override
  String get reciter => 'Reciter';

  @override
  String get repeatAyah => 'Recite each ayah';

  @override
  String get recitationFailed => 'Couldn\'t load. Check your connection.';

  @override
  String get recitationHint =>
      'Each reciter\'s own recording, ayah by ayah, from EveryAyah. Ayahs you\'ve heard are kept, so they play again without a connection.';

  @override
  String get bismillah => 'Bismillah';

  @override
  String get srcRecitationNote =>
      'One recording per ayah, as each reciter recorded it and EveryAyah publishes it; nothing is cut or joined. The Bismillah before a surah is Al-Fatihah\'s first ayah.';

  @override
  String get srcTranslationVoices => 'Translations, read aloud';

  @override
  String roundOf(int round, int rounds) {
    return '$round of $rounds';
  }

  @override
  String get backup => 'Your places';

  @override
  String get exportLibrary => 'Save to a file';

  @override
  String get exportLibraryHint =>
      'Your sessions, bookmarks and notes, to keep or open on another device.';

  @override
  String get importLibrary => 'Open a saved file';

  @override
  String get importLibraryHint =>
      'Brings in places saved from Quiet Quran on any device.';

  @override
  String get importConfirmTitle => 'Replace your places here?';

  @override
  String get importConfirmBody =>
      'The sessions, bookmarks and notes on this device will be replaced by the file’s.';

  @override
  String get replace => 'Replace';

  @override
  String imported(int sessions, int bookmarks) {
    return 'Brought in $sessions sessions and $bookmarks bookmarks.';
  }

  @override
  String get importFailed => 'That isn’t a file saved from Quiet Quran.';

  @override
  String get exported => 'Saved.';

  @override
  String get translationAudioHint =>
      'When the translation is shown under each ayah, it\'s read aloud after the recitation.';

  @override
  String get switchToDay => 'Switch to Day';

  @override
  String get switchToNight => 'Switch to Night';

  @override
  String showAll(int count) {
    return 'Show all ($count)';
  }

  @override
  String get showLess => 'Show less';

  @override
  String get printedDownloadTitle => 'Download printed pages?';

  @override
  String printedDownloadBody(int pages, int mb) {
    return 'Printed pages are downloaded once, then work fully offline. $pages pages, about $mb MB. Wi-Fi is recommended.';
  }

  @override
  String get printedDownloadStart => 'Download';

  @override
  String get printedDownloading => 'Downloading printed pages';

  @override
  String get printedDownloadStopped => 'Download paused';

  @override
  String printedDownloadProgress(int done, int total) {
    return '$done of $total pages';
  }

  @override
  String get printedDownloadKeepOpen =>
      'Keep the app open until it finishes. Then every page is on your device, and you can read without a connection.';

  @override
  String get printedDownloadStoppedHint =>
      'The connection was lost. Pages already saved are kept: try again to carry on from here.';

  @override
  String get pageNotSaved => 'This page isn\'t saved';

  @override
  String pageNotSavedDetail(int page) {
    return 'Page $page of this printed set isn\'t on this device. Download the set again to read it.';
  }

  @override
  String get downloadPrinted => 'Download printed pages';
}
