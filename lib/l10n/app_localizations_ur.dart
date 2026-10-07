// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'Quiet Quran';

  @override
  String get back => 'واپس';

  @override
  String get settings => 'ترتیبات';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get continueLabel => 'آگے';

  @override
  String get startReading => 'پڑھنا شروع کریں';

  @override
  String get changeLater => 'آپ اسے کسی بھی وقت ترتیبات میں بدل سکتے ہیں۔';

  @override
  String get scriptTitle => 'آپ کون سا رسم الخط پڑھتے ہیں؟';

  @override
  String get scriptSubtitle =>
      'وہ مصحف منتخب کریں جس سے آپ نے پڑھنا سیکھا۔ اگلے مرحلے میں آپ اس کا مخصوص نسخہ چن سکیں گے۔';

  @override
  String get indopakTitle => 'انڈو پاک (نستعلیق)';

  @override
  String get indopakTagline =>
      'پاکستان، بھارت، بنگلہ دیش اور جنوبی افریقہ میں رائج';

  @override
  String get madaniTitle => 'مدنی (عثمانی)';

  @override
  String get madaniTagline =>
      'شاہ فہد کمپلیکس کا مصحف، جو عرب دنیا میں رائج ہے';

  @override
  String get scriptIndopak => 'انڈو پاک';

  @override
  String get scriptMadani => 'مدنی';

  @override
  String get modeTitle => 'آپ کیسے پڑھنا چاہیں گے؟';

  @override
  String modeSubtitle(String script) {
    return 'قرآن کو قرآنی خطوط میں لکھے ہوئے متن کی صورت میں پڑھیں، یا چھپے ہوئے $script مصحف کی تصاویر کی صورت میں۔';
  }

  @override
  String get modeText => 'متن';

  @override
  String get modeTextTagline =>
      'قابلِ تبدیل سائز، تھیم کے مطابق، اور ہر ریزولوشن پر صاف';

  @override
  String get modeTextCaption => 'آپ کے مصحف کی ہوبہو سطریں، متن کی صورت میں';

  @override
  String get modeTextPoint1 =>
      'حروف کا سائز قابلِ تبدیل، بڑے حروف کے لیے آسان مطالعہ کے منظر کے ساتھ';

  @override
  String get modeTextPoint2 => 'آنکھوں کو آرام دینے والے ہلکے اور گہرے رنگ';

  @override
  String get modeTextPoint3 => 'ہر سائز پر واضح، ٹیبلٹ اور کمپیوٹر سمیت';

  @override
  String get modeTextPoint4 => 'ایپ میں شامل: کچھ ڈاؤن لوڈ کرنے کی ضرورت نہیں';

  @override
  String get modePages => 'چھپے ہوئے صفحات';

  @override
  String get modePagesTagline => 'اصل چھپے ہوئے مصحف کے صفحات';

  @override
  String get modePagesCaption => 'صفحہ بالکل ویسا ہی جیسا چھپا ہے';

  @override
  String get modePagesPoint1 => 'بالکل اسی مصحف جیسا جس کے آپ عادی ہیں';

  @override
  String get modePagesPoint2 =>
      'صفحات کی وہ بصری یادداشت برقرار رہتی ہے جس پر حفظ کا انحصار ہے';

  @override
  String get modePagesPoint3 => 'زوم کے لیے دو انگلیوں سے پھیلائیں';

  @override
  String get modePagesFootnote =>
      'صفحات پڑھتے وقت ڈاؤن لوڈ ہوتے ہیں، یا آف لائن استعمال کے لیے پورا نسخہ ترتیبات میں محفوظ کر لیں۔';

  @override
  String get editionTitle => 'آپ کس مصحف سے پڑھتے ہیں؟';

  @override
  String get editionSubtitleText =>
      'وہ نسخہ منتخب کریں جس سے آپ نے سیکھا۔ ہر سطر اور صفحہ اسی نسخے کے مطابق ہوگا۔';

  @override
  String get editionSubtitlePages =>
      'وہ چھپا ہوا نسخہ منتخب کریں جس سے آپ سب سے زیادہ مانوس ہیں۔';

  @override
  String editionDetailText(int lines, int pages) {
    return 'فی صفحہ $lines سطریں · $pages صفحات';
  }

  @override
  String editionDetailPages(String description, int mb) {
    return '$description پورا نسخہ محفوظ کرنے کے لیے تقریباً $mb MB۔';
  }

  @override
  String get dailyReading => 'روزانہ کی تلاوت';

  @override
  String get otherSessions => 'دیگر معمولات';

  @override
  String get newLabel => 'نیا';

  @override
  String get sessionsHint =>
      'دوسری تلاوتوں کے لیے الگ مقامات رکھیں — جمعہ کو سورۃ الکہف، رات کو سورۃ الملک — روزانہ کے صفحے کو کھوئے بغیر۔';

  @override
  String get browse => 'فہرست';

  @override
  String get surahs => 'سورتیں';

  @override
  String get juz => 'پارے';

  @override
  String get bookmarks => 'بک مارکس';

  @override
  String get searchHint => 'سورت تلاش کریں — نام یا نمبر';

  @override
  String noSurahMatches(String query) {
    return '\"$query\" سے کوئی سورت نہیں ملی۔';
  }

  @override
  String opensAtStart(int page) {
    return 'شروع سے کھلتا ہے · صفحہ $page';
  }

  @override
  String pageJuz(int page, int juz) {
    return 'صفحہ $page · پارہ $juz';
  }

  @override
  String get open => 'کھولیں';

  @override
  String get resume => 'جاری رکھیں';

  @override
  String get sessionStart => 'آغاز';

  @override
  String pageShort(int page) {
    return 'ص $page';
  }

  @override
  String versesPage(int count, int page) {
    return '$count آیات · ص $page';
  }

  @override
  String juzN(int n) {
    return 'پارہ $n';
  }

  @override
  String surahN(int n) {
    return 'سورت $n';
  }

  @override
  String get noBookmarks => 'ابھی کوئی بک مارک نہیں';

  @override
  String get noBookmarksHint =>
      'کسی صفحے یا آیت کو بک مارک کریں تاکہ اسے یہاں دوبارہ پا سکیں۔';

  @override
  String get editSession => 'معمول میں ترمیم';

  @override
  String get name => 'نام';

  @override
  String get eachTimeOpen => 'ہر بار کھولنے پر';

  @override
  String get startOfSurah => 'سورت کا آغاز';

  @override
  String get deleteSession => 'معمول حذف کریں';

  @override
  String tapAgainDelete(String name) {
    return '\"$name\" حذف کرنے کے لیے دوبارہ دبائیں';
  }

  @override
  String get note => 'نوٹ';

  @override
  String get optional => 'اختیاری';

  @override
  String get removeBookmark => 'بک مارک ہٹائیں';

  @override
  String get newSession => 'نیا معمول';

  @override
  String get newSessionHint => 'واپس آنے کی ایک جگہ، روزانہ کی تلاوت سے الگ۔';

  @override
  String get nameExample => 'مثلاً رات · سورۃ الملک';

  @override
  String get startsAt => 'آغاز';

  @override
  String get createSession => 'معمول بنائیں';

  @override
  String get browsing => 'سرسری مطالعہ';

  @override
  String continueFromHere(String name) {
    return '$name یہاں سے جاری رکھیں';
  }

  @override
  String movesTo(String name, String place) {
    return '$name کو $place پر منتقل کرتا ہے';
  }

  @override
  String get saveAsNew => 'نئے معمول کے طور پر محفوظ کریں';

  @override
  String get saveAsNewHint => 'اسے نام دیں، اور ہوم سے اس پر واپس آئیں';

  @override
  String get backToHome => 'ہوم پر واپس';

  @override
  String get saveAsSession => 'اس مقام کو معمول کے طور پر محفوظ کریں';

  @override
  String get bookmarkPage => 'اس صفحے کو بک مارک کریں';

  @override
  String readerMeta(int juz, String pages, int total) {
    return 'پارہ $juz · $pages از $total';
  }

  @override
  String get displayTooltip =>
      'فوری ترتیبات: منظر، حروف کا سائز، ترجمہ اور تھیم';

  @override
  String get showTranslation => 'ترجمہ دکھائیں';

  @override
  String get hideTranslation => 'ترجمہ چھپائیں';

  @override
  String pageOf(int page, int total) {
    return 'صفحہ $page از $total';
  }

  @override
  String scrubberLabel(String unit, int current, int count) {
    return '$unit $current از $count۔ جانے کے لیے کھینچیں۔';
  }

  @override
  String get surah => 'سورت';

  @override
  String runningHeadJuz(int juz) {
    return 'پارہ $juz';
  }

  @override
  String get display => 'منظر';

  @override
  String get readAs => 'پڑھنے کا طریقہ';

  @override
  String get printed => 'چھپا ہوا';

  @override
  String get layout => 'ترتیب';

  @override
  String get mushafPage => 'مصحف کا صفحہ';

  @override
  String get reflow => 'آسان مطالعہ';

  @override
  String get textSize => 'حروف کا سائز';

  @override
  String get bookmark => 'بک مارک';

  @override
  String get bookmarked => 'بک مارک شدہ';

  @override
  String get copy => 'کاپی';

  @override
  String copied(String reference) {
    return '$reference کاپی ہو گئی';
  }

  @override
  String get offline => 'آپ آف لائن ہیں';

  @override
  String get pageFailed => 'یہ صفحہ لوڈ نہیں ہوا';

  @override
  String offlineDetail(int page) {
    return 'صفحہ $page ابھی اس ڈیوائس پر محفوظ نہیں۔ انٹرنیٹ سے جڑیں، یا آف لائن پڑھنے کے لیے پورا نسخہ ترتیبات میں محفوظ کریں۔';
  }

  @override
  String failedDetail(int page) {
    return 'صفحہ $page لاتے ہوئے کچھ غلط ہو گیا۔';
  }

  @override
  String get tryAgain => 'دوبارہ کوشش کریں';

  @override
  String pageN(int page) {
    return 'صفحہ $page';
  }

  @override
  String get loadingPage => 'چھپا ہوا صفحہ لوڈ ہو رہا ہے…';

  @override
  String get appearance => 'رنگ و روپ';

  @override
  String get mushaf => 'مصحف';

  @override
  String get edition => 'نسخہ';

  @override
  String get typeface => 'خط';

  @override
  String get textLayout => 'متن کی ترتیب';

  @override
  String get reflowTextSize => 'آسان مطالعہ میں حروف کا سائز';

  @override
  String get reader => 'ریڈر';

  @override
  String get scrubberHint => 'ریڈر کے نیچے والی پٹی اس حساب سے آگے بڑھتی ہے';

  @override
  String get offlinePages => 'آف لائن استعمال کے لیے چھپے صفحات';

  @override
  String get about => 'تعارف';

  @override
  String get aboutText =>
      'مفت اور اوپن سورس، بغیر اشتہارات، بغیر ٹریکنگ اور بغیر اکاؤنٹ کے۔';

  @override
  String linesPages(int lines, int pages) {
    return '$lines سطریں · $pages صفحات';
  }

  @override
  String get system => 'سسٹم';

  @override
  String get custom => 'اپنی مرضی';

  @override
  String swatchLabel(String label) {
    return '$label رنگ';
  }

  @override
  String downloadStopped(String error) {
    return 'ڈاؤن لوڈ رک گیا: $error';
  }

  @override
  String downloadProgress(int cached, int total, int mb) {
    return '$total میں سے $cached صفحات · تقریباً $mb MB';
  }

  @override
  String get pause => 'روکیں';

  @override
  String get downloadAll => 'سب ڈاؤن لوڈ کریں';

  @override
  String get deleteSaved => 'محفوظ صفحات حذف کریں';

  @override
  String get language => 'زبان';

  @override
  String get languageSystem => 'سسٹم';

  @override
  String get languageHint => 'ایپ کی زبان۔';

  @override
  String get paletteNight => 'رات';

  @override
  String get paletteDay => 'دن';

  @override
  String get paletteSepia => 'سیپیا';

  @override
  String get paletteGreen => 'سبز';

  @override
  String get paletteContrast => 'زیادہ تضاد';

  @override
  String get typefaceIndopak => 'انڈو پاک نستعلیق';

  @override
  String get typefaceIndopakDesc => 'برصغیر کا روایتی انداز';

  @override
  String get typefaceQpcNastaleeq => 'شاہ فہد کمپلیکس نستعلیق';

  @override
  String get typefaceQpcNastaleeqDesc => 'شاہ فہد کمپلیکس کا انڈو پاک انداز';

  @override
  String get typefaceQpcHafs => 'شاہ فہد کمپلیکس حفص';

  @override
  String get typefaceQpcHafsDesc => 'شاہ فہد کمپلیکس کا عثمانی رسم الخط';

  @override
  String get customColours => 'اپنی مرضی کے رنگ';

  @override
  String contrastGood(String ratio) {
    return 'تضاد $ratio:1 — پڑھنے میں آسان۔';
  }

  @override
  String contrastBad(String ratio) {
    return 'تضاد $ratio:1 — متن پڑھنا مشکل ہو سکتا ہے۔ 4.5:1 یا زیادہ تجویز کیا جاتا ہے۔';
  }

  @override
  String get background => 'پس منظر';

  @override
  String get textColour => 'متن';

  @override
  String get accent => 'نمایاں رنگ';

  @override
  String get suggestions => 'تجاویز';

  @override
  String get suggestedColour => 'تجویز کردہ رنگ';

  @override
  String get editionIndopak15Qudratullah => '15 سطری · قدرت اللہ';

  @override
  String get editionIndopak16Taj => '16 سطری · تاج کمپنی';

  @override
  String get editionIndopak13Qudratullah => '13 سطری · قدرت اللہ';

  @override
  String get editionIndopak13Taj => '13 سطری · تاج کمپنی';

  @override
  String get editionIndopak9Gaba => '9 سطری · گابا (جلی حروف)';

  @override
  String get editionMadani1405 => '1405ھ · شاہ فہد کمپلیکس V1';

  @override
  String get editionMadani1421 => '1421ھ · شاہ فہد کمپلیکس V2';

  @override
  String get imageIndopak15Plain => '15 سطری · شاہ فہد کمپلیکس';

  @override
  String get imageIndopak15PlainDesc =>
      'شاہ فہد کمپلیکس کا 15 سطری انڈوپاک مصحف (610 صفحات)۔';

  @override
  String get imageIndopak16Taj => '16 سطری · تاج کمپنی';

  @override
  String get imageIndopak16TajDesc =>
      'تاج کمپنی کے 16 سطری نسخے کا اسکین (548 صفحات)۔';

  @override
  String get imageIndopak13Qudratullah => '13 سطری · قدرت اللہ';

  @override
  String get imageIndopak13QudratullahDesc =>
      'قدرت اللہ کمپنی کے 13 سطری نسخے کا اسکین (849 صفحات)۔';

  @override
  String get imageIndopak15Colour => '15 سطری · رنگین تجوید';

  @override
  String get imageIndopak15ColourDesc =>
      'ہر صفحے پر تجوید کے قواعد رنگوں میں (610 صفحات)۔';

  @override
  String get imageMadani15 => '15 سطری · شاہ فہد کمپلیکس';

  @override
  String get imageMadani15Desc =>
      'شاہ فہد کمپلیکس کا مدنی مصحف، ممتاز طباعت (604 صفحات)۔';

  @override
  String get sources => 'ماخذ';

  @override
  String get sourcesHint =>
      'قرآن کا متن، ترتیب، خطوط اور صفحات کی تصاویر کہاں سے لی گئی ہیں';

  @override
  String get sourcesIntro =>
      'اس ایپ میں قرآن کا ہر لفظ، مصحف کی ہر ترتیب اور قرآن سے متعلق تمام معلومات QUL (Quranic Universal Library، از Tarteel AI) سے لی گئی ہیں، جو تصحیح شدہ مواد شائع کرتی ہے۔ متن بالکل ویسا ہی استعمال ہوا ہے جیسا شائع ہوا، سوائے الفاظ کے کناروں پر زائد خالی جگہ ہٹانے کے۔';

  @override
  String get srcText => 'قرآن کا متن، لفظ بہ لفظ';

  @override
  String get srcLayouts => 'مصحف کی ترتیب';

  @override
  String get srcLayoutsNote =>
      'ہر چھپے نسخے میں ہر صفحے کی ہر سطر پر کون سے الفاظ ہیں۔';

  @override
  String get srcFonts => 'قرآنی خطوط';

  @override
  String get srcMetadata => 'قرآن سے متعلق معلومات';

  @override
  String get metaSurahs => 'سورتوں کے نام، مقامِ نزول اور آیات کی تعداد';

  @override
  String get metaAyahs => 'آیات کی فہرست';

  @override
  String get metaJuz => 'پارے';

  @override
  String get metaHizb => 'حزب';

  @override
  String get metaRub => 'ربع الحزب';

  @override
  String get metaManzil => 'منزلیں';

  @override
  String get metaRuku => 'رکوع';

  @override
  String get metaSajda => 'سجدۂ تلاوت کے مقامات';

  @override
  String get srcPrinted => 'چھپے صفحات کی تصاویر';

  @override
  String get srcPrintedNote =>
      'شاہ فہد کمپلیکس کے اپنے مصحف کے صفحات، اس کی فائلوں سے بغیر کسی تبدیلی کے، لہٰذا ان کی صحت اصل طباعت پر منحصر ہے۔ یہ پڑھتے وقت ہماری اپنی ہوسٹنگ سے ڈاؤن لوڈ ہوتے ہیں۔';

  @override
  String imageThanks(String name) {
    return '$name کا شکریہ، جن کے صفحات کے مجموعے کے ذریعے ہمیں یہ اصل نسخہ ملا۔';
  }

  @override
  String get srcOther => 'جو قرآن کا متن نہیں';

  @override
  String get srcOtherNote =>
      'یہ حصے QUL کے علاوہ بنائے یا لیے گئے ہیں۔ ان میں سے کوئی بھی قرآن کا متن نہیں۔';

  @override
  String get otherMeanings =>
      'سورتوں کے ناموں کے انگریزی معانی (تلاش میں استعمال)';

  @override
  String get otherHeaders =>
      'سورت کے عنوان میں آياتها، مكية اور مدنية کے الفاظ';

  @override
  String get writtenInApp => 'ایپ میں لکھے گئے';

  @override
  String get otherMarkers => 'شاہ فہد کمپلیکس نستعلیق خط کے لیے آیت کے نشانات';

  @override
  String get otherMarkersSource =>
      'ایپ خود بناتی ہے: خط کا اپنا آیت کا نشان، QUL کے آیت نمبروں کے ساتھ';

  @override
  String get otherLineFit => 'ہر نسخے کے حروف کا سائز';

  @override
  String get otherLineFitSource =>
      'شامل خطوط سے HarfBuzz کے ذریعے ناپا گیا، تاکہ ہر سطر پوری آئے';

  @override
  String get srcAppFonts => 'ایپ کے خطوط';

  @override
  String get appFontsSource => 'Google Fonts · SIL Open Font License';

  @override
  String get openLink => 'لنک کھولیں';

  @override
  String get languageStepSubtitle =>
      'ایپ کے مینو اور بٹنوں کی زبان منتخب کریں۔';

  @override
  String get languageSystemHint => 'فون کی زبان کے مطابق';

  @override
  String get colourVividness => 'رنگ کی شدت';

  @override
  String get hexCode => 'ہیکس کوڈ';

  @override
  String get editionBigTextIndopak =>
      'بڑے حروف چاہییں؟ 13 سطری اور 9 سطری نسخوں کے حروف بڑے ہیں، اور ریڈر میں آپ دو انگلیوں سے زوم کر سکتے ہیں یا آسان مطالعہ منتخب کر سکتے ہیں، جس میں متن کسی بھی سائز میں دکھتا ہے۔';

  @override
  String get editionBigTextMadani =>
      'بڑے حروف چاہییں؟ ریڈر میں آپ دو انگلیوں سے زوم کر سکتے ہیں، یا آسان مطالعہ منتخب کر سکتے ہیں، جس میں متن کسی بھی سائز میں دکھتا ہے۔';

  @override
  String get displayBigTextIndopak =>
      'بڑا متن چاہیے؟ صفحے کو دو انگلیوں سے زوم کریں، آسان مطالعہ منتخب کریں، یا ترتیبات میں 13 یا 9 سطری نسخہ چنیں۔';

  @override
  String get displayBigTextMadani =>
      'بڑا متن چاہیے؟ صفحے کو دو انگلیوں سے زوم کریں، یا آسان مطالعہ منتخب کریں۔';

  @override
  String get translation => 'ترجمہ';

  @override
  String get translationNone => 'کوئی نہیں';

  @override
  String get translationAuto => 'ایپ کی زبان کے مطابق';

  @override
  String get translationHint =>
      'کسی آیت کو دبا کر رکھنے پر، اور آسان مطالعہ میں ہر آیت کے نیچے دکھایا جاتا ہے۔ مصحف کا صفحہ صرف قرآن رہتا ہے۔';

  @override
  String translationBy(String translator) {
    return 'ترجمہ: $translator';
  }

  @override
  String get srcTranslations => 'معانی کے تراجم';

  @override
  String get srcTranslationsNote =>
      'عربی متن کے ساتھ دکھائے جاتے ہیں، کبھی اس کی جگہ نہیں، بالکل ویسے جیسے ہر مترجم نے شائع کیے (حواشی کے بغیر)۔';

  @override
  String get languageEnglish => 'انگریزی';

  @override
  String get languageUrdu => 'اردو';

  @override
  String get translationStepTitle => 'کیا آپ ترجمہ چاہیں گے؟';

  @override
  String get translationStepSubtitle =>
      'ہر آیت کا مطلب آپ کی زبان میں۔ پڑھتے وقت کسی بھی آیت کو دبا کر رکھیں تو اس کا ترجمہ نظر آئے گا۔';

  @override
  String get theme => 'تھیم';

  @override
  String get themeAuto => 'خودکار';

  @override
  String get pagesLabel => 'صفحات';

  @override
  String get onePage => 'ایک';

  @override
  String get twoPagesLabel => 'دو';

  @override
  String get twoPagesSetting => 'دو صفحے ساتھ ساتھ';

  @override
  String get twoPagesHint =>
      'ٹیبلٹ، کمپیوٹر اور افقی رکھے فون پر، کھلی کتاب کی طرح۔';

  @override
  String get onePageTip => 'ایک صفحہ';

  @override
  String get twoPagesTip => 'دو صفحے ساتھ ساتھ';

  @override
  String get textSizeStepTitle => 'پڑھنے کے لیے آرام دہ سائز منتخب کریں';

  @override
  String get textSizeStepSubtitle =>
      'وہ سائز منتخب کریں جس میں آپ پڑھنا چاہیں۔ پڑھتے وقت اسے کبھی بھی بدلا جا سکتا ہے۔';

  @override
  String get viewLabel => 'انداز';

  @override
  String get printedFollowTheme => 'چھپے صفحات تھیم کے مطابق';

  @override
  String get printedFollowThemeHint =>
      'چھپے صفحات آپ کے منتخب رنگ اپناتے ہیں۔ بند کریں تو وہ بالکل چھپے ہوئے کی طرح، اپنے اصل رنگوں میں دکھیں گے۔';

  @override
  String get remindMe => 'یاد دہانی';

  @override
  String get reminderBody => 'آپ کی تلاوت کا وقت';

  @override
  String get everyDay => 'ہر روز';

  @override
  String get reminderPermissionOff =>
      'اس ایپ کے لیے اطلاعات بند ہیں۔ یاد دہانیوں کے لیے فون کی ترتیبات میں انہیں اجازت دیں۔';

  @override
  String reminderAt(String time) {
    return 'یاد دہانی $time بجے';
  }

  @override
  String get share => 'شیئر کریں';

  @override
  String get shareImage => 'تصویر شیئر کریں';

  @override
  String get shareText => 'متن شیئر کریں';

  @override
  String get saveImage => 'تصویر محفوظ کریں';

  @override
  String get copyText => 'متن کاپی کریں';

  @override
  String get cardPost => 'پوسٹ';

  @override
  String get cardStory => 'اسٹوری';

  @override
  String imageSaved(String path) {
    return 'تصویر یہاں محفوظ ہو گئی: $path';
  }

  @override
  String get wordSpacing => 'الفاظ کا درمیانی فاصلہ';

  @override
  String get surahTitles => 'سورتوں کے نام (عنوان)';

  @override
  String get verticalScrollSetting => 'صفحے عمودی طور پر اسکرول کریں';

  @override
  String get verticalScrollHint =>
      'صفحے پلٹنے کے بجائے اوپر سے نیچے ایک مسلسل اسکرول۔ صفحے ایک ایک کر کے دکھتے ہیں۔';

  @override
  String get listen => 'سنیں';

  @override
  String get previousAyah => 'پچھلی آیت';

  @override
  String get nextAyah => 'اگلی آیت';

  @override
  String get stopRecitation => 'بند کریں';

  @override
  String get recitation => 'تلاوت';

  @override
  String get reciter => 'قاری';

  @override
  String get repeatAyah => 'ہر آیت کی تلاوت';

  @override
  String get recitationFailed => 'لوڈ نہیں ہو سکا۔ کنکشن دیکھیں۔';

  @override
  String get recitationHint =>
      'ہر قاری کی اپنی ریکارڈنگ، آیت بہ آیت، EveryAyah سے۔ سنی ہوئی آیات محفوظ رہتی ہیں، اس لیے انٹرنیٹ کے بغیر بھی دوبارہ سنی جا سکتی ہیں۔';

  @override
  String get bismillah => 'بسم اللہ';

  @override
  String get srcRecitationNote =>
      'ہر آیت کی ایک ریکارڈنگ، جیسے قاری نے پڑھی اور EveryAyah نے شائع کی؛ کچھ کاٹا یا جوڑا نہیں جاتا۔ سورت سے پہلے کی بسم اللہ سورۃ الفاتحہ کی پہلی آیت ہے۔';

  @override
  String get srcTranslationVoices => 'ترجمے، آواز میں';

  @override
  String roundOf(int round, int rounds) {
    return '$rounds میں سے $round';
  }

  @override
  String get backup => 'آپ کے مقامات';

  @override
  String get exportLibrary => 'فائل میں محفوظ کریں';

  @override
  String get exportLibraryHint =>
      'آپ کے سیشن، بک مارک اور نوٹس، محفوظ رکھنے یا کسی اور ڈیوائس پر کھولنے کے لیے۔';

  @override
  String get importLibrary => 'محفوظ فائل کھولیں';

  @override
  String get importLibraryHint =>
      'کسی بھی ڈیوائس پر Quiet Quran سے محفوظ کیے گئے مقامات لے آئیں۔';

  @override
  String get importConfirmTitle => 'یہاں کے مقامات بدل دیں؟';

  @override
  String get importConfirmBody =>
      'اس ڈیوائس کے سیشن، بک مارک اور نوٹس فائل والے سے بدل دیے جائیں گے۔';

  @override
  String get replace => 'بدل دیں';

  @override
  String imported(int sessions, int bookmarks) {
    return '$sessions سیشن اور $bookmarks بک مارک آ گئے۔';
  }

  @override
  String get importFailed => 'یہ Quiet Quran سے محفوظ کی گئی فائل نہیں ہے۔';

  @override
  String get exported => 'محفوظ ہو گیا۔';

  @override
  String get translationAudioHint =>
      'جب ہر آیت کے نیچے ترجمہ دکھایا جائے تو تلاوت کے بعد وہ بھی پڑھ کر سنایا جاتا ہے۔';

  @override
  String get switchToDay => 'دن کے رنگ';

  @override
  String get switchToNight => 'رات کے رنگ';

  @override
  String showAll(int count) {
    return 'سب دکھائیں ($count)';
  }

  @override
  String get showLess => 'کم دکھائیں';
}
