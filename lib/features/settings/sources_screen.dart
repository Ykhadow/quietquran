import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/image_editions.dart';
import '../../data/quran_db.dart';
import '../../data/recitation.dart';
import '../audio/recitation_widgets.dart';
import '../../l10n/l10n.dart';
import '../../widgets/night.dart';

/// Where every part of the app's content comes from (mirrors SOURCES.md).
///
/// Quran text, layouts and metadata are read from the `sources` table the
/// build script writes into the database, so this page always describes the
/// data actually shipped.
class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final db = ref.watch(quranDbProvider);
    final recorded = db.sources;

    /// A row from the database's record, if the build recorded that part.
    _Source? fromDb(String what, String part) {
      final r = recorded[part];
      if (r == null) return null;
      return _Source(what, r.$1, r.$2.isEmpty ? null : r.$2);
    }

    Widget section(String title, List<_Source?> rows, {String? note}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Eyebrow(title),
        if (note != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(note, style: AppType.caption(t.mut)),
          ),
        GroupedCard(
          children: [for (final r in rows.nonNulls) _SourceRow(source: r)],
        ),
      ],
    );

    const qulFont = 'https://qul.tarteel.ai/resources/font/';
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
        title: Text(l.sources),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(
                  l.sourcesIntro,
                  style: AppType.body(t.ink).copyWith(height: 1.5),
                ),
              ),
              _SourceRow.link(
                'QUL · Quranic Universal Library',
                'https://qul.tarteel.ai',
              ),
              section(l.srcText, [
                fromDb(
                  l.typefaceLabel(QuranTypeface.indopakNastaleeq),
                  'words.indopak',
                ),
                fromDb(
                  l.typefaceLabel(QuranTypeface.kfgqpcNastaleeq),
                  'words.qpc_nastaleeq',
                ),
                fromDb(l.typefaceLabel(QuranTypeface.qpcHafs), 'words.madani'),
              ]),
              section(l.srcTranslations, note: l.srcTranslationsNote, [
                for (final tr in db.translations)
                  switch (fromDb(tr.translator, 'translation:${tr.id}')) {
                    final r? => _Source(
                      tr.translator,
                      [r.from, ?_publisher[tr.id]].join(' · '),
                      r.url,
                    ),
                    null => null,
                  },
              ]),
              section(l.recitation, note: l.srcRecitationNote, [
                for (final r in Reciter.all)
                  _Source(
                    reciterName(context, r),
                    'EveryAyah · ${r.folder}',
                    'https://everyayah.com/data/${r.folder}/',
                  ),
              ]),
              section(l.srcTranslationVoices, [
                for (final v in TranslationVoice.all)
                  _Source(
                    [
                      v.name,
                      ?db.translation(v.translationId)?.translator,
                    ].join(' · '),
                    'EveryAyah · ${v.folder}',
                    'https://everyayah.com/data/${v.folder}/',
                  ),
              ]),
              section(l.srcLayouts, note: l.srcLayoutsNote, [
                for (final e in db.editions)
                  fromDb(l.editionName(e), 'lines:${e.id}'),
              ]),
              section(l.srcFonts, [
                // Credited as its makers ask (see docs/permissions).
                const _Source(
                  'AlQuran IndoPak by QuranWBW',
                  'Ayman Siddiqui, QuranWBW, based on the Al Qalam Quran '
                      'Majeed fonts. © Al Qalam · © Ghandhara · © KFGQPC · '
                      '© Ayman Siddiqui. Credits: Abdul Majeed Khan, Arif '
                      'Karim, Shakir-ul-Qadree, Jawad. Used with the '
                      'permission of QuranWBW.',
                  'https://quranwbw.com',
                ),
                _Source(
                  l.typefaceLabel(QuranTypeface.kfgqpcNastaleeq),
                  'QUL · KFGQPCNastaleeq.ttf',
                  '${qulFont}462',
                ),
                _Source(
                  l.typefaceLabel(QuranTypeface.qpcHafs),
                  'QUL · UthmanicHafs.ttf (V22)',
                  '${qulFont}245',
                ),
                _Source(
                  l.surahTitles,
                  'QUL · surah-name-v2.ttf',
                  '${qulFont}455',
                ),
              ]),
              section(l.srcMetadata, [
                fromDb(l.metaSurahs, 'metadata:surahs'),
                fromDb(l.metaAyahs, 'metadata:ayahs'),
                fromDb(l.metaJuz, 'metadata:juz'),
                fromDb(l.metaHizb, 'metadata:hizb'),
                fromDb(l.metaRub, 'metadata:rub'),
                fromDb(l.metaManzil, 'metadata:manzil'),
                fromDb(l.metaRuku, 'metadata:ruku'),
                fromDb(l.metaSajda, 'metadata:sajda'),
              ]),
              section(l.srcPrinted, note: l.srcPrintedNote, [
                for (final e in ImageEdition.all)
                  _Source(
                    '${l.scriptLabel(e.script)} · ${l.imageTitle(e)}',
                    [
                      e.credit ?? e.host,
                      if (e.thanks case final name?) l.imageThanks(name),
                    ].join('\n'),
                    e.creditUrl ?? e.hostUrl,
                  ),
              ]),
              section(l.srcOther, note: l.srcOtherNote, [
                fromDb(l.otherMeanings, 'surahs.name_translated'),
                _Source(l.otherHeaders, l.writtenInApp, null),
                _Source(l.otherMarkers, l.otherMarkersSource, null),
                _Source(l.otherLineFit, l.otherLineFitSource, null),
              ]),
              section(l.srcAppFonts, [
                const _Source(
                  'Newsreader · Source Sans 3 · Amiri · Noto Naskh Arabic · '
                      'Noto Nastaliq Urdu',
                  '',
                  'https://fonts.google.com',
                ),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(l.appFontsSource, style: AppType.caption(t.mut)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rights holders to credit with a translation, where it isn't in the
/// public domain.
const _publisher = {'en-sahih': '© Dar Abul-Qasim / Al-Muntada Al-Islami'};

class _Source {
  const _Source(this.what, this.from, this.url);

  /// The part of the app ("IndoPak Nastaleeq", "Juz").
  final String what;

  /// Where it comes from, as named by its publisher.
  final String from;
  final String? url;
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source});

  /// A lone link, outside a card.
  static Widget link(String label, String url) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Builder(
        builder: (context) => TextButton.icon(
          onPressed: () => _open(url),
          icon: const Icon(LucideIcons.externalLink, size: 16),
          label: Text(label),
        ),
      ),
    ),
  );

  final _Source source;

  static void _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final url = source.url;
    return InkWell(
      onTap: url == null ? null : () => _open(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(source.what, style: AppType.title(t.ink)),
                  if (source.from.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(source.from, style: AppType.caption(t.mut)),
                  ],
                  if (url != null) ...[
                    const SizedBox(height: 2),
                    // Links read left to right in every language.
                    Text(
                      url.replaceFirst('https://', ''),
                      textDirection: TextDirection.ltr,
                      style: AppType.small(t.acc),
                    ),
                  ],
                ],
              ),
            ),
            if (url != null)
              Semantics(
                label: context.l10n.openLink,
                child: SizedBox(
                  width: 40,
                  child: Icon(LucideIcons.externalLink, size: 16, color: t.mut),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
