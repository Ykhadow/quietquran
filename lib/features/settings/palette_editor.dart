import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/quran_db.dart';
import '../../widgets/colour_picker.dart';
import '../../widgets/night.dart';
import '../reader/quran_word.dart';
import '../../l10n/l10n.dart';

/// Edit the custom palette: background, text and accent, with a live preview
/// of a Mushaf line and a warning when text contrast is too low.
enum _Target { bg, ink, acc }

class PaletteEditor extends ConsumerStatefulWidget {
  const PaletteEditor({super.key});

  @override
  ConsumerState<PaletteEditor> createState() => _PaletteEditorState();
}

class _PaletteEditorState extends ConsumerState<PaletteEditor> {
  _Target _target = _Target.bg;

  static const _backgrounds = [
    Color(0xFF151614),
    Color(0xFF0A0A0A),
    Color(0xFF12201B),
    Color(0xFF1B1D26),
    Color(0xFF2A2320),
    Color(0xFFF4F0E8),
    Color(0xFFEFE3CB),
    Color(0xFFFFFFFF),
    Color(0xFFE8F0EA),
    Color(0xFFF3ECF3),
  ];
  static const _inks = [
    Color(0xFFE4DDD0),
    Color(0xFFFFFFFF),
    Color(0xFFDCE6DD),
    Color(0xFFD8DCEB),
    Color(0xFF211F1B),
    Color(0xFF3A2E22),
    Color(0xFF000000),
    Color(0xFF1E3326),
  ];
  static const _accents = [
    Color(0xFFD98E70),
    Color(0xFFA9532F),
    Color(0xFF8C5A2B),
    Color(0xFF8CC0A2),
    Color(0xFF2E7D6B),
    Color(0xFFFFC266),
    Color(0xFF7AA2E3),
    Color(0xFFB8860B),
    Color(0xFFC0506B),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final db = ref.watch(quranDbProvider);
    final p = s.customPalette;
    final preview = Tokens.fromPalette(p);
    final contrast = p.contrast;

    void set({Color? bg, Color? ink, Color? acc}) =>
        n.setCustomPalette(p.copyWith(bg: bg, ink: ink, acc: acc));

    // A line of Al-Mulk (67:1) in the reader's typeface, as a live preview.
    final typeface = s.typeface;
    final line = db.lineEndingAyah(s.textEdition, 67, 1, typeface);
    final quran = TextStyle(
      fontFamily: typeface.fontFamily,
      fontSize: 26,
      height: 1.9,
      color: preview.ink,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.l10n.back,
          icon: Icon(
            context.rtl ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
            color: t.ink,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(context.l10n.customColours),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: preview.bg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: preview.line),
                ),
                child: Column(
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Container(height: 1, color: preview.rule),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'سُورَةُ الملك',
                            textDirection: TextDirection.rtl,
                            style: quran.copyWith(
                              color: preview.acc,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(height: 1, color: preview.rule),
                        ),
                      ],
                    ),
                    if (line != null)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            for (final (i, w) in line.words.indexed) ...[
                              if (i > 0) const SizedBox(width: 7),
                              QuranWord(
                                word: w,
                                typeface: typeface,
                                style: quran,
                                markerStyle: quran.copyWith(color: preview.acc),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: Row(
                  children: [
                    Icon(
                      contrast >= 4.5
                          ? LucideIcons.circleCheck
                          : LucideIcons.triangleAlert,
                      size: 16,
                      color: contrast >= 4.5 ? t.mut : t.acc,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        contrast >= 4.5
                            ? context.l10n.contrastGood(
                                contrast.toStringAsFixed(1),
                              )
                            : context.l10n.contrastBad(
                                contrast.toStringAsFixed(1),
                              ),
                        style: AppType.caption(contrast >= 4.5 ? t.mut : t.acc),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Segmented<_Target>(
                  value: _target,
                  onChanged: (v) => setState(() => _target = v),
                  options: [
                    (_Target.bg, context.l10n.background),
                    (_Target.ink, context.l10n.textColour),
                    (_Target.acc, context.l10n.accent),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: ColourPicker(
                  color: switch (_target) {
                    _Target.bg => p.bg,
                    _Target.ink => p.ink,
                    _Target.acc => p.acc,
                  },
                  onChanged: (c) => switch (_target) {
                    _Target.bg => set(bg: c),
                    _Target.ink => set(ink: c),
                    _Target.acc => set(acc: c),
                  },
                ),
              ),
              Eyebrow(context.l10n.suggestions),
              _Swatches(
                colours: switch (_target) {
                  _Target.bg => _backgrounds,
                  _Target.ink => _inks,
                  _Target.acc => _accents,
                },
                value: switch (_target) {
                  _Target.bg => p.bg,
                  _Target.ink => p.ink,
                  _Target.acc => p.acc,
                },
                onChanged: (c) => switch (_target) {
                  _Target.bg => set(bg: c),
                  _Target.ink => set(ink: c),
                  _Target.acc => set(acc: c),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick picks for the colour being edited.
class _Swatches extends StatelessWidget {
  const _Swatches({
    required this.colours,
    required this.value,
    required this.onChanged,
  });

  final List<Color> colours;
  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in colours)
            Semantics(
              button: true,
              selected: c == value,
              label: context.l10n.suggestedColour,
              child: GestureDetector(
                onTap: () => onChanged(c),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c == value ? t.acc : t.line,
                      width: c == value ? 3 : 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
