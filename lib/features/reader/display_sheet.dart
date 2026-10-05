import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/quran_db.dart';
import '../../l10n/l10n.dart';
import '../../widgets/night.dart';

/// The reader's "Aa" sheet, kept to a few quiet rows: how to read (Reflow,
/// Mushaf page or printed page), the reflow text size, the translation, and
/// icon toggles for Day/Night and one or two pages.
Future<void> showDisplaySheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _DisplaySheet(),
    );

/// Wide enough for two pages side by side (as the reader decides).
bool _wide(Size size) => size.width >= 600 && size.width >= size.height * 1.1;

enum _View { reflow, mushaf, printed }

class _DisplaySheet extends ConsumerWidget {
  const _DisplaySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final db = ref.watch(quranDbProvider);

    final view = s.mode == ReadingMode.pages
        ? _View.printed
        : s.textLayout == TextLayout.reflow
        ? _View.reflow
        : _View.mushaf;
    void setView(_View v) {
      if (v == _View.printed) {
        n.setMode(ReadingMode.pages);
        return;
      }
      n.setMode(ReadingMode.text);
      n.setTextLayout(
        v == _View.reflow ? TextLayout.reflow : TextLayout.mushaf,
      );
    }

    // One translation control. In Reflow it also shows the translation under
    // each ayah (Off hides it there, but keeps it for a held ayah); on a
    // Mushaf page it's what a held ayah shows.
    final chosen = s.translationFor(l.localeName);
    final translationValue = view == _View.reflow
        ? (s.reflowTranslation ? chosen ?? 'none' : 'none')
        : chosen ?? 'none';
    void setTranslation(String v) {
      if (view == _View.reflow) {
        if (v == 'none') {
          n.setReflowTranslation(false);
          return;
        }
        n.setReflowTranslation(true);
      }
      n.setTranslation(v);
    }

    final wide = _wide(MediaQuery.sizeOf(context));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(
              label: l.viewLabel,
              first: true,
              child: Segmented<_View>(
                value: view,
                onChanged: setView,
                options: [
                  (_View.reflow, l.reflow),
                  (_View.mushaf, l.mushaf),
                  (_View.printed, l.printed),
                ],
              ),
            ),
            if (view == _View.reflow)
              _Section(
                label: l.textSize,
                trailing: Text(
                  s.reflowFontSize.round().toString(),
                  style: AppType.label(t.ink),
                ),
                child: Row(
                  children: [
                    Text('A', style: AppType.body(t.mut)),
                    Expanded(
                      child: Semantics(
                        label: l.textSize,
                        child: Slider(
                          value: s.reflowFontSize,
                          min: 18,
                          max: 64,
                          divisions: 23,
                          onChanged: n.setReflowFontSize,
                        ),
                      ),
                    ),
                    Text(
                      'A',
                      style: AppType.body(t.mut).copyWith(fontSize: 24),
                    ),
                  ],
                ),
              ),
            // Translations go with text pages (a held ayah, or Reflow).
            if (view != _View.printed)
              _Section(
                label: l.translation,
                child: Segmented<String>(
                  value: translationValue,
                  onChanged: setTranslation,
                  options: [
                    ('none', l.translationNone),
                    for (final tr in db.translations)
                      (tr.id, l.translationLanguage(tr)),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Section(
                  label: l.theme,
                  compact: true,
                  child: IconSegmented<String>(
                    value: s.appearance,
                    onChanged: n.setAppearance,
                    options: [
                      ('system', LucideIcons.sunMoon, l.themeAuto),
                      ('day', LucideIcons.sun, l.paletteDay),
                      ('night', LucideIcons.moon, l.paletteNight),
                    ],
                  ),
                ),
                const Spacer(),
                // One or two pages, where the screen is wide enough for two.
                if (wide)
                  _Section(
                    label: l.pagesLabel,
                    compact: true,
                    end: true,
                    child: IconSegmented<bool>(
                      value: s.twoPages,
                      onChanged: n.setTwoPages,
                      options: [
                        (false, LucideIcons.rectangleVertical, l.onePageTip),
                        (true, LucideIcons.bookOpen, l.twoPagesTip),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One setting: a quiet uppercase label (with an optional value at its end)
/// above its control.
class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.child,
    this.trailing,
    this.first = false,
    this.compact = false,
    this.end = false,
  });

  final String label;
  final Widget child;
  final Widget? trailing;

  /// The first section sits closer to the sheet's handle.
  final bool first;

  /// Only as wide as its control (two side by side in a row).
  final bool compact;

  /// Aligned to the end of its row.
  final bool end;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(top: first ? 4 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: !compact
            ? CrossAxisAlignment.stretch
            : end
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
            child: Row(
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Text(label.toUpperCase(), style: AppType.eyebrow(t.mut)),
                if (trailing != null) ...[const Spacer(), trailing!],
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
