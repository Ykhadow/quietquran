import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/image_editions.dart';
import 'theme.dart';

/// The Mushaf script. Each script has several editions (line layouts).
enum QuranScript {
  indopak('IndoPak', 'IndoPak', 'indopak-15-qudratullah'),
  madani('Madani', 'UthmanicHafs', 'madani-1405');

  const QuranScript(this.label, this.fontFamily, this.defaultTextEdition);
  final String label;
  final String fontFamily;
  final String defaultTextEdition;

  String get defaultImageEdition => ImageEdition.forScript(this).first.id;
}

/// A QUL Quran script paired with the font designed for it. All typefaces
/// share the same word ids, so any of a script's typefaces can render any of
/// its layouts.
enum QuranTypeface {
  indopakNastaleeq(
    'IndoPak Nastaleeq',
    'The classic Subcontinent style',
    QuranScript.indopak,
    'indopak',
    'IndoPak',
    0.55,
  ),
  kfgqpcNastaleeq(
    'KFGQPC Nastaleeq',
    'IndoPak style by the King Fahd Complex',
    QuranScript.indopak,
    'qpc_nastaleeq',
    'KFGQPCNastaleeq',
    0.55,
    drawMarkers: true,
  ),
  qpcHafs(
    'KFGQPC Hafs',
    'Uthmani script by the King Fahd Complex',
    QuranScript.madani,
    'madani',
    'UthmanicHafs',
    0.56,
  );

  const QuranTypeface(
    this.label,
    this.description,
    this.script,
    this.column,
    this.fontFamily,
    this.lineFill, {
    this.drawMarkers = false,
  });

  final String label;
  final String description;
  final QuranScript script;

  /// Column of the `words` table holding this typeface's text.
  final String column;
  final String fontFamily;

  /// Largest font size, as a share of the line height, that keeps a line's
  /// marks clear of its neighbours. Checked against every glyph of every
  /// page of every edition (letters and marks of neighbouring lines never
  /// overlap): Nastaleeq is clear from 1/1.82 = 0.55, Uthmani from 1/1.75.
  final double lineFill;

  /// The text ends ayahs with bare digits (no ornament), so the app draws the
  /// marker: the font's U+06DD ornament with the number over it.
  final bool drawMarkers;

  static List<QuranTypeface> forScript(QuranScript s) =>
      values.where((t) => t.script == s).toList();
}

/// How pages are drawn: live text with our fonts, or downloaded page images.
enum ReadingMode { text, pages }

/// What the reader's bottom strip steps through.
enum ScrubberMode { juz, surah }

/// In text mode: the fixed Mushaf page, or ayahs reflowed at any size.
enum TextLayout { mushaf, reflow }

class Settings {
  const Settings({
    required this.onboarded,
    required this.script,
    required this.mode,
    required this.textEdition,
    required this.imageEdition,
    required this.textLayout,
    required this.scrubber,
    required this.indopakTypeface,
    required this.appearance,
    required this.customPalette,
    required this.reflowFontSize,
    required this.reflowWordSpacing,
    required this.language,
    required this.translation,
    required this.reflowTranslation,
    required this.twoPages,
    required this.verticalScroll,
    required this.printedFollowTheme,
    required this.reciter,
    required this.ayahRepeat,
  });

  static const defaults = Settings(
    onboarded: false,
    script: QuranScript.indopak,
    mode: ReadingMode.text,
    textEdition: 'indopak-15-qudratullah',
    imageEdition: 'indopak-15-plain',
    textLayout: TextLayout.reflow,
    scrubber: ScrubberMode.juz,
    indopakTypeface: QuranTypeface.indopakNastaleeq,
    appearance: 'system',
    customPalette: Palette(
      id: 'custom',
      name: 'Custom',
      bg: Color(0xFF151614),
      ink: Color(0xFFE4DDD0),
      acc: Color(0xFFD98E70),
    ),
    reflowFontSize: 30,
    reflowWordSpacing: 0.08,
    language: 'system',
    translation: 'auto',
    reflowTranslation: false,
    twoPages: true,
    verticalScroll: false,
    printedFollowTheme: false,
    reciter: 'alafasy',
    ayahRepeat: 1,
  );

