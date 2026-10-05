import 'package:flutter/material.dart';

/// The few colours a reader chooses; every other token is derived from them
/// (see [Tokens.fromPalette]). Night and Day carry the handoff's exact tokens.
class Palette {
  const Palette({
    required this.id,
    required this.name,
    required this.bg,
    required this.ink,
    required this.acc,
  });

  final String id;
  final String name;

  /// Page and app background.
  final Color bg;

  /// Text, including the Quran text.
  final Color ink;

  /// Ayah markers, surah names, calls to action.
  final Color acc;

  Brightness get brightness =>
      bg.computeLuminance() < 0.35 ? Brightness.dark : Brightness.light;

  static const night = Palette(
    id: 'night',
    name: 'Night',
    bg: Color(0xFF151614),
    ink: Color(0xFFE4DDD0),
    acc: Color(0xFFD98E70),
  );
  static const day = Palette(
    id: 'day',
    name: 'Day',
    bg: Color(0xFFF4F0E8),
    ink: Color(0xFF211F1B),
    acc: Color(0xFFA9532F),
  );
  static const sepia = Palette(
    id: 'sepia',
    name: 'Sepia',
    bg: Color(0xFFEFE3CB),
    ink: Color(0xFF3A2E22),
    acc: Color(0xFF8C5A2B),
  );
  static const green = Palette(
    id: 'green',
    name: 'Green',
    bg: Color(0xFF12201B),
    ink: Color(0xFFDCE6DD),
    acc: Color(0xFF8CC0A2),
  );
  static const highContrast = Palette(
    id: 'contrast',
    name: 'High contrast',
    bg: Color(0xFF0A0A0A),
    ink: Color(0xFFFFFFFF),
    acc: Color(0xFFFFC266),
  );

  static const presets = [night, day, sepia, green, highContrast];

  static Palette? preset(String id) =>
      presets.where((p) => p.id == id).firstOrNull;

  @override
  bool operator ==(Object other) =>
      other is Palette &&
      other.id == id &&
      other.bg == bg &&
      other.ink == ink &&
      other.acc == acc;

  @override
  int get hashCode => Object.hash(id, bg, ink, acc);

  Palette copyWith({Color? bg, Color? ink, Color? acc}) => Palette(
    id: id,
    name: name,
    bg: bg ?? this.bg,
    ink: ink ?? this.ink,
    acc: acc ?? this.acc,
  );

  /// WCAG contrast ratio of ink on background (1–21; 4.5 is the AA minimum).
  double get contrast {
    final a = bg.computeLuminance(), b = ink.computeLuminance();
    final (hi, lo) = a > b ? (a, b) : (b, a);
    return (hi + 0.05) / (lo + 0.05);
  }
}

/// Colour roles from the design handoff ("Mushaf · Night").
class Tokens extends ThemeExtension<Tokens> {
  const Tokens({
    required this.bg,
    required this.surf,
    required this.ink,
    required this.mut,
    required this.acc,
    required this.onAcc,
    required this.line,
    required this.line2,
    required this.rule,
    required this.shadow,
    required this.veil,
    required this.ring,
    required this.juzCell,
    required this.juzCell5,
    required this.brightness,
  });

  final Color bg, surf, ink, mut, acc, onAcc;
  final Color line, line2, rule, shadow, veil, ring, juzCell, juzCell5;
  final Brightness brightness;

  bool get dark => brightness == Brightness.dark;

