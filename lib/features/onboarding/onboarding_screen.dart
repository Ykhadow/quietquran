import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../data/image_editions.dart';
import '../../data/quran_db.dart';
import '../../l10n/l10n.dart';
import '../settings/page_download.dart';
import 'reading_previews.dart';

/// First-run flow: choose a script (with live samples), then choose whether to
/// read live text or printed page images. Both can be changed later.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pager = PageController();
  QuranScript? _script;
  ReadingMode? _mode;
  int _step = 0;
  static const _steps = 4;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pager.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Starts with the script's usual edition (the 15-line Mushaf for
  /// IndoPak); Settings has the others. Text size is set while reading.
  void _finish() {
    final script = _script!;
    final mode = _mode!;
    final edition = mode == ReadingMode.text
        ? script.defaultTextEdition
        : script.defaultImageEdition;
    ref
        .read(settingsProvider.notifier)
        .completeOnboarding(script: script, mode: mode, edition: edition);
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = switch (_step) {
      0 => true, // language: following the device is a fine answer
      1 => _script != null,
      2 => _mode != null,
      _ => true, // translation always has a choice
    };
    final last = _step == _steps - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  for (var i = 0; i < _steps; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pager,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Language first, so the rest of the questions read in it.
                  const _LanguageStep(),
                  _ScriptStep(
                    selected: _script,
                    onSelect: (s) => setState(() => _script = s),
                  ),
                  _ModeStep(
                    script: _script ?? QuranScript.indopak,
                    selected: _mode,
                    onSelect: (m) {
                      setState(() => _mode = m);
                      // Printed: save the whole set now, or load as read.
                      if (m == ReadingMode.pages) {
                        askToSavePrinted(
                          context,
                          ref,
                          ImageEdition.byId(
                            (_script ?? QuranScript.indopak)
                                .defaultImageEdition,
                          ),
                        );
                      }
                    },
                  ),
                  const _TranslationStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => _goTo(_step - 1),
                      child: Text(context.l10n.back),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: !canContinue
                        ? null
                        : last
                        ? _finish
                        : () => _goTo(_step + 1),
                    child: Text(
                      last
                          ? context.l10n.startReading
                          : context.l10n.continueLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          children: [
            Text(title, style: t.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: t.bodyLarge),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, box) {
                // Side by side on tablets / desktop, stacked on phones.
                if (box.maxWidth < 640) {
                  return Column(
                    children: [
                      for (final c in children)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: c,
                        ),
                    ],
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        if (i > 0) const SizedBox(width: 16),
                        Expanded(child: children[i]),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.changeLater,
              style: t.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.tagline,
    required this.preview,
    required this.points,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String tagline;
  final Widget preview;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.45)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: t.titleLarge)),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tagline,
                style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              preview,
              const SizedBox(height: 16),
              for (final p in points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short passage rendered with the script's own font and text data.
class _ScriptSample extends ConsumerWidget {
  const _ScriptSample(this.script);
  final QuranScript script;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(quranDbProvider);
    // Al-Fatihah, the opening page of every Mushaf.
    final words = db
        .page(script.defaultTextEdition, 1)
        .lines
        .expand((l) => l.words)
        .where((w) => w.ayah >= 2 && w.ayah <= 4)
        .map((w) => w.text)
        .join(' ');
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        words,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: script.fontFamily,
          fontSize: 26,
          height: script == QuranScript.indopak ? 2.0 : 1.8,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

class _ScriptStep extends StatelessWidget {
  const _ScriptStep({required this.selected, required this.onSelect});

  final QuranScript? selected;
  final ValueChanged<QuranScript> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _StepScaffold(
      title: l.scriptTitle,
      subtitle: l.scriptSubtitle,
      children: [
        _ChoiceCard(
          selected: selected == QuranScript.indopak,
          onTap: () => onSelect(QuranScript.indopak),
          title: l.indopakTitle,
          tagline: l.indopakTagline,
          preview: const _ScriptSample(QuranScript.indopak),
          points: const [],
        ),
        _ChoiceCard(
          selected: selected == QuranScript.madani,
          onTap: () => onSelect(QuranScript.madani),
          title: l.madaniTitle,
          tagline: l.madaniTagline,
          preview: const _ScriptSample(QuranScript.madani),
          points: const [],
        ),
      ],
    );
  }
}

class _ModeStep extends StatelessWidget {
  const _ModeStep({
    required this.script,
    required this.selected,
    required this.onSelect,
  });

  final QuranScript script;
  final ReadingMode? selected;
  final ValueChanged<ReadingMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    // Printed pages download as they're read: worth knowing when choosing.
    final footnote = selected == ReadingMode.pages ? l.modePagesFootnote : null;
    return _StepScaffold(
      title: l.modeTitle,
      subtitle: l.modeSubtitle(l.scriptLabel(script)),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The whole page each way, side by side, as on the website.
            ReadingModeChoice(
              script: script,
              selected: selected,
              onSelect: onSelect,
            ),
            const SizedBox(height: 16),
            if (footnote != null) ...[
              const SizedBox(height: 6),
              Text(
                footnote,
                style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Picks the specific Mushaf: a text layout, or a set of printed pages.
class _TranslationStep extends ConsumerWidget {
  const _TranslationStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final db = ref.watch(quranDbProvider);
    final s = ref.watch(settingsProvider);
    final auto = db.translation(
      s.copyWith(translation: 'auto').translationFor(l.localeName),
    );
    return _StepScaffold(
      title: l.translationStepTitle,
      subtitle: l.translationStepSubtitle,
      children: [
        Card.outlined(
          clipBehavior: Clip.antiAlias,
          child: RadioGroup<String>(
            groupValue: s.translation,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setTranslation(v!),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'auto',
                  title: Text(l.translationAuto),
                  subtitle: Text(
                    auto?.translator ?? l.translationNone,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                for (final tr in db.translations)
                  RadioListTile<String>(
                    value: tr.id,
                    title: Text(tr.translator),
                    subtitle: Text(
                      l.translationLanguage(tr),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                RadioListTile<String>(
                  value: 'none',
                  title: Text(l.translationNone),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Chooses the app language: the device's, English, Urdu or Arabic. The
/// choice applies at once, so the rest of setup reads in it.
class _LanguageStep extends ConsumerWidget {
  const _LanguageStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final current = ref.watch(settingsProvider.select((s) => s.language));
    return _StepScaffold(
      // In all three languages: whoever opens the app can read it.
      title: 'Language · زبان · اللغة',
      subtitle: l.languageStepSubtitle,
      children: [
        Card.outlined(
          clipBehavior: Clip.antiAlias,
          child: RadioGroup<String>(
            groupValue: current,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setLanguage(v!),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'system',
                  title: Text(l.languageSystem),
                  subtitle: Text(
                    l.languageSystemHint,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                for (final (code, name) in languages)
                  RadioListTile<String>(value: code, title: Text(name)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