  final bool onboarded;
  final QuranScript script;
  final ReadingMode mode;

  /// Edition ids: one for text mode, one for printed pages.
  final String textEdition;
  final String imageEdition;
  final TextLayout textLayout;
  final ScrubberMode scrubber;

  final QuranTypeface indopakTypeface;

  /// 'system' (Day or Night, following the device), a preset palette id, or
  /// 'custom'.
  final String appearance;

  /// The reader's own colours, used when [appearance] is 'custom'.
  final Palette customPalette;

  /// The palette to use for a given device brightness.
  Palette palette(Brightness platform) => switch (appearance) {
    'system' => platform == Brightness.dark ? Palette.night : Palette.day,
    'custom' => customPalette,
    final id => Palette.preset(id) ?? Palette.day,
  };
  final double reflowFontSize;

  /// The least space between words in Easy read, as a share of the text
  /// size (lines are justified to the full width, so most spaces are a
  /// little wider). From as close as the words' ink allows (0) up; the
  /// Mushaf pages use 0.18. A little under half that by default.
  final double reflowWordSpacing;

  /// App language: 'system', 'en', 'ur' or 'ar'. Quran text is unaffected.
  final String language;

  /// Translation of the meanings: 'auto' (by the app's language), 'none', or
  /// a translation id.
  final String translation;

  /// Show each ayah's translation under it in Reflow.
  final bool reflowTranslation;

  /// On wide screens (tablets, desktop, phones held sideways), show two
  /// Mushaf pages side by side like an open book; otherwise one.
  final bool twoPages;

  /// Pages follow one another in one continuous vertical scroll, instead of
  /// turning sideways. One page at a time, never two side by side.
  final bool verticalScroll;

  /// Printed pages take the palette's paper and ink colours (colour-coded
  /// tajweed pages are only dimmed at night); otherwise they show exactly as
  /// scanned, black on white.
  final bool printedFollowTheme;

  /// Recitation: the reciter's id (see [Reciter]).
  final String reciter;

  /// The translation is on the page, under each ayah (Easy read with the
  /// translation shown). Then the recitation reads it aloud too, after each
  /// ayah: one switch for both.
  bool get translationShown =>
      mode == ReadingMode.text &&
      textLayout == TextLayout.reflow &&
      reflowTranslation;

  /// How many times each ayah is recited before the next (for memorising);
  /// its translation, if on, follows once.
  final int ayahRepeat;

  /// The translation to show for an app in [languageCode], or null for none.
  /// 'auto' picks the reader's own language: Urdu for Urdu, English for
  /// English, none for Arabic (whose readers read the Quran directly).
  String? translationFor(String languageCode) => switch (translation) {
    'auto' => switch (languageCode) {
      'ur' => 'ur-jalandhari',
      'en' => 'en-sahih',
      _ => null,
    },
    'none' => null,
    final id => id,
  };

  /// The locale to force, or null to follow the device.
  Locale? get locale => language == 'system' ? null : Locale(language);

  /// Typeface used to draw the current script in text mode.
  QuranTypeface get typeface =>
      script == QuranScript.indopak ? indopakTypeface : QuranTypeface.qpcHafs;

  /// The text layout whose page numbers are in use: the text edition itself,
  /// or the layout a printed-page edition follows.
  String get layoutEdition => mode == ReadingMode.text
      ? textEdition
      : ImageEdition.byId(imageEdition).layout;

