// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Quiet Quran';

  @override
  String get back => 'رجوع';

  @override
  String get settings => 'الإعدادات';

  @override
  String get save => 'حفظ';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get startReading => 'ابدأ القراءة';

  @override
  String get changeLater => 'يمكنك تغيير هذا في أي وقت من الإعدادات.';

  @override
  String get scriptTitle => 'بأي رسم تقرأ؟';

  @override
  String get scriptSubtitle =>
      'اختر نوع المصحف الذي تعلّمت منه. الطبعات الأخرى في الإعدادات.';

  @override
  String get indopakTitle => 'الهندي الباكستاني (نستعليق)';

  @override
  String get indopakTagline =>
      'منتشر في باكستان والهند وبنغلاديش وجنوب أفريقيا';

  @override
  String get madaniTitle => 'المدني (العثماني)';

  @override
  String get madaniTagline => 'مصحف مجمع الملك فهد، المعتمد في العالم العربي';

  @override
  String get scriptIndopak => 'الهندي';

  @override
  String get scriptMadani => 'المدني';

  @override
  String get modeTitle => 'كيف تحب أن تقرأ؟';

  @override
  String modeSubtitle(String script) {
    return 'اقرأ القرآن نصًّا مرسومًا بخطوط قرآنية، أو صورًا لمصحف $script مطبوع.';
  }

  @override
  String get modeText => 'نص';

  @override
  String get modeTextTagline => 'حجم قابل للتعديل، يتبع السمة، وواضح بأي دقة';

  @override
  String get modeTextCaption => 'أسطر مصحفك نفسها، مرسومة نصًّا';

  @override
  String get modeTextPoint1 => 'حجم خط قابل للتعديل، مع قراءة ميسّرة بخط كبير';

  @override
  String get modeTextPoint2 => 'سمات فاتحة وداكنة مريحة للعين';

  @override
  String get modeTextPoint3 =>
      'واضح بأي حجم، على الأجهزة اللوحية والحاسوب أيضًا';

  @override
  String get modeTextPoint4 => 'مضمَّن في التطبيق: لا حاجة لأي تنزيل';

  @override
  String get modePages => 'صفحات مطبوعة';

  @override
  String get modePagesTagline => 'صفحات مصحف مطبوع حقيقي';

  @override
  String get modePagesCaption => 'الصفحة كما طُبعت تمامًا';

  @override
  String get modePagesPoint1 => 'تمامًا كالمصحف الذي اعتدت عليه';

  @override
  String get modePagesPoint2 =>
      'يحفظ الذاكرة البصرية للصفحة التي يعتمد عليها الحفظ';

  @override
  String get modePagesPoint3 => 'قرّب بإصبعين للتكبير';

  @override
  String get editionTitle => 'من أي مصحف تقرأ؟';

  @override
  String get editionSubtitleText =>
      'اختر الطبعة التي تعلّمت منها. كل سطر وصفحة يتبعان تلك الطبعة.';

  @override
  String get editionSubtitlePages => 'اختر الطبعة المطبوعة التي تعرفها أكثر.';

  @override
  String editionDetailText(int lines, int pages) {
    return '$lines سطرًا في الصفحة · $pages صفحة';
  }

  @override
  String editionDetailPages(String description, int mb) {
    return '$description نحو $mb ميغابايت لحفظ الطبعة كاملة.';
  }

  @override
  String get dailyReading => 'الورد اليومي';

  @override
  String get otherSessions => 'أوراد أخرى';

  @override
  String get newLabel => 'جديد';

  @override
  String get sessionsHint =>
      'احتفظ بمواضع منفصلة لقراءات أخرى — الكهف يوم الجمعة، والملك في الليل — دون أن تفقد موضع وردك اليومي.';

  @override
  String get browse => 'تصفّح';

  @override
  String get surahs => 'السور';

  @override
  String get juz => 'الأجزاء';

  @override
  String get bookmarks => 'العلامات';

  @override
  String get searchHint => 'ابحث عن سورة — بالاسم أو الرقم';

  @override
  String noSurahMatches(String query) {
    return 'لا توجد سورة تطابق \"$query\".';
  }

  @override
  String opensAtStart(int page) {
    return 'تُفتح من البداية · صفحة $page';
  }

  @override
  String pageJuz(int page, int juz) {
    return 'صفحة $page · الجزء $juz';
  }

  @override
  String get open => 'افتح';

  @override
  String get resume => 'تابع';

  @override
  String get sessionStart => 'البداية';

  @override
  String pageShort(int page) {
    return 'ص $page';
  }

  @override
  String versesPage(int count, int page) {
    return '$count آية · ص $page';
  }

  @override
  String juzN(int n) {
    return 'الجزء $n';
  }

  @override
  String surahN(int n) {
    return 'سورة $n';
  }

  @override
  String get noBookmarks => 'لا توجد علامات بعد';

  @override
  String get noBookmarksHint => 'ضع علامة على صفحة أو آية لتجدها هنا مرة أخرى.';

  @override
  String get editSession => 'تعديل الورد';

  @override
  String get name => 'الاسم';

  @override
  String get eachTimeOpen => 'في كل مرة تفتحه';

  @override
  String get startOfSurah => 'بداية السورة';

  @override
  String get deleteSession => 'حذف الورد';

  @override
  String tapAgainDelete(String name) {
    return 'اضغط مرة أخرى لحذف \"$name\"';
  }

  @override
  String get note => 'ملاحظة';

  @override
  String get optional => 'اختياري';

  @override
  String get removeBookmark => 'إزالة العلامة';

  @override
  String get newSession => 'ورد جديد';

  @override
  String get newSessionHint => 'موضع تعود إليه، منفصل عن وردك اليومي.';

  @override
  String get nameExample => 'مثلًا: الليل · الملك';

  @override
  String get startsAt => 'يبدأ من';

  @override
  String get createSession => 'إنشاء الورد';

  @override
  String get browsing => 'تصفّح حر';

  @override
  String continueFromHere(String name) {
    return 'تابع $name من هنا';
  }

  @override
  String movesTo(String name, String place) {
    return 'ينقل $name إلى $place';
  }

  @override
  String get saveAsNew => 'احفظ كورد جديد';

  @override
  String get saveAsNewHint => 'سمِّه، وعُد إليه من الصفحة الرئيسية';

  @override
  String get backToHome => 'العودة إلى الرئيسية';

  @override
  String get saveAsSession => 'احفظ هذا الموضع كورد';

  @override
  String get bookmarkPage => 'ضع علامة على هذه الصفحة';

  @override
  String readerMeta(int juz, String pages, int total) {
    return 'الجزء $juz · $pages من $total';
  }

  @override
  String get displayTooltip =>
      'إعدادات سريعة: العرض وحجم الخط والترجمة والمظهر';

  @override
  String get showTranslation => 'إظهار الترجمة';

  @override
  String get hideTranslation => 'إخفاء الترجمة';

  @override
  String pageOf(int page, int total) {
    return 'صفحة $page من $total';
  }

  @override
  String scrubberLabel(String unit, int current, int count) {
    return '$unit $current من $count. اسحب للانتقال.';
  }

  @override
  String get surah => 'سورة';

  @override
  String runningHeadJuz(int juz) {
    return 'الجزء $juz';
  }

  @override
  String get display => 'العرض';

  @override
  String get readAs => 'القراءة';

  @override
  String get printed => 'مطبوع';

  @override
  String get layout => 'التخطيط';

  @override
  String get mushafPage => 'صفحة المصحف';

  @override
  String get reflow => 'قراءة ميسّرة';

  @override
  String get textSize => 'حجم الخط';

  @override
  String get bookmark => 'علامة';

  @override
  String get bookmarked => 'عليها علامة';

  @override
  String get copy => 'نسخ';

  @override
  String copied(String reference) {
    return 'تم نسخ $reference';
  }

  @override
  String get offline => 'أنت غير متصل';

  @override
  String get pageFailed => 'لم تُحمَّل هذه الصفحة';

  @override
  String offlineDetail(int page) {
    return 'لم تُحفظ الصفحة $page على هذا الجهاز بعد. اتصل بالإنترنت، أو احفظ الطبعة كاملة من الإعدادات للقراءة دون اتصال.';
  }

  @override
  String failedDetail(int page) {
    return 'حدث خطأ أثناء جلب الصفحة $page.';
  }

  @override
  String get tryAgain => 'أعد المحاولة';

  @override
  String pageN(int page) {
    return 'صفحة $page';
  }

  @override
  String get loadingPage => 'جارٍ تحميل الصفحة المطبوعة…';

  @override
  String get appearance => 'المظهر';

  @override
  String get mushaf => 'المصحف';

  @override
  String get edition => 'الطبعة';

  @override
  String get typeface => 'الخط';

  @override
  String get textLayout => 'تخطيط النص';

  @override
  String get reflowTextSize => 'حجم خط القراءة الميسّرة';

  @override
  String get reader => 'القارئ';

  @override
  String get scrubberHint => 'الشريط أسفل القارئ ينتقل حسب';

  @override
  String get offlinePages => 'صفحات مطبوعة للقراءة دون اتصال';

  @override
  String get about => 'حول التطبيق';

  @override
  String get aboutText =>
      'مجاني ومفتوح المصدر، بلا إعلانات ولا تتبّع ولا حسابات.';

  @override
  String linesPages(int lines, int pages) {
    return '$lines سطرًا · $pages صفحة';
  }

  @override
  String get system => 'النظام';

  @override
  String get custom => 'مخصص';

  @override
  String swatchLabel(String label) {
    return 'ألوان $label';
  }

  @override
  String downloadStopped(String error) {
    return 'توقف التنزيل: $error';
  }

  @override
  String downloadProgress(int cached, int total, int mb) {
    return '$cached من $total صفحة · نحو $mb ميغابايت';
  }

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get downloadAll => 'تنزيل الكل';

  @override
  String get deleteSaved => 'حذف الصفحات المحفوظة';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'النظام';

  @override
  String get languageHint => 'لغة التطبيق.';

  @override
  String get paletteNight => 'ليل';

  @override
  String get paletteDay => 'نهار';

  @override
  String get paletteClassic => 'كلاسيكي';

  @override
  String get paletteSepia => 'بنّي';

  @override
  String get paletteGreen => 'أخضر';

  @override
  String get paletteContrast => 'تباين عالٍ';

  @override
  String get typefaceIndopak => 'نستعليق هندي';

  @override
  String get typefaceIndopakDesc => 'أسلوب شبه القارة الهندية التقليدي';

  @override
  String get typefaceQpcNastaleeq => 'نستعليق مجمع الملك فهد';

  @override
  String get typefaceQpcNastaleeqDesc => 'الأسلوب الهندي من مجمع الملك فهد';

  @override
  String get typefaceQpcHafs => 'حفص مجمع الملك فهد';

  @override
  String get typefaceQpcHafsDesc => 'الرسم العثماني من مجمع الملك فهد';

  @override
  String get customColours => 'ألوان مخصصة';

  @override
  String contrastGood(String ratio) {
    return 'التباين $ratio:1 — سهل القراءة.';
  }

  @override
  String contrastBad(String ratio) {
    return 'التباين $ratio:1 — قد يصعب قراءة النص. يُنصح بـ 4.5:1 أو أكثر.';
  }

  @override
  String get background => 'الخلفية';

  @override
  String get textColour => 'النص';

  @override
  String get accent => 'لون التمييز';

  @override
  String get suggestions => 'اقتراحات';

  @override
  String get suggestedColour => 'لون مقترح';

  @override
  String get editionIndopak15Qudratullah => '15 سطرًا · قدرة الله';

  @override
  String get editionIndopak16Taj => '16 سطرًا · شركة تاج';

  @override
  String get editionIndopak13Qudratullah => '13 سطرًا · قدرة الله';

  @override
  String get editionIndopak13Taj => '13 سطرًا · شركة تاج';

  @override
  String get editionIndopak9Gaba => '9 أسطر · غابا (خط كبير)';

  @override
  String get editionMadani1405 => '1405هـ · مجمع الملك فهد V1';

  @override
  String get editionMadani1421 => '1421هـ · مجمع الملك فهد V2';

  @override
  String get imageIndopak15Plain => '15 سطرًا · مجمع الملك فهد';

  @override
  String get imageIndopak15PlainDesc =>
      'مصحف مجمع الملك فهد بالرسم الهندي، 15 سطرًا (610 صفحات).';

  @override
  String get imageIndopak16Taj => '16 سطرًا · شركة تاج';

  @override
  String get imageIndopak16TajDesc =>
      'مسح لطبعة شركة تاج ذات 16 سطرًا (548 صفحة).';

  @override
  String get imageIndopak13Qudratullah => '13 سطرًا · قدرة الله';

  @override
  String get imageIndopak13QudratullahDesc =>
      'مسح لطبعة قدرة الله ذات 13 سطرًا (849 صفحة).';

  @override
  String get imageIndopak15Colour => '15 سطرًا · تجويد ملوّن';

  @override
  String get imageIndopak15ColourDesc =>
      'أحكام التجويد بالألوان في كل صفحة (610 صفحات).';

  @override
  String get imageMadani15 => '15 سطرًا · مجمع الملك فهد';

  @override
  String get imageMadani15Desc =>
      'مصحف المدينة من مجمع الملك فهد، الطبعة الممتازة (604 صفحات).';

  @override
  String get sources => 'المصادر';

  @override
  String get sourcesHint =>
      'من أين أُخذ نص القرآن وتخطيطاته وخطوطه وصور صفحاته';

  @override
  String get sourcesIntro =>
      'كل كلمة من نص القرآن، وكل تخطيط للمصحف، وجميع بيانات القرآن في هذا التطبيق مأخوذة من QUL (المكتبة القرآنية الشاملة من Tarteel AI)، التي تنشر بيانات مُدقَّقة. يُستخدم النص كما نُشر تمامًا، سوى حذف المسافات الزائدة على أطراف الكلمات.';

  @override
  String get srcText => 'نص القرآن، كلمة كلمة';

  @override
  String get srcLayouts => 'تخطيطات المصحف';

  @override
  String get srcLayoutsNote =>
      'أي الكلمات تقع في كل سطر من كل صفحة، لكل طبعة مطبوعة.';

  @override
  String get srcFonts => 'الخطوط القرآنية';

  @override
  String get srcMetadata => 'بيانات القرآن';

  @override
  String get metaSurahs => 'أسماء السور ومكان النزول وعدد الآيات';

  @override
  String get metaAyahs => 'قائمة الآيات';

  @override
  String get metaJuz => 'الأجزاء';

  @override
  String get metaHizb => 'الأحزاب';

  @override
  String get metaRub => 'أرباع الأحزاب';

  @override
  String get metaManzil => 'المنازل';

  @override
  String get metaRuku => 'الركوعات';

  @override
  String get metaSajda => 'مواضع السجود';

  @override
  String get srcPrinted => 'صور الصفحات المطبوعة';

  @override
  String get srcPrintedNote =>
      'صفحات المصحف من مجمع الملك فهد نفسه، مأخوذة من ملفاته دون أي تغيير، فدقتها تتبع الطبعة نفسها. تُنزَّل من استضافتنا أثناء القراءة.';

  @override
  String imageThanks(String name) {
    return 'شكرًا لـ$name، فمجموعته من الصفحات هي التي قادتنا إلى هذا الأصل.';
  }

  @override
  String get srcOther => 'ما ليس من نص القرآن';

  @override
  String get srcOtherNote =>
      'هذه الأجزاء أُعدّت أو أُخذت من خارج QUL، وليس شيء منها من نص القرآن.';

  @override
  String get otherMeanings =>
      'المعاني الإنجليزية لأسماء السور (تُستخدم في البحث)';

  @override
  String get otherHeaders => 'كلمات آياتها ومكية ومدنية في عناوين السور';

  @override
  String get writtenInApp => 'مكتوبة في التطبيق';

  @override
  String get otherMarkers => 'علامات الآيات لخط نستعليق مجمع الملك فهد';

  @override
  String get otherMarkersSource =>
      'يرسمها التطبيق: زخرفة الآية من الخط نفسه، مع أرقام الآيات من QUL';

  @override
  String get otherLineFit => 'حجم الخط لكل طبعة';

  @override
  String get otherLineFitSource =>
      'مقيس بـ HarfBuzz من الخطوط المضمّنة، ليتسع كل سطر';

  @override
  String get srcAppFonts => 'خطوط التطبيق';

  @override
  String get appFontsSource => 'Google Fonts · SIL Open Font License';

  @override
  String get openLink => 'فتح الرابط';

  @override
  String get languageStepSubtitle => 'اختر لغة قوائم التطبيق وأزراره.';

  @override
  String get languageSystemHint => 'حسب لغة الهاتف';

  @override
  String get colourBrightness => 'السطوع';

  @override
  String get hexCode => 'رمز Hex';

  @override
  String get editionBigTextIndopak =>
      'تريد حروفًا أكبر؟ طبعتا 13 سطرًا و9 أسطر حروفهما أكبر، ويمكنك في القارئ التكبير بإصبعين أو اختيار القراءة الميسّرة الذي يعرض النص بأي حجم.';

  @override
  String get editionBigTextMadani =>
      'تريد حروفًا أكبر؟ يمكنك في القارئ التكبير بإصبعين، أو اختيار القراءة الميسّرة الذي يعرض النص بأي حجم.';

  @override
  String get displayBigTextIndopak =>
      'تريد نصًا أكبر؟ كبّر الصفحة بإصبعين، أو اختر القراءة الميسّرة، أو اختر طبعة 13 أو 9 أسطر من الإعدادات.';

  @override
  String get displayBigTextMadani =>
      'تريد نصًا أكبر؟ كبّر الصفحة بإصبعين، أو اختر القراءة الميسّرة.';

  @override
  String get translation => 'الترجمة';

  @override
  String get translationNone => 'بدون';

  @override
  String get translationAuto => 'حسب لغة التطبيق';

  @override
  String get translationHint =>
      'تظهر عند الضغط المطوّل على آية، وتحت كل آية في القراءة الميسّرة. صفحة المصحف تبقى للقرآن وحده.';

  @override
  String translationBy(String translator) {
    return 'الترجمة: $translator';
  }

  @override
  String get srcTranslations => 'ترجمات المعاني';

  @override
  String get srcTranslationsNote =>
      'تُعرض مع النص العربي، لا بدلًا منه، كما نشرها كل مترجم تمامًا (دون الحواشي).';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get languageUrdu => 'الأردية';

  @override
  String get translationStepTitle => 'هل تريد ترجمة للمعاني؟';

  @override
  String get translationStepSubtitle =>
      'معنى كل آية بلغتك. اضغط مطوّلًا على أي آية أثناء القراءة لترى ترجمتها.';

  @override
  String get theme => 'السمة';

  @override
  String get themeAuto => 'تلقائي';

  @override
  String get pagesLabel => 'الصفحات';

  @override
  String get onePage => 'صفحة';

  @override
  String get twoPagesLabel => 'صفحتان';

  @override
  String get twoPagesSetting => 'صفحتان متجاورتان';

  @override
  String get twoPagesHint =>
      'على الأجهزة اللوحية والحواسيب والهواتف الأفقية، كالكتاب المفتوح.';

  @override
  String get onePageTip => 'صفحة واحدة';

  @override
  String get twoPagesTip => 'صفحتان متجاورتان';

  @override
  String get textSizeStepTitle => 'اختر حجم خط مريحًا';

  @override
  String get textSizeStepSubtitle =>
      'اختر الحجم الذي تريد القراءة به. يمكنك تغييره في أي وقت أثناء القراءة.';

  @override
  String get viewLabel => 'طريقة العرض';

  @override
  String get printedFollowTheme => 'الصفحات المطبوعة تتبع السمة';

  @override
  String get printedFollowThemeHint =>
      'تأخذ الصفحات المطبوعة ألوان الورق والنص التي اخترتها. أوقفه لتراها كما طُبعت تمامًا، بألوانها الأصلية.';

  @override
  String get remindMe => 'التذكير';

  @override
  String get reminderBody => 'حان وقت وردك';

  @override
  String get everyDay => 'كل يوم';

  @override
  String get reminderPermissionOff =>
      'الإشعارات متوقفة لهذا التطبيق. اسمح بها من إعدادات هاتفك لتصلك التذكيرات.';

  @override
  String reminderAt(String time) {
    return 'تذكير الساعة $time';
  }

  @override
  String get share => 'مشاركة';

  @override
  String get shareImage => 'مشاركة صورة';

  @override
  String get shareText => 'مشاركة نص';

  @override
  String get saveImage => 'حفظ الصورة';

  @override
  String get copyText => 'نسخ النص';

  @override
  String get cardPost => 'منشور';

  @override
  String get cardStory => 'قصة';

  @override
  String imageSaved(String path) {
    return 'حُفظت الصورة في $path';
  }

  @override
  String get wordSpacing => 'المسافة بين الكلمات';

  @override
  String get surahTitles => 'أسماء السور (العناوين)';

  @override
  String get verticalScrollSetting => 'تمرير الصفحات عموديًا';

  @override
  String get verticalScrollHint =>
      'تمرير متصل من الأعلى إلى الأسفل بدل تقليب الصفحات جانبيًا. تظهر الصفحات واحدة تلو الأخرى.';

  @override
  String get listen => 'استماع';

  @override
  String get previousAyah => 'الآية السابقة';

  @override
  String get nextAyah => 'الآية التالية';

  @override
  String get stopRecitation => 'إيقاف';

  @override
  String get recitation => 'التلاوة';

  @override
  String get reciter => 'القارئ';

  @override
  String get repeatAyah => 'تلاوة كل آية';

  @override
  String get recitationFailed => 'تعذّر التحميل. تحقّق من الاتصال.';

  @override
  String get recitationHint =>
      'تسجيل كل قارئ كما هو، آيةً آية، من موقع EveryAyah. تُحفظ الآيات التي استمعت إليها، فتُسمع مرة أخرى دون اتصال.';

  @override
  String get bismillah => 'البسملة';

  @override
  String get srcRecitationNote =>
      'تسجيل لكل آية كما قرأها القارئ ونشره موقع EveryAyah؛ دون قصّ أو وصل. والبسملة قبل السورة هي الآية الأولى من الفاتحة.';

  @override
  String get srcTranslationVoices => 'الترجمات مسموعة';

  @override
  String roundOf(int round, int rounds) {
    return '$round من $rounds';
  }

  @override
  String get backup => 'مواضعك';

  @override
  String get exportLibrary => 'حفظ في ملف';

  @override
  String get exportLibraryHint =>
      'جلساتك وعلاماتك وملاحظاتك، لتحتفظ بها أو تفتحها على جهاز آخر.';

  @override
  String get importLibrary => 'فتح ملف محفوظ';

  @override
  String get importLibraryHint =>
      'يستعيد المواضع المحفوظة من Quiet Quran على أي جهاز.';

  @override
  String get importConfirmTitle => 'استبدال مواضعك هنا؟';

  @override
  String get importConfirmBody =>
      'ستُستبدل الجلسات والعلامات والملاحظات على هذا الجهاز بما في الملف.';

  @override
  String get replace => 'استبدال';

  @override
  String imported(int sessions, int bookmarks) {
    return 'تمت استعادة $sessions جلسات و$bookmarks علامات.';
  }

  @override
  String get importFailed => 'هذا ليس ملفًا محفوظًا من Quiet Quran.';

  @override
  String get exported => 'تم الحفظ.';

  @override
  String get translationAudioHint =>
      'عند إظهار الترجمة تحت كل آية، تُقرأ بعد التلاوة.';

  @override
  String get switchToDay => 'الوضع النهاري';

  @override
  String get switchToNight => 'الوضع الليلي';

  @override
  String showAll(int count) {
    return 'عرض الكل ($count)';
  }

  @override
  String get showLess => 'عرض أقل';

  @override
  String get printedDownloadTitle => 'حفظ الصفحات المطبوعة للقراءة دون اتصال؟';

  @override
  String printedDownloadBody(int pages, int mb) {
    return '$pages صفحة، نحو $mb ميغابايت. نزّلها كلها الآن في الخلفية أثناء قراءتك، أو دع كل صفحة تُحمَّل حين تقرؤها (يحتاج ذلك اتصالًا).';
  }

  @override
  String get printedDownloadAll => 'تنزيل الكل';

  @override
  String get printedLoadAsRead => 'تحميل أثناء القراءة';

  @override
  String printedDownloadingBar(int done, int total) {
    return 'جارٍ حفظ الصفحات المطبوعة: $done من $total';
  }

  @override
  String printedSavingNotice(String done, String total) {
    return 'جارٍ حفظ الصفحات المطبوعة: $done من $total';
  }

  @override
  String get printedSavedNotice => 'حُفظت الصفحات المطبوعة للقراءة دون اتصال';
}