  /// Night and Day use the handoff's exact values; other palettes derive the
  /// secondary roles from background, ink and accent.
  factory Tokens.fromPalette(Palette p) {
    if (p.id == 'night' &&
        p.bg == Palette.night.bg &&
        p.ink == Palette.night.ink) {
      return Tokens(
        bg: p.bg,
        surf: const Color(0xFF20211D),
        ink: p.ink,
        mut: const Color(0xFF9A9387),
        acc: p.acc,
        onAcc: const Color(0xFF151614),
        line: const Color(0x29E4DDD0),
        line2: const Color(0x1AE4DDD0),
        rule: const Color(0x33E4DDD0),
        shadow: const Color(0x80000000),
        veil: const Color(0xE60C0C0B),
        ring: const Color(0x2EE4DDD0),
        juzCell: const Color(0xFF3A3B35),
        juzCell5: const Color(0xFF4A4B44),
        brightness: Brightness.dark,
      );
    }
    if (p.id == 'day' && p.bg == Palette.day.bg && p.ink == Palette.day.ink) {
      return Tokens(
        bg: p.bg,
        surf: const Color(0xFFEBE5DA),
        ink: p.ink,
        mut: const Color(0xFF6E675C),
        acc: p.acc,
        onAcc: const Color(0xFFFBF8F2),
        line: const Color(0x29211F1B),
        line2: const Color(0x1A211F1B),
        rule: const Color(0x29211F1B),
        shadow: const Color(0x29211F1B),
        veil: const Color(0xF0F4F0E8),
        ring: const Color(0x1F211F1B),
        juzCell: const Color(0xFFD9D1C3),
        juzCell5: const Color(0xFFC9BFAE),
        brightness: Brightness.light,
      );
    }
    final dark = p.brightness == Brightness.dark;
    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
    return Tokens(
      bg: p.bg,
      surf: mix(p.bg, p.ink, dark ? 0.06 : 0.05),
      ink: p.ink,
      mut: mix(p.ink, p.bg, 0.38),
      acc: p.acc,
      onAcc: p.acc.computeLuminance() > 0.4
          ? mix(p.bg, Colors.black, 0.3)
          : Colors.white,
      line: p.ink.withValues(alpha: 0.16),
      line2: p.ink.withValues(alpha: 0.10),
      rule: p.ink.withValues(alpha: dark ? 0.20 : 0.16),
      shadow: dark ? const Color(0x80000000) : p.ink.withValues(alpha: 0.16),
      veil: mix(
        p.bg,
        dark ? Colors.black : Colors.white,
        0.2,
      ).withValues(alpha: dark ? 0.9 : 0.94),
      ring: p.ink.withValues(alpha: dark ? 0.18 : 0.12),
      juzCell: mix(p.bg, p.ink, dark ? 0.17 : 0.13),
      juzCell5: mix(p.bg, p.ink, dark ? 0.24 : 0.2),
      brightness: p.brightness,
    );
  }

  @override
  Tokens copyWith() => this;