  Settings copyWith({
    bool? onboarded,
    QuranScript? script,
    ReadingMode? mode,
    String? textEdition,
    String? imageEdition,
    TextLayout? textLayout,
    ScrubberMode? scrubber,
    QuranTypeface? indopakTypeface,
    String? appearance,
    Palette? customPalette,
    double? reflowFontSize,
    double? reflowWordSpacing,
    String? language,
    String? translation,
    bool? reflowTranslation,
    bool? twoPages,
    bool? verticalScroll,
    bool? printedFollowTheme,
    String? reciter,
    int? ayahRepeat,
  }) => Settings(
    onboarded: onboarded ?? this.onboarded,
    script: script ?? this.script,
    mode: mode ?? this.mode,
    textEdition: textEdition ?? this.textEdition,
    imageEdition: imageEdition ?? this.imageEdition,
    textLayout: textLayout ?? this.textLayout,
    scrubber: scrubber ?? this.scrubber,
    indopakTypeface: indopakTypeface ?? this.indopakTypeface,
    appearance: appearance ?? this.appearance,
    customPalette: customPalette ?? this.customPalette,
    reflowFontSize: reflowFontSize ?? this.reflowFontSize,
    reflowWordSpacing: reflowWordSpacing ?? this.reflowWordSpacing,
    language: language ?? this.language,
    translation: translation ?? this.translation,
    reflowTranslation: reflowTranslation ?? this.reflowTranslation,
    twoPages: twoPages ?? this.twoPages,
    verticalScroll: verticalScroll ?? this.verticalScroll,
    printedFollowTheme: printedFollowTheme ?? this.printedFollowTheme,
    reciter: reciter ?? this.reciter,
    ayahRepeat: ayahRepeat ?? this.ayahRepeat,
  );
}

