import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ur'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet Quran'**
  String get appTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get startReading;

  /// No description provided for @changeLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this any time in Settings.'**
  String get changeLater;

  /// No description provided for @scriptTitle.
  ///
  /// In en, this message translates to:
  /// **'Which script do you read?'**
  String get scriptTitle;

  /// No description provided for @scriptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the style of Mushaf you learned from. Next you can pick the exact printed edition.'**
  String get scriptSubtitle;

  /// No description provided for @indopakTitle.
  ///
  /// In en, this message translates to:
  /// **'IndoPak (Nastaliq)'**
  String get indopakTitle;

  /// No description provided for @indopakTagline.
  ///
  /// In en, this message translates to:
  /// **'Common in Pakistan, India, Bangladesh and South Africa'**
  String get indopakTagline;

  /// No description provided for @madaniTitle.
  ///
  /// In en, this message translates to:
  /// **'Madani (Uthmani)'**
  String get madaniTitle;

  /// No description provided for @madaniTagline.
  ///
  /// In en, this message translates to:
  /// **'The King Fahd Complex Mushaf, standard across the Arab world'**
  String get madaniTagline;

  /// No description provided for @scriptIndopak.
  ///
  /// In en, this message translates to:
  /// **'IndoPak'**
  String get scriptIndopak;

  /// No description provided for @scriptMadani.
  ///
  /// In en, this message translates to:
  /// **'Madani'**
  String get scriptMadani;

  /// No description provided for @modeTitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to read?'**
  String get modeTitle;

  /// No description provided for @modeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read the Quran as live text drawn with Quranic fonts, or as pictures of a printed {script} Mushaf.'**
  String modeSubtitle(String script);

  /// No description provided for @modeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get modeText;

  /// No description provided for @modeTextTagline.
  ///
  /// In en, this message translates to:
  /// **'Adjustable size, theme aware, and crisp at any resolution'**
  String get modeTextTagline;

  /// No description provided for @modeTextCaption.
  ///
  /// In en, this message translates to:
  /// **'Your Mushaf\'s exact lines, drawn as text'**
  String get modeTextCaption;

  /// No description provided for @modeTextPoint1.
  ///
  /// In en, this message translates to:
  /// **'Adjustable text size, with an Easy read view for large print'**
  String get modeTextPoint1;

  /// No description provided for @modeTextPoint2.
  ///
  /// In en, this message translates to:
  /// **'Light and dark themes that are easy on the eyes'**
  String get modeTextPoint2;

  /// No description provided for @modeTextPoint3.
  ///
  /// In en, this message translates to:
  /// **'Crisp at any size, including tablets and desktop'**
  String get modeTextPoint3;

  /// No description provided for @modeTextPoint4.
  ///
  /// In en, this message translates to:
  /// **'Included in the app: nothing to download'**
  String get modeTextPoint4;

  /// No description provided for @modePages.
  ///
  /// In en, this message translates to:
  /// **'Printed pages'**
  String get modePages;

  /// No description provided for @modePagesTagline.
  ///
  /// In en, this message translates to:
  /// **'Pages of a real printed Mushaf'**
  String get modePagesTagline;

  /// No description provided for @modePagesCaption.
  ///
  /// In en, this message translates to:
  /// **'The page exactly as printed'**
  String get modePagesCaption;

  /// No description provided for @modePagesPoint1.
  ///
  /// In en, this message translates to:
  /// **'Looks exactly like the Mushaf you are used to'**
  String get modePagesPoint1;

  /// No description provided for @modePagesPoint2.
  ///
  /// In en, this message translates to:
  /// **'Keeps the visual page memory that hifz depends on'**
  String get modePagesPoint2;

  /// No description provided for @modePagesPoint3.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom'**
  String get modePagesPoint3;

  /// No description provided for @modePagesFootnote.
  ///
  /// In en, this message translates to:
  /// **'Pages download as you read, or save a whole edition for offline use in Settings.'**
  String get modePagesFootnote;

  /// No description provided for @editionTitle.
  ///
  /// In en, this message translates to:
  /// **'Which Mushaf do you read from?'**
  String get editionTitle;

  /// No description provided for @editionSubtitleText.
  ///
  /// In en, this message translates to:
  /// **'Pick the edition you learned from. Every line and page break follows that print.'**
  String get editionSubtitleText;

  /// No description provided for @editionSubtitlePages.
  ///
  /// In en, this message translates to:
  /// **'Pick the printed edition you know best.'**
  String get editionSubtitlePages;

  /// No description provided for @editionDetailText.
  ///
  /// In en, this message translates to:
  /// **'{lines} lines per page · {pages} pages'**
  String editionDetailText(int lines, int pages);

  /// No description provided for @editionDetailPages.
  ///
  /// In en, this message translates to:
  /// **'{description} About {mb} MB to save the full set.'**
  String editionDetailPages(String description, int mb);

  /// No description provided for @dailyReading.
  ///
  /// In en, this message translates to:
  /// **'Daily reading'**
  String get dailyReading;

  /// No description provided for @otherSessions.
  ///
  /// In en, this message translates to:
  /// **'Other sessions'**
  String get otherSessions;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @sessionsHint.
  ///
  /// In en, this message translates to:
  /// **'Keep separate places for other readings — Al-Kahf on Fridays, Al-Mulk at night — without losing your daily page.'**
  String get sessionsHint;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @surahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get surahs;

  /// No description provided for @juz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get juz;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search surahs — name, meaning or number'**
  String get searchHint;

  /// No description provided for @noSurahMatches.
  ///
  /// In en, this message translates to:
  /// **'No surah matches \"{query}\".'**
  String noSurahMatches(String query);

  /// No description provided for @opensAtStart.
  ///
  /// In en, this message translates to:
  /// **'Opens at the start · Page {page}'**
  String opensAtStart(int page);

  /// No description provided for @pageJuz.
  ///
  /// In en, this message translates to:
  /// **'Page {page} · Juz {juz}'**
  String pageJuz(int page, int juz);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @sessionStart.
  ///
  /// In en, this message translates to:
  /// **'start'**
  String get sessionStart;

  /// No description provided for @pageShort.
  ///
  /// In en, this message translates to:
  /// **'p. {page}'**
  String pageShort(int page);

  /// No description provided for @versesPage.
  ///
  /// In en, this message translates to:
  /// **'{count} verses · p. {page}'**
  String versesPage(int count, int page);

  /// No description provided for @juzN.
  ///
  /// In en, this message translates to:
  /// **'Juz {n}'**
  String juzN(int n);

  /// No description provided for @surahN.
  ///
  /// In en, this message translates to:
  /// **'Surah {n}'**
  String surahN(int n);

  /// No description provided for @noBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarks;

  /// No description provided for @noBookmarksHint.
  ///
  /// In en, this message translates to:
  /// **'Bookmark a page or an ayah to find it again here.'**
  String get noBookmarksHint;

  /// No description provided for @editSession.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get editSession;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @eachTimeOpen.
  ///
  /// In en, this message translates to:
  /// **'Each time you open it'**
  String get eachTimeOpen;

  /// No description provided for @startOfSurah.
  ///
  /// In en, this message translates to:
  /// **'Start of surah'**
  String get startOfSurah;

  /// No description provided for @deleteSession.
  ///
  /// In en, this message translates to:
  /// **'Delete session'**
  String get deleteSession;

  /// No description provided for @tapAgainDelete.
  ///
  /// In en, this message translates to:
  /// **'Tap again to delete \"{name}\"'**
  String tapAgainDelete(String name);

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get removeBookmark;

  /// No description provided for @newSession.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get newSession;

  /// No description provided for @newSessionHint.
  ///
  /// In en, this message translates to:
  /// **'A place to come back to, separate from your daily reading.'**
  String get newSessionHint;

  /// No description provided for @nameExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Night · Al-Mulk'**
  String get nameExample;

  /// No description provided for @startsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at'**
  String get startsAt;

  /// No description provided for @createSession.
  ///
  /// In en, this message translates to:
  /// **'Create session'**
  String get createSession;

  /// No description provided for @browsing.
  ///
  /// In en, this message translates to:
  /// **'Browsing'**
  String get browsing;

  /// No description provided for @continueFromHere.
  ///
  /// In en, this message translates to:
  /// **'Continue {name} from here'**
  String continueFromHere(String name);

  /// No description provided for @movesTo.
  ///
  /// In en, this message translates to:
  /// **'Moves {name} to {place}'**
  String movesTo(String name, String place);

  /// No description provided for @saveAsNew.
  ///
  /// In en, this message translates to:
  /// **'Save as a new session'**
  String get saveAsNew;

  /// No description provided for @saveAsNewHint.
  ///
  /// In en, this message translates to:
  /// **'Name it, and come back to it from Home'**
  String get saveAsNewHint;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @saveAsSession.
  ///
  /// In en, this message translates to:
  /// **'Save this place as a session'**
  String get saveAsSession;

  /// No description provided for @bookmarkPage.
  ///
  /// In en, this message translates to:
  /// **'Bookmark this page'**
  String get bookmarkPage;

  /// No description provided for @readerMeta.
  ///
  /// In en, this message translates to:
  /// **'Juz {juz} · {pages} of {total}'**
  String readerMeta(int juz, String pages, int total);

  /// No description provided for @displayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Quick settings: view, text size, translation and theme'**
  String get displayTooltip;

  /// No description provided for @showTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get showTranslation;

  /// No description provided for @hideTranslation.
  ///
  /// In en, this message translates to:
  /// **'Hide translation'**
  String get hideTranslation;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pageOf(int page, int total);

  /// No description provided for @scrubberLabel.
  ///
  /// In en, this message translates to:
  /// **'{unit} {current} of {count}. Drag to jump.'**
  String scrubberLabel(String unit, int current, int count);

  /// No description provided for @surah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get surah;

  /// No description provided for @runningHeadJuz.
  ///
  /// In en, this message translates to:
  /// **'JUZ {juz}'**
  String runningHeadJuz(int juz);

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @readAs.
  ///
  /// In en, this message translates to:
  /// **'Read as'**
  String get readAs;

  /// No description provided for @printed.
  ///
  /// In en, this message translates to:
  /// **'Printed'**
  String get printed;

  /// No description provided for @layout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layout;

  /// No description provided for @mushafPage.
  ///
  /// In en, this message translates to:
  /// **'Mushaf page'**
  String get mushafPage;

  /// No description provided for @reflow.
  ///
  /// In en, this message translates to:
  /// **'Easy read'**
  String get reflow;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @bookmarked.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get bookmarked;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied {reference}'**
  String copied(String reference);

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offline;

  /// No description provided for @pageFailed.
  ///
  /// In en, this message translates to:
  /// **'This page didn\'t load'**
  String get pageFailed;

  /// No description provided for @offlineDetail.
  ///
  /// In en, this message translates to:
  /// **'Page {page} hasn\'t been saved to this device yet. Connect to the internet, or save the full set in Settings to read offline.'**
  String offlineDetail(int page);

  /// No description provided for @failedDetail.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong fetching page {page}.'**
  String failedDetail(int page);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @pageN.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String pageN(int page);

  /// No description provided for @loadingPage.
  ///
  /// In en, this message translates to:
  /// **'Loading the printed page…'**
  String get loadingPage;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @mushaf.
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get mushaf;

  /// No description provided for @edition.
  ///
  /// In en, this message translates to:
  /// **'Edition'**
  String get edition;

  /// No description provided for @typeface.
  ///
  /// In en, this message translates to:
  /// **'Typeface'**
  String get typeface;

  /// No description provided for @textLayout.
  ///
  /// In en, this message translates to:
  /// **'Text layout'**
  String get textLayout;

  /// No description provided for @reflowTextSize.
  ///
  /// In en, this message translates to:
  /// **'Easy read text size'**
  String get reflowTextSize;

  /// No description provided for @reader.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get reader;

  /// No description provided for @scrubberHint.
  ///
  /// In en, this message translates to:
  /// **'The strip at the bottom of the reader jumps by'**
  String get scrubberHint;

  /// No description provided for @offlinePages.
  ///
  /// In en, this message translates to:
  /// **'Printed pages for offline use'**
  String get offlinePages;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'Free and open source, with no ads, no tracking and no accounts.'**
  String get aboutText;

  /// No description provided for @linesPages.
  ///
  /// In en, this message translates to:
  /// **'{lines} lines · {pages} pages'**
  String linesPages(int lines, int pages);

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @swatchLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} colours'**
  String swatchLabel(String label);

  /// No description provided for @downloadStopped.
  ///
  /// In en, this message translates to:
  /// **'Download stopped: {error}'**
  String downloadStopped(String error);

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'{cached} of {total} pages · about {mb} MB'**
  String downloadProgress(int cached, int total, int mb);

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @downloadAll.
  ///
  /// In en, this message translates to:
  /// **'Download all'**
  String get downloadAll;

  /// No description provided for @deleteSaved.
  ///
  /// In en, this message translates to:
  /// **'Delete saved pages'**
  String get deleteSaved;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'The app\'s language.'**
  String get languageHint;

  /// No description provided for @paletteNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get paletteNight;

  /// No description provided for @paletteDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get paletteDay;

  /// No description provided for @paletteSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get paletteSepia;

  /// No description provided for @paletteGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get paletteGreen;

  /// No description provided for @paletteContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get paletteContrast;

  /// No description provided for @typefaceIndopak.
  ///
  /// In en, this message translates to:
  /// **'IndoPak Nastaleeq'**
  String get typefaceIndopak;

  /// No description provided for @typefaceIndopakDesc.
  ///
  /// In en, this message translates to:
  /// **'The classic Subcontinent style'**
  String get typefaceIndopakDesc;

  /// No description provided for @typefaceQpcNastaleeq.
  ///
  /// In en, this message translates to:
  /// **'KFGQPC Nastaleeq'**
  String get typefaceQpcNastaleeq;

  /// No description provided for @typefaceQpcNastaleeqDesc.
  ///
  /// In en, this message translates to:
  /// **'IndoPak style by the King Fahd Complex'**
  String get typefaceQpcNastaleeqDesc;

  /// No description provided for @typefaceQpcHafs.
  ///
  /// In en, this message translates to:
  /// **'KFGQPC Hafs'**
  String get typefaceQpcHafs;

  /// No description provided for @typefaceQpcHafsDesc.
  ///
  /// In en, this message translates to:
  /// **'Uthmani script by the King Fahd Complex'**
  String get typefaceQpcHafsDesc;

  /// No description provided for @customColours.
  ///
  /// In en, this message translates to:
  /// **'Custom colours'**
  String get customColours;

  /// No description provided for @contrastGood.
  ///
  /// In en, this message translates to:
  /// **'Contrast {ratio}:1 — easy to read.'**
  String contrastGood(String ratio);

  /// No description provided for @contrastBad.
  ///
  /// In en, this message translates to:
  /// **'Contrast {ratio}:1 — text may be hard to read. 4.5:1 or more is recommended.'**
  String contrastBad(String ratio);

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @textColour.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textColour;

  /// No description provided for @accent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get accent;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @suggestedColour.
  ///
  /// In en, this message translates to:
  /// **'Suggested colour'**
  String get suggestedColour;

  /// No description provided for @editionIndopak15Qudratullah.
  ///
  /// In en, this message translates to:
  /// **'15-line · Qudratullah'**
  String get editionIndopak15Qudratullah;

  /// No description provided for @editionIndopak16Taj.
  ///
  /// In en, this message translates to:
  /// **'16-line · Taj Company'**
  String get editionIndopak16Taj;

  /// No description provided for @editionIndopak13Qudratullah.
  ///
  /// In en, this message translates to:
  /// **'13-line · Qudratullah'**
  String get editionIndopak13Qudratullah;

  /// No description provided for @editionIndopak13Taj.
  ///
  /// In en, this message translates to:
  /// **'13-line · Taj Company'**
  String get editionIndopak13Taj;

  /// No description provided for @editionIndopak9Gaba.
  ///
  /// In en, this message translates to:
  /// **'9-line · Gaba (large print)'**
  String get editionIndopak9Gaba;

  /// No description provided for @editionMadani1405.
  ///
  /// In en, this message translates to:
  /// **'1405H · KFGQPC V1'**
  String get editionMadani1405;

  /// No description provided for @editionMadani1421.
  ///
  /// In en, this message translates to:
  /// **'1421H · KFGQPC V2'**
  String get editionMadani1421;

  /// No description provided for @imageIndopak15Plain.
  ///
  /// In en, this message translates to:
  /// **'15-line · King Fahd Complex'**
  String get imageIndopak15Plain;

  /// No description provided for @imageIndopak15PlainDesc.
  ///
  /// In en, this message translates to:
  /// **'The King Fahd Complex\'s IndoPak 15-line Mushaf (610 pages).'**
  String get imageIndopak15PlainDesc;

  /// No description provided for @imageIndopak16Taj.
  ///
  /// In en, this message translates to:
  /// **'16-line · Taj Company'**
  String get imageIndopak16Taj;

  /// No description provided for @imageIndopak16TajDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan of the Taj Company 16-line print (548 pages).'**
  String get imageIndopak16TajDesc;

  /// No description provided for @imageIndopak13Qudratullah.
  ///
  /// In en, this message translates to:
  /// **'13-line · Qudratullah'**
  String get imageIndopak13Qudratullah;

  /// No description provided for @imageIndopak13QudratullahDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan of the Qudratullah 13-line print (849 pages).'**
  String get imageIndopak13QudratullahDesc;

  /// No description provided for @imageIndopak15Colour.
  ///
  /// In en, this message translates to:
  /// **'15-line · colour-coded tajweed'**
  String get imageIndopak15Colour;

  /// No description provided for @imageIndopak15ColourDesc.
  ///
  /// In en, this message translates to:
  /// **'Tajweed rules in colour on every page (610 pages).'**
  String get imageIndopak15ColourDesc;

  /// No description provided for @imageMadani15.
  ///
  /// In en, this message translates to:
  /// **'15-line · King Fahd Complex'**
  String get imageMadani15;

  /// No description provided for @imageMadani15Desc.
  ///
  /// In en, this message translates to:
  /// **'The King Fahd Complex\'s Madinah Mushaf, Mumtaz print (604 pages).'**
  String get imageMadani15Desc;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @sourcesHint.
  ///
  /// In en, this message translates to:
  /// **'Where the Quran text, layouts, fonts and page images come from'**
  String get sourcesHint;

  /// No description provided for @sourcesIntro.
  ///
  /// In en, this message translates to:
  /// **'Every word of Quran text, every Mushaf layout and all Quran data in this app come from QUL, the Quranic Universal Library by Tarteel AI, which publishes proofread data. The text is used exactly as published, apart from trimming stray spaces at the edges of words.'**
  String get sourcesIntro;

  /// No description provided for @srcText.
  ///
  /// In en, this message translates to:
  /// **'Quran text, word by word'**
  String get srcText;

  /// No description provided for @srcLayouts.
  ///
  /// In en, this message translates to:
  /// **'Mushaf layouts'**
  String get srcLayouts;

  /// No description provided for @srcLayoutsNote.
  ///
  /// In en, this message translates to:
  /// **'Which words sit on each line of each page, for each printed edition.'**
  String get srcLayoutsNote;

  /// No description provided for @srcFonts.
  ///
  /// In en, this message translates to:
  /// **'Quran fonts'**
  String get srcFonts;

  /// No description provided for @srcMetadata.
  ///
  /// In en, this message translates to:
  /// **'Quran data'**
  String get srcMetadata;

  /// No description provided for @metaSurahs.
  ///
  /// In en, this message translates to:
  /// **'Surah names, revelation places and verse counts'**
  String get metaSurahs;

  /// No description provided for @metaAyahs.
  ///
  /// In en, this message translates to:
  /// **'Ayah list'**
  String get metaAyahs;

  /// No description provided for @metaJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get metaJuz;

  /// No description provided for @metaHizb.
  ///
  /// In en, this message translates to:
  /// **'Hizb'**
  String get metaHizb;

  /// No description provided for @metaRub.
  ///
  /// In en, this message translates to:
  /// **'Rub al-hizb'**
  String get metaRub;

  /// No description provided for @metaManzil.
  ///
  /// In en, this message translates to:
  /// **'Manzil'**
  String get metaManzil;

  /// No description provided for @metaRuku.
  ///
  /// In en, this message translates to:
  /// **'Ruku'**
  String get metaRuku;

  /// No description provided for @metaSajda.
  ///
  /// In en, this message translates to:
  /// **'Places of sajdah'**
  String get metaSajda;

  /// No description provided for @srcPrinted.
  ///
  /// In en, this message translates to:
  /// **'Printed page images'**
  String get srcPrinted;

  /// No description provided for @srcPrintedNote.
  ///
  /// In en, this message translates to:
  /// **'The King Fahd Complex\'s own Mushaf pages, taken unchanged from its files, so their accuracy rests on the print itself. They download from our own hosting as you read.'**
  String get srcPrintedNote;

  /// No description provided for @imageThanks.
  ///
  /// In en, this message translates to:
  /// **'With thanks to {name}, whose page collection led us to this original.'**
  String imageThanks(String name);

  /// No description provided for @srcOther.
  ///
  /// In en, this message translates to:
  /// **'Not Quran text'**
  String get srcOther;

  /// No description provided for @srcOtherNote.
  ///
  /// In en, this message translates to:
  /// **'These parts are made or taken outside QUL. None of them is Quran text.'**
  String get srcOtherNote;

  /// No description provided for @otherMeanings.
  ///
  /// In en, this message translates to:
  /// **'English meanings of surah names (used in search)'**
  String get otherMeanings;

  /// No description provided for @otherHeaders.
  ///
  /// In en, this message translates to:
  /// **'The words آياتها, مكية and مدنية in surah headers'**
  String get otherHeaders;

  /// No description provided for @writtenInApp.
  ///
  /// In en, this message translates to:
  /// **'Written in the app'**
  String get writtenInApp;

  /// No description provided for @otherMarkers.
  ///
  /// In en, this message translates to:
  /// **'Ayah markers for the KFGQPC Nastaleeq typeface'**
  String get otherMarkers;

  /// No description provided for @otherMarkersSource.
  ///
  /// In en, this message translates to:
  /// **'Drawn by the app: the font\'s own ayah ornament, with QUL\'s ayah numbers'**
  String get otherMarkersSource;

  /// No description provided for @otherLineFit.
  ///
  /// In en, this message translates to:
  /// **'Text size of each edition'**
  String get otherLineFit;

  /// No description provided for @otherLineFitSource.
  ///
  /// In en, this message translates to:
  /// **'Measured with HarfBuzz from the bundled fonts, so every line fits'**
  String get otherLineFitSource;

  /// No description provided for @srcAppFonts.
  ///
  /// In en, this message translates to:
  /// **'App fonts'**
  String get srcAppFonts;

  /// No description provided for @appFontsSource.
  ///
  /// In en, this message translates to:
  /// **'Google Fonts · SIL Open Font License'**
  String get appFontsSource;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get openLink;

  /// No description provided for @languageStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language for the app\'s menus and buttons.'**
  String get languageStepSubtitle;

  /// No description provided for @languageSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Follow the phone\'s language'**
  String get languageSystemHint;

  /// No description provided for @colourVividness.
  ///
  /// In en, this message translates to:
  /// **'Vividness'**
  String get colourVividness;

  /// No description provided for @hexCode.
  ///
  /// In en, this message translates to:
  /// **'Hex code'**
  String get hexCode;

  /// No description provided for @editionBigTextIndopak.
  ///
  /// In en, this message translates to:
  /// **'Want bigger letters? The 13-line and 9-line editions have larger text, and in the reader you can pinch to zoom or switch to Easy read, which shows the text at any size.'**
  String get editionBigTextIndopak;

  /// No description provided for @editionBigTextMadani.
  ///
  /// In en, this message translates to:
  /// **'Want bigger letters? In the reader you can pinch to zoom, or switch to Easy read, which shows the text at any size.'**
  String get editionBigTextMadani;

  /// No description provided for @displayBigTextIndopak.
  ///
  /// In en, this message translates to:
  /// **'Want bigger text? Pinch the page to zoom, choose Easy read, or pick the 13- or 9-line edition in Settings.'**
  String get displayBigTextIndopak;

  /// No description provided for @displayBigTextMadani.
  ///
  /// In en, this message translates to:
  /// **'Want bigger text? Pinch the page to zoom, or choose Easy read.'**
  String get displayBigTextMadani;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @translationNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get translationNone;

  /// No description provided for @translationAuto.
  ///
  /// In en, this message translates to:
  /// **'Match app language'**
  String get translationAuto;

  /// No description provided for @translationHint.
  ///
  /// In en, this message translates to:
  /// **'Shown when you hold an ayah, and under each ayah in Easy read. The Mushaf page itself stays Quran only.'**
  String get translationHint;

  /// No description provided for @translationBy.
  ///
  /// In en, this message translates to:
  /// **'Translation: {translator}'**
  String translationBy(String translator);

  /// No description provided for @srcTranslations.
  ///
  /// In en, this message translates to:
  /// **'Translations of the meanings'**
  String get srcTranslations;

  /// No description provided for @srcTranslationsNote.
  ///
  /// In en, this message translates to:
  /// **'Shown with the Arabic, never instead of it, exactly as each translator published it (without footnotes).'**
  String get srcTranslationsNote;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get languageUrdu;

  /// No description provided for @translationStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Would you like a translation?'**
  String get translationStepTitle;

  /// No description provided for @translationStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The meaning of each ayah in your language. Press and hold any ayah while reading to see its translation.'**
  String get translationStepSubtitle;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @pagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pagesLabel;

  /// No description provided for @onePage.
  ///
  /// In en, this message translates to:
  /// **'One'**
  String get onePage;

  /// No description provided for @twoPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Two'**
  String get twoPagesLabel;

  /// No description provided for @twoPagesSetting.
  ///
  /// In en, this message translates to:
  /// **'Two pages side by side'**
  String get twoPagesSetting;

  /// No description provided for @twoPagesHint.
  ///
  /// In en, this message translates to:
  /// **'On tablets, computers and phones held sideways, like an open book.'**
  String get twoPagesHint;

  /// No description provided for @onePageTip.
  ///
  /// In en, this message translates to:
  /// **'One page'**
  String get onePageTip;

  /// No description provided for @twoPagesTip.
  ///
  /// In en, this message translates to:
  /// **'Two pages side by side'**
  String get twoPagesTip;

  /// No description provided for @textSizeStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a comfortable text size'**
  String get textSizeStepTitle;

  /// No description provided for @textSizeStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the size you\'d like to read at. You can change it any time while reading.'**
  String get textSizeStepSubtitle;

  /// No description provided for @viewLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewLabel;

  /// No description provided for @printedFollowTheme.
  ///
  /// In en, this message translates to:
  /// **'Printed pages follow the theme'**
  String get printedFollowTheme;

  /// No description provided for @printedFollowThemeHint.
  ///
  /// In en, this message translates to:
  /// **'Printed pages take your paper and text colours. Turn off to see them exactly as printed, in their own colours.'**
  String get printedFollowThemeHint;

  /// No description provided for @remindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindMe;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Time for your reading'**
  String get reminderBody;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @reminderPermissionOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for this app. Allow them in your phone\'s settings to get reminders.'**
  String get reminderPermissionOff;

  /// No description provided for @reminderAt.
  ///
  /// In en, this message translates to:
  /// **'Reminder at {time}'**
  String reminderAt(String time);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareImage.
  ///
  /// In en, this message translates to:
  /// **'Share image'**
  String get shareImage;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'Share text'**
  String get shareText;

  /// No description provided for @saveImage.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get saveImage;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyText;

  /// No description provided for @cardPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get cardPost;

  /// No description provided for @cardStory.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get cardStory;

  /// No description provided for @imageSaved.
  ///
  /// In en, this message translates to:
  /// **'Image saved to {path}'**
  String imageSaved(String path);

  /// No description provided for @wordSpacing.
  ///
  /// In en, this message translates to:
  /// **'Word spacing'**
  String get wordSpacing;

  /// No description provided for @surahTitles.
  ///
  /// In en, this message translates to:
  /// **'Surah titles'**
  String get surahTitles;

  /// No description provided for @verticalScrollSetting.
  ///
  /// In en, this message translates to:
  /// **'Scroll pages vertically'**
  String get verticalScrollSetting;

  /// No description provided for @verticalScrollHint.
  ///
  /// In en, this message translates to:
  /// **'One continuous scroll, top to bottom, instead of turning pages sideways. Pages show one at a time.'**
  String get verticalScrollHint;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @previousAyah.
  ///
  /// In en, this message translates to:
  /// **'Previous ayah'**
  String get previousAyah;

  /// No description provided for @nextAyah.
  ///
  /// In en, this message translates to:
  /// **'Next ayah'**
  String get nextAyah;

  /// No description provided for @stopRecitation.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopRecitation;

  /// No description provided for @recitation.
  ///
  /// In en, this message translates to:
  /// **'Recitation'**
  String get recitation;

  /// No description provided for @reciter.
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get reciter;

  /// No description provided for @repeatAyah.
  ///
  /// In en, this message translates to:
  /// **'Recite each ayah'**
  String get repeatAyah;

  /// No description provided for @recitationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load. Check your connection.'**
  String get recitationFailed;

  /// No description provided for @recitationHint.
  ///
  /// In en, this message translates to:
  /// **'Each reciter\'s own recording, ayah by ayah, from EveryAyah. Ayahs you\'ve heard are kept, so they play again without a connection.'**
  String get recitationHint;

  /// No description provided for @bismillah.
  ///
  /// In en, this message translates to:
  /// **'Bismillah'**
  String get bismillah;

  /// No description provided for @srcRecitationNote.
  ///
  /// In en, this message translates to:
  /// **'One recording per ayah, as each reciter recorded it and EveryAyah publishes it; nothing is cut or joined. The Bismillah before a surah is Al-Fatihah\'s first ayah.'**
  String get srcRecitationNote;

  /// No description provided for @srcTranslationVoices.
  ///
  /// In en, this message translates to:
  /// **'Translations, read aloud'**
  String get srcTranslationVoices;

  /// No description provided for @roundOf.
  ///
  /// In en, this message translates to:
  /// **'{round} of {rounds}'**
  String roundOf(int round, int rounds);

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Your places'**
  String get backup;

  /// No description provided for @exportLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to a file'**
  String get exportLibrary;

  /// No description provided for @exportLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'Your sessions, bookmarks and notes, to keep or open on another device.'**
  String get exportLibraryHint;

  /// No description provided for @importLibrary.
  ///
  /// In en, this message translates to:
  /// **'Open a saved file'**
  String get importLibrary;

  /// No description provided for @importLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'Brings in places saved from Quiet Quran on any device.'**
  String get importLibraryHint;

  /// No description provided for @importConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace your places here?'**
  String get importConfirmTitle;

  /// No description provided for @importConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The sessions, bookmarks and notes on this device will be replaced by the file’s.'**
  String get importConfirmBody;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @imported.
  ///
  /// In en, this message translates to:
  /// **'Brought in {sessions} sessions and {bookmarks} bookmarks.'**
  String imported(int sessions, int bookmarks);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'That isn’t a file saved from Quiet Quran.'**
  String get importFailed;

  /// No description provided for @exported.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get exported;

  /// No description provided for @translationAudioHint.
  ///
  /// In en, this message translates to:
  /// **'When the translation is shown under each ayah, it\'s read aloud after the recitation.'**
  String get translationAudioHint;

  /// No description provided for @switchToDay.
  ///
  /// In en, this message translates to:
  /// **'Switch to Day'**
  String get switchToDay;

  /// No description provided for @switchToNight.
  ///
  /// In en, this message translates to:
  /// **'Switch to Night'**
  String get switchToNight;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all ({count})'**
  String showAll(int count);

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @printedDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download printed pages?'**
  String get printedDownloadTitle;

  /// No description provided for @printedDownloadBody.
  ///
  /// In en, this message translates to:
  /// **'Printed pages are downloaded once, then work fully offline. {pages} pages, about {mb} MB. Wi-Fi is recommended.'**
  String printedDownloadBody(int pages, int mb);

  /// No description provided for @printedDownloadStart.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get printedDownloadStart;

  /// No description provided for @printedDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading printed pages'**
  String get printedDownloading;

  /// No description provided for @printedDownloadStopped.
  ///
  /// In en, this message translates to:
  /// **'Download paused'**
  String get printedDownloadStopped;

  /// No description provided for @printedDownloadProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} pages'**
  String printedDownloadProgress(int done, int total);

  /// No description provided for @printedDownloadKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep the app open until it finishes. Then every page is on your device, and you can read without a connection.'**
  String get printedDownloadKeepOpen;

  /// No description provided for @printedDownloadStoppedHint.
  ///
  /// In en, this message translates to:
  /// **'The connection was lost. Pages already saved are kept: try again to carry on from here.'**
  String get printedDownloadStoppedHint;

  /// No description provided for @pageNotSaved.
  ///
  /// In en, this message translates to:
  /// **'This page isn\'t saved'**
  String get pageNotSaved;

  /// No description provided for @pageNotSavedDetail.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of this printed set isn\'t on this device. Download the set again to read it.'**
  String pageNotSavedDetail(int page);

  /// No description provided for @downloadPrinted.
  ///
  /// In en, this message translates to:
  /// **'Download printed pages'**
  String get downloadPrinted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
