import 'package:flutter/widgets.dart';

import '../core/settings.dart';
import '../core/theme.dart';
import '../data/image_editions.dart';
import '../data/library.dart';
import '../data/models.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// The app's languages, each named in itself.
const languages = [('en', 'English'), ('ur', 'اردو'), ('ar', 'العربية')];

/// The app's own words (never the Quran text) in English, Urdu or Arabic.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Urdu and Arabic readers see surah names in Arabic, not transliterated.
  bool get arabicNames => l10n.localeName != 'en';

  String surahName(Surah s) => arabicNames ? s.nameArabic : s.nameSimple;

  /// Daily reading keeps its default name in each language until renamed.
  String sessionName(Session s) =>
      s.isDaily && s.name == Session.dailyDefaultName
      ? l10n.dailyReading
      : s.name;

  /// Back arrow pointing the way the layout reads.
  bool get rtl => Directionality.of(this) == TextDirection.rtl;
}

extension L10nNames on AppLocalizations {
  String scriptLabel(QuranScript s) => switch (s) {
    QuranScript.indopak => scriptIndopak,
    QuranScript.madani => scriptMadani,
  };

  String typefaceLabel(QuranTypeface t) => switch (t) {
    QuranTypeface.indopakNastaleeq => typefaceIndopak,
    QuranTypeface.kfgqpcNastaleeq => typefaceQpcNastaleeq,
    QuranTypeface.qpcHafs => typefaceQpcHafs,
  };

  String typefaceDescription(QuranTypeface t) => switch (t) {
    QuranTypeface.indopakNastaleeq => typefaceIndopakDesc,
    QuranTypeface.kfgqpcNastaleeq => typefaceQpcNastaleeqDesc,
    QuranTypeface.qpcHafs => typefaceQpcHafsDesc,
  };

  /// A translation's language, in the app's language.
  String translationLanguage(Translation t) => switch (t.language) {
    'ur' => languageUrdu,
    'en' => languageEnglish,
    final other => other,
  };

  String paletteName(Palette p) => switch (p.id) {
    'night' => paletteNight,
    'day' => paletteDay,
    'classic' => paletteClassic,
    'sepia' => paletteSepia,
    'green' => paletteGreen,
    'contrast' => paletteContrast,
    _ => p.name,
  };

  /// A text edition's name; the database's English name for any not listed.
  String editionName(TextEdition e) => switch (e.id) {
    'indopak-15-qudratullah' => editionIndopak15Qudratullah,
    'indopak-16-taj' => editionIndopak16Taj,
    'indopak-13-qudratullah' => editionIndopak13Qudratullah,
    'indopak-13-taj' => editionIndopak13Taj,
    'indopak-9-gaba' => editionIndopak9Gaba,
    'madani-1405' => editionMadani1405,
    'madani-1421' => editionMadani1421,
    _ => e.name,
  };

  String imageTitle(ImageEdition e) => switch (e.id) {
    'indopak-15-plain' => imageIndopak15Plain,
    'indopak-16-taj-scan' => imageIndopak16Taj,
    'indopak-13-qudratullah-scan' => imageIndopak13Qudratullah,
    'indopak-15-colour' => imageIndopak15Colour,
    'madani-15-kfgqpc' => imageMadani15,
    _ => e.title,
  };

  String imageDescription(ImageEdition e) => switch (e.id) {
    'indopak-15-plain' => imageIndopak15PlainDesc,
    'indopak-16-taj-scan' => imageIndopak16TajDesc,
    'indopak-13-qudratullah-scan' => imageIndopak13QudratullahDesc,
    'indopak-15-colour' => imageIndopak15ColourDesc,
    'madani-15-kfgqpc' => imageMadani15Desc,
    _ => e.description,
  };
}