/// Overridden in main() once SharedPreferences has loaded.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('prefsProvider must be overridden'),
);

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<Settings> {
  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  Settings build() {
    final p = ref.read(prefsProvider);
    const d = Settings.defaults;
    T pick<T extends Enum>(List<T> values, String key, T fallback) =>
        values.asNameMap()[p.getString(key)] ?? fallback;
    final script = pick(QuranScript.values, 'script', d.script);
    final image = p.getString('imageEdition');
    return Settings(
      onboarded: p.getBool('onboarded') ?? d.onboarded,
      script: script,
      mode: pick(ReadingMode.values, 'mode', d.mode),
      textEdition: p.getString('textEdition') ?? script.defaultTextEdition,
      imageEdition: image != null && ImageEdition.exists(image)
          ? image
          : script.defaultImageEdition,
      textLayout: pick(TextLayout.values, 'textLayout', d.textLayout),
      scrubber: pick(ScrubberMode.values, 'scrubber', d.scrubber),
      indopakTypeface: pick(
        QuranTypeface.values,
        'indopakTypeface',
        d.indopakTypeface,
      ),
      appearance: p.getString('appearance') ?? d.appearance,
      customPalette: _readCustom(p) ?? d.customPalette,
      reflowFontSize: p.getDouble('reflowFontSize') ?? d.reflowFontSize,
      reflowWordSpacing:
          p.getDouble('reflowWordSpacing') ?? d.reflowWordSpacing,
      language: p.getString('language') ?? d.language,
      translation: p.getString('translation') ?? d.translation,
      reflowTranslation: p.getBool('reflowTranslation') ?? d.reflowTranslation,
      twoPages: p.getBool('twoPages') ?? d.twoPages,
      verticalScroll: p.getBool('verticalScroll') ?? d.verticalScroll,
      printedFollowTheme:
          p.getBool('printedFollowTheme') ?? d.printedFollowTheme,
      reciter: p.getString('reciter') ?? d.reciter,
      ayahRepeat: (p.getInt('ayahRepeat') ?? d.ayahRepeat).clamp(1, 99),
    );
  }

  void completeOnboarding({
    required QuranScript script,
    required ReadingMode mode,
    required String edition,
  }) {
    setScript(script);
    setMode(mode);
    mode == ReadingMode.text
        ? setTextEdition(edition)
        : setImageEdition(edition);
    state = state.copyWith(onboarded: true);
    _prefs.setBool('onboarded', true);
  }

  /// Switching script also switches to that script's default editions.
  void setScript(QuranScript v) {
    if (v == state.script) return;
    state = state.copyWith(
      script: v,
      textEdition: v.defaultTextEdition,
      imageEdition: v.defaultImageEdition,
    );
    _prefs
      ..setString('script', v.name)
      ..setString('textEdition', state.textEdition)
      ..setString('imageEdition', state.imageEdition);
  }

  void setMode(ReadingMode v) {
    state = state.copyWith(mode: v);
    _prefs.setString('mode', v.name);
  }

  void setTextEdition(String id) {
    state = state.copyWith(textEdition: id);
    _prefs.setString('textEdition', id);
  }

  void setImageEdition(String id) {
    state = state.copyWith(imageEdition: id);
    _prefs.setString('imageEdition', id);
  }

  void setTextLayout(TextLayout v) {
    state = state.copyWith(textLayout: v);
    _prefs.setString('textLayout', v.name);
  }

  void setScrubber(ScrubberMode v) {
    state = state.copyWith(scrubber: v);
    _prefs.setString('scrubber', v.name);
  }

  void setReciter(String id) {
    state = state.copyWith(reciter: id);
    _prefs.setString('reciter', id);
  }

  void setAyahRepeat(int v) {
    state = state.copyWith(ayahRepeat: v);
    _prefs.setInt('ayahRepeat', v);
  }

  void setIndopakTypeface(QuranTypeface v) {
    state = state.copyWith(indopakTypeface: v);
    _prefs.setString('indopakTypeface', v.name);
  }

  static Palette? _readCustom(SharedPreferences p) {
    final v = p.getStringList('customPalette');
    if (v == null || v.length != 3) return null;
    Color c(String s) => Color(int.parse(s, radix: 16));
    return Palette(
      id: 'custom',
      name: 'Custom',
      bg: c(v[0]),
      ink: c(v[1]),
      acc: c(v[2]),
    );
  }

  void setAppearance(String v) {
    state = state.copyWith(appearance: v);
    _prefs.setString('appearance', v);
  }

  void setCustomPalette(Palette v) {
    state = state.copyWith(customPalette: v, appearance: 'custom');
    String hex(Color c) => c.toARGB32().toRadixString(16).padLeft(8, '0');
    _saveSoon('customPalette', () {
      _prefs
        ..setStringList('customPalette', [hex(v.bg), hex(v.ink), hex(v.acc)])
        ..setString('appearance', 'custom');
    });
  }

  void setReflowFontSize(double v) {
    state = state.copyWith(reflowFontSize: v);
    _saveSoon('reflowFontSize', () => _prefs.setDouble('reflowFontSize', v));
  }

  void setReflowWordSpacing(double v) {
    state = state.copyWith(reflowWordSpacing: v);
    _saveSoon(
      'reflowWordSpacing',
      () => _prefs.setDouble('reflowWordSpacing', v),
    );
  }

  /// Saves a value dragged on a slider or colour picker once the drag pauses,
  /// not on every frame of it (each save is a call to the platform).
  void _saveSoon(String key, void Function() save) {
    _pendingSaves.remove(key)?.cancel();
    _pendingSaves[key] = Timer(const Duration(milliseconds: 300), () {
      _pendingSaves.remove(key);
      save();
    });
  }

  final _pendingSaves = <String, Timer>{};

  void setLanguage(String v) {
    state = state.copyWith(language: v);
    _prefs.setString('language', v);
  }

  void setTranslation(String v) {
    state = state.copyWith(translation: v);
    _prefs.setString('translation', v);
  }

  void setReflowTranslation(bool v) {
    state = state.copyWith(reflowTranslation: v);
    _prefs.setBool('reflowTranslation', v);
  }

  void setTwoPages(bool v) {
    state = state.copyWith(twoPages: v);
    _prefs.setBool('twoPages', v);
  }

  void setVerticalScroll(bool v) {
    state = state.copyWith(verticalScroll: v);
    _prefs.setBool('verticalScroll', v);
  }

  void setPrintedFollowTheme(bool v) {
    state = state.copyWith(printedFollowTheme: v);
    _prefs.setBool('printedFollowTheme', v);
  }
}
