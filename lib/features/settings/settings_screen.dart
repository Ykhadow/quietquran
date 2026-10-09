import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/image_editions.dart';
import '../../data/models.dart';
import '../../data/page_images.dart';
import '../../data/quran_db.dart';
import '../audio/recitation_widgets.dart';
import '../reader/reflow_page.dart';
import '../../widgets/night.dart';
import '../onboarding/reading_previews.dart';
import 'backup_rows.dart';
import 'page_download.dart';
import 'palette_editor.dart';
import 'sources_screen.dart';
import '../../l10n/l10n.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final db = ref.watch(quranDbProvider);
    final l = context.l10n;

    Widget pad(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.back,
          icon: Icon(
            context.rtl ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
            color: t.ink,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(l.settings),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // Themes first: the colours set the feel of everything below.
              Eyebrow(
                l.appearance,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              ),
              const _Appearance(),
              Eyebrow(l.language),
              pad(
                Segmented<String>(
                  value: s.language,
                  onChanged: n.setLanguage,
                  options: [
                    ('system', l.languageSystem),
                    for (final (code, name) in languages) (code, name),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 0),
                child: Text(l.languageHint, style: AppType.caption(t.mut)),
              ),
              Eyebrow(l.mushaf),
              GroupedCard(
                children: [
                  for (final v in QuranScript.values)
                    ChoiceRow(
                      title: l.scriptLabel(v),
                      subtitle: v == QuranScript.indopak
                          ? l.indopakTagline
                          : l.madaniTagline,
                      selected: s.script == v,
                      onTap: () {
                        n.setScript(v);
                        // On printed pages: the other script's set too.
                        if (s.mode == ReadingMode.pages && v != s.script) {
                          askToSavePrinted(
                            context,
                            ref,
                            ImageEdition.byId(v.defaultImageEdition),
                          );
                        }
                      },
                      preview: Text(
                        _sample(db, QuranTypeface.forScript(v).first),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: QuranTypeface.forScript(
                            v,
                          ).first.fontFamily,
                          fontSize: 22,
                          height: 2,
                          color: t.ink,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              pad(
                Center(
                  child: ReadingModeChoice(
                    script: s.script,
                    selected: s.mode,
                    onSelect: (m) {
                      n.setMode(m);
                      if (m == ReadingMode.pages) {
                        askToSavePrinted(
                          context,
                          ref,
                          ImageEdition.byId(s.imageEdition),
                        );
                      }
                    },
                    maxWidth: 440,
                  ),
                ),
              ),
              Eyebrow(l.edition),
              ChoiceCard(
                rows: s.mode == ReadingMode.text
                    ? [
                        for (final e in db.editionsFor(s.script))
                          ChoiceRow(
                            title: l.editionName(e),
                            subtitle: l.linesPages(e.linesPerPage, e.pages),
                            selected: e.id == s.textEdition,
                            onTap: () => n.setTextEdition(e.id),
                          ),
                      ]
                    : [
                        for (final e in ImageEdition.forScript(s.script))
                          ChoiceRow(
                            title: l.imageTitle(e),
                            subtitle: l.imageDescription(e),
                            selected: e.id == s.imageEdition,
                            onTap: () {
                              n.setImageEdition(e.id);
                              askToSavePrinted(context, ref, e);
                            },
                          ),
                      ],
              ),
              if (s.mode == ReadingMode.text &&
                  QuranTypeface.forScript(s.script).length > 1) ...[
                Eyebrow(l.typeface),
                ChoiceCard(
                  rows: [
                    for (final tf in QuranTypeface.forScript(s.script))
                      ChoiceRow(
                        title: l.typefaceLabel(tf),
                        subtitle: l.typefaceDescription(tf),
                        selected: tf == s.typeface,
                        onTap: () => n.setIndopakTypeface(tf),
                        preview: Text(
                          _sample(db, tf),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: tf.fontFamily,
                            fontSize: 22,
                            height: 2,
                            color: t.ink,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (s.mode == ReadingMode.text) ...[
                Eyebrow(l.textLayout),
                pad(
                  Segmented<TextLayout>(
                    value: s.textLayout,
                    onChanged: n.setTextLayout,
                    options: [
                      (TextLayout.reflow, l.reflow),
                      (TextLayout.mushaf, l.mushafPage),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 14, 16, 0),
                  child: Row(
                    children: [
                      Text(l.reflowTextSize, style: AppType.body(t.ink)),
                      Expanded(
                        child: Slider(
                          value: s.reflowFontSize,
                          min: 18,
                          max: 64,
                          divisions: 23,
                          label: s.reflowFontSize.round().toString(),
                          onChanged: n.setReflowFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 16, 0),
                  child: Row(
                    children: [
                      Text(l.wordSpacing, style: AppType.body(t.ink)),
                      Expanded(
                        // From as close as the words' ink allows, through
                        // the Mushaf page's own spacing (0.18), up.
                        child: Slider(
                          value: s.reflowWordSpacing,
                          min: 0,
                          max: 0.5,
                          divisions: 25,
                          onChanged: n.setReflowWordSpacing,
                        ),
                      ),
                    ],
                  ),
                ),
                // What the two sliders do, as they move.
                pad(_EasyReadPreview(settings: s, db: db)),
              ],
              Eyebrow(l.offlinePages),
              GroupedCard(
                children: [
                  for (final e in ImageEdition.forScript(s.script))
                    _DownloadRow(edition: e),
                ],
              ),
              Eyebrow(l.translation),
              ChoiceCard(
                rows: [
                  ChoiceRow(
                    title: l.translationAuto,
                    subtitle:
                        db.translation(s.translationFor(l.localeName)) == null
                        ? l.translationNone
                        : db
                              .translation(s.translationFor(l.localeName))!
                              .translator,
                    selected: s.translation == 'auto',
                    onTap: () => n.setTranslation('auto'),
                  ),
                  for (final tr in db.translations)
                    ChoiceRow(
                      title: tr.translator,
                      subtitle: l.translationLanguage(tr),
                      selected: s.translation == tr.id,
                      onTap: () => n.setTranslation(tr.id),
                    ),
                  ChoiceRow(
                    title: l.translationNone,
                    subtitle: '',
                    selected: s.translation == 'none',
                    onTap: () => n.setTranslation('none'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(l.translationHint, style: AppType.caption(t.mut)),
              ),
              const RecitationOptions(),
              Eyebrow(l.reader),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(l.twoPagesSetting, style: AppType.body(t.ink)),
                subtitle: Text(l.twoPagesHint, style: AppType.caption(t.mut)),
                value: s.twoPages,
                activeThumbColor: t.acc,
                onChanged: n.setTwoPages,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  l.verticalScrollSetting,
                  style: AppType.body(t.ink),
                ),
                subtitle: Text(
                  l.verticalScrollHint,
                  style: AppType.caption(t.mut),
                ),
                value: s.verticalScroll,
                activeThumbColor: t.acc,
                onChanged: n.setVerticalScroll,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(l.scrubberHint, style: AppType.caption(t.mut)),
              ),
              pad(
                Segmented<ScrubberMode>(
                  value: s.scrubber,
                  onChanged: n.setScrubber,
                  options: [
                    (ScrubberMode.juz, l.juz),
                    (ScrubberMode.surah, l.surahs),
                  ],
                ),
              ),
              Eyebrow(l.backup),
              const BackupRows(),
              Eyebrow(l.about),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l.aboutText,
                  style: AppType.caption(t.mut).copyWith(height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              GroupedCard(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SourcesScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Icon(LucideIcons.bookOpenCheck, color: t.acc),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.sources, style: AppType.title(t.ink)),
                                const SizedBox(height: 2),
                                Text(
                                  l.sourcesHint,
                                  style: AppType.caption(t.mut),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            context.rtl
                                ? LucideIcons.chevronLeft
                                : LucideIcons.chevronRight,
                            size: 18,
                            color: t.mut,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Al-Fatihah 2-3 in [t], to preview a typeface.
String _sample(QuranDb db, QuranTypeface t) => db
    .page(t.script.defaultTextEdition, 1, t)
    .lines
    .expand((l) => l.words)
    .where((w) => (w.ayah == 2 || w.ayah == 3) && !w.isAyahEnd)
    .map((w) => w.text)
    .join(' ');

/// Palette swatches: System (Day/Night with the device), the presets, and the
/// reader's custom colours.
class _Appearance extends ConsumerWidget {
  const _Appearance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    Widget swatch({
      required String id,
      required String label,
      required List<Palette> palettes,
      VoidCallback? onTap,
    }) {
      final selected = s.appearance == id;
      return Semantics(
        button: true,
        selected: selected,
        label: context.l10n.swatchLabel(label),
        child: GestureDetector(
          onTap: onTap ?? () => n.setAppearance(id),
          child: SizedBox(
            width: 76,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? t.acc : t.line,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Row(
                      children: [
                        for (final p in palettes)
                          Expanded(
                            child: ColoredBox(
                              color: p.bg,
                              child: Center(
                                child: Text(
                                  'ب',
                                  style: TextStyle(
                                    fontFamily: AppType.arabicUi,
                                    fontSize: palettes.length > 1 ? 18 : 24,
                                    color: p.ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.small(selected ? t.ink : t.mut),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              swatch(
                id: 'system',
                label: context.l10n.system,
                palettes: const [Palette.day, Palette.night],
              ),
              for (final p in Palette.presets)
                swatch(
                  id: p.id,
                  label: context.l10n.paletteName(p),
                  palettes: [p],
                ),
              swatch(
                id: 'custom',
                label: context.l10n.custom,
                palettes: [s.customPalette],
                onTap: () {
                  n.setAppearance('custom');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaletteEditor()),
                  );
                },
              ),
            ],
          ),
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          title: Text(
            context.l10n.printedFollowTheme,
            style: AppType.body(t.ink),
          ),
          subtitle: Text(
            context.l10n.printedFollowThemeHint,
            style: AppType.caption(t.mut),
          ),
          value: s.printedFollowTheme,
          activeThumbColor: t.acc,
          onChanged: n.setPrintedFollowTheme,
        ),
      ],
    );
  }
}

class _DownloadRow extends ConsumerWidget {
  const _DownloadRow({required this.edition});
  final ImageEdition edition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    // Only this set's progress: others' downloads needn't rebuild this row.
    final status = ref.watch(
      pageImageStoreProvider.select((m) => m[edition.id]!),
    );
    final store = ref.read(pageImageStoreProvider.notifier);
    final total = store.pageCount(edition);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.imageTitle(edition),
                  style: AppType.title(t.ink),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: status.cached / total,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  status.error != null
                      ? context.l10n.downloadStopped('${status.error}')
                      : context.l10n.downloadProgress(
                          status.cached,
                          total,
                          edition.approxTotalMb,
                        ),
                  style: AppType.caption(t.mut),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (status.running)
            IconButton(
              tooltip: context.l10n.pause,
              icon: const Icon(LucideIcons.pause),
              onPressed: () => store.cancel(edition),
            )
          else if (status.cached < total)
            IconButton(
              tooltip: context.l10n.downloadAll,
              icon: const Icon(LucideIcons.download),
              onPressed: () => savePrinted(context, ref, edition),
            ),
          if (status.cached > 0 && !status.running)
            IconButton(
              tooltip: context.l10n.deleteSaved,
              icon: const Icon(LucideIcons.trash2),
              onPressed: () => store.deleteAll(edition),
            ),
        ],
      ),
    );
  }
}

/// A few lines of Easy read at the chosen text size and word spacing: the
/// opening of Surah Al-Mulk, in the reader's script.
class _EasyReadPreview extends StatelessWidget {
  const _EasyReadPreview({required this.settings, required this.db});

  final Settings settings;
  final QuranDb db;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final typeface = settings.typeface;
    final edition = settings.textEdition;
    final page = db.page(edition, db.surahStartPage(edition, 67), typeface);
    final words = [
      for (final line in page.lines)
        if (line.kind == LineKind.text)
          for (final w in line.words)
            if (w.surah == 67) w,
    ].take(40).toList();
    final style = TextStyle(
      fontFamily: typeface.fontFamily,
      fontSize: settings.reflowFontSize,
      height: typeface.script == QuranScript.indopak ? 2.1 : 1.9,
      color: t.ink,
    );
    return Container(
      height: 220,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.hardEdge,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: double.infinity,
        child: QuranParagraph(
          units: QuranParagraph.unitsOf(words),
          typeface: typeface,
          style: style,
          markerStyle: style.copyWith(color: t.acc),
          wordGap: settings.reflowWordSpacing,
        ),
      ),
    );
  }
}