  @override
  Tokens lerp(Tokens? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Tokens(
      bg: l(bg, other.bg),
      surf: l(surf, other.surf),
      ink: l(ink, other.ink),
      mut: l(mut, other.mut),
      acc: l(acc, other.acc),
      onAcc: l(onAcc, other.onAcc),
      line: l(line, other.line),
      line2: l(line2, other.line2),
      rule: l(rule, other.rule),
      shadow: l(shadow, other.shadow),
      veil: l(veil, other.veil),
      ring: l(ring, other.ring),
      juzCell: l(juzCell, other.juzCell),
      juzCell5: l(juzCell5, other.juzCell5),
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

/// Type roles from the handoff.
abstract final class AppType {
  static const serif = 'Newsreader';
  static const sans = 'SourceSans3';
  static const arabicUi = 'Amiri';
  static const arabicSmall = 'NotoNaskhArabic';

  /// Surah titles: the font draws "surahNNN" as that surah's name.
  static const surahName = 'SurahName';

  /// Urdu translations of the meanings.
  static const urdu = 'NotoNastaliqUrdu';

  /// Urdu and Arabic UI text (the Latin fonts have no Arabic letters).
  static const fallback = [arabicSmall];

  static TextStyle wordmark(Color c) => TextStyle(
    fontFamily: serif,
    fontFamilyFallback: fallback,
    fontSize: 22,
    color: c,
  );
  static TextStyle titleLg(Color c) => TextStyle(
    fontFamily: serif,
    fontFamilyFallback: fallback,
    fontSize: 21,
    color: c,
  );
  static TextStyle title(Color c) => TextStyle(
    fontFamily: serif,
    fontFamilyFallback: fallback,
    fontSize: 17.5,
    height: 1.2,
    color: c,
  );
  static TextStyle body(Color c, {FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: fallback,
    fontSize: 15,
    fontWeight: w,
    color: c,
  );
  static TextStyle label(Color c) => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: fallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: c,
  );
  static TextStyle caption(Color c) => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: fallback,
    fontSize: 13,
    color: c,
  );
  static TextStyle eyebrow(Color c) => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: fallback,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 12 * 0.12,
    color: c,
  );
  static TextStyle small(Color c) => TextStyle(
    fontFamily: sans,
    fontFamilyFallback: fallback,
    fontSize: 12,
    color: c,
  );
}

/// The theme for [palette], built once per palette (the app asks on every
/// rebuild; building ThemeData is not free).
ThemeData themeFor(Palette palette) {
  final cached = _themes[palette];
  if (cached != null) return cached;
  if (_themes.length > 8) _themes.remove(_themes.keys.first);
  return _themes[palette] = buildTheme(palette);
}

final _themes = <Palette, ThemeData>{};

ThemeData buildTheme(Palette palette) {
  final t = Tokens.fromPalette(palette);
  final scheme = ColorScheme(
    brightness: t.brightness,
    primary: t.acc,
    onPrimary: t.onAcc,
    secondary: t.acc,
    onSecondary: t.onAcc,
    error: const Color(0xFFD9534F),
    onError: Colors.white,
    surface: t.bg,
    onSurface: t.ink,
    onSurfaceVariant: t.mut,
    surfaceContainerLowest: t.bg,
    surfaceContainerLow: t.surf,
    surfaceContainer: t.surf,
    surfaceContainerHigh: t.surf,
    surfaceContainerHighest: t.surf,
    outline: t.mut,
    outlineVariant: t.line,
    primaryContainer: t.surf,
    onPrimaryContainer: t.ink,
    secondaryContainer: t.surf,
    onSecondaryContainer: t.ink,
    shadow: t.shadow,
  );
  final base = ThemeData(
    colorScheme: scheme,
    brightness: t.brightness,
    fontFamily: AppType.sans,
    fontFamilyFallback: AppType.fallback,
    scaffoldBackgroundColor: t.bg,
    canvasColor: t.bg,
    splashFactory: InkSparkle.splashFactory,
    extensions: [t],
  );
  final text = base.textTheme.apply(bodyColor: t.ink, displayColor: t.ink);
  return base.copyWith(
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(fontFamily: AppType.serif),
      titleLarge: text.titleLarge?.copyWith(fontFamily: AppType.serif),
    ),
    iconTheme: IconThemeData(color: t.mut, size: 22),
    appBarTheme: AppBarTheme(
      backgroundColor: t.bg,
      foregroundColor: t.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppType.titleLg(t.ink),
      iconTheme: IconThemeData(color: t.mut),
      actionsIconTheme: IconThemeData(color: t.mut),
    ),
    dividerTheme: DividerThemeData(color: t.line, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.acc,
        foregroundColor: t.onAcc,
        disabledBackgroundColor: t.surf,
        disabledForegroundColor: t.mut,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: const StadiumBorder(),
        textStyle: AppType.body(t.onAcc, w: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.acc,
        minimumSize: const Size(48, 40),
        textStyle: AppType.label(t.acc),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: t.line2)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.bg : t.surf,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.ink : t.mut,
        ),
        textStyle: WidgetStatePropertyAll(AppType.label(t.ink)),
        minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: t.acc,
      inactiveTrackColor: t.juzCell,
      thumbColor: t.ink,
      overlayColor: t.ring,
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.acc : t.mut,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: t.mut,
      textColor: t.ink,
      titleTextStyle: AppType.title(t.ink),
      subtitleTextStyle: AppType.caption(t.mut),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.acc,
      linearTrackColor: t.juzCell,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.bg,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: t.line,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: t.line2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.bg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: t.line2),
      ),
      titleTextStyle: AppType.titleLg(t.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.surf,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.line2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.line2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.acc),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.ink,
      contentTextStyle: AppType.body(t.bg),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

extension TokensX on BuildContext {
  Tokens get tokens => Theme.of(this).extension<Tokens>()!;
}
