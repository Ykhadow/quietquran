import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/library.dart';
import '../../data/quran_db.dart';
import 'quran_word.dart';
import 'share_card.dart';
import 'translation_text.dart';
import '../../l10n/l10n.dart';

/// Actions for one ayah (opened by a long press on the page). [onListen]
/// starts the recitation from it.
Future<void> showAyahSheet(
  BuildContext context,
  int surah,
  int ayah, {
  VoidCallback? onListen,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) =>
      _AyahSheet(surah: surah, ayah: ayah, onListen: onListen),
);

class _AyahSheet extends ConsumerWidget {
  const _AyahSheet({required this.surah, required this.ayah, this.onListen});

  final int surah;
  final int ayah;
  final VoidCallback? onListen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final db = ref.watch(quranDbProvider);
    final settings = ref.watch(settingsProvider);
    final typeface = settings.typeface;
    final translation = db.translation(
      settings.translationFor(context.l10n.localeName),
    );
    final translated = translation == null
        ? null
        : db.translationText(translation.id, surah, ayah);
    final bookmarked = ref.watch(
      libraryProvider.select((l) => l.isBookmarked(surah, ayah)),
    );
    // Whole ayah, marker included.
    final words = db.ayahTail(surah, ayah, typeface, count: 1000);
    final quran = TextStyle(
      fontFamily: typeface.fontFamily,
      fontSize: 26,
      height: 2,
      color: t.ink,
    );
    final reference = '${context.surahName(db.surah(surah))} $surah:$ayah';
    final l = context.l10n;

    Widget action(
      IconData icon,
      String label,
      VoidCallback onTap, {
      bool on = false,
    }) => Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, color: on ? t.acc : t.ink, size: 22),
              const SizedBox(height: 6),
              Text(label, style: AppType.small(on ? t.acc : t.mut)),
            ],
          ),
        ),
      ),
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(reference, style: AppType.titleLg(t.ink)),
              const SizedBox(height: 12),
              // Word by word, right to left: order can't be disturbed by
              // bidi rules (see QuranWord).
              Wrap(
                textDirection: TextDirection.rtl,
                alignment: WrapAlignment.start,
                spacing: 8,
                children: [
                  for (final w in words)
                    QuranWord(
                      word: w,
                      typeface: typeface,
                      style: quran,
                      markerStyle: quran.copyWith(color: t.acc),
                    ),
                ],
              ),
              if (translation != null && translated != null) ...[
                const SizedBox(height: 14),
                TranslationText(translation: translation, text: translated),
                const SizedBox(height: 6),
                Text(
                  l.translationBy(translation.translator),
                  style: AppType.small(t.mut),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onListen case final listen?)
                    action(LucideIcons.play, l.listen, () {
                      Navigator.pop(context);
                      listen();
                    }),
                  action(
                    bookmarked
                        ? LucideIcons.bookmarkCheck
                        : LucideIcons.bookmark,
                    bookmarked ? l.bookmarked : l.bookmark,
                    () => ref
                        .read(libraryProvider.notifier)
                        .toggleBookmark(surah, ayah),
                    on: bookmarked,
                  ),
                  action(LucideIcons.copy, l.copy, () {
                    // Standard Unicode text (KFGQPC Hafs, from QUL) so it
                    // displays in any app; the IndoPak font's private-use
                    // characters would not.
                    final text = db
                        .ayahTail(
                          surah,
                          ayah,
                          QuranTypeface.qpcHafs,
                          count: 1000,
                        )
                        .where((w) => !w.isAyahEnd)
                        .map((w) => w.text)
                        .join(' ');
                    Clipboard.setData(
                      ClipboardData(text: '$text\n— $reference'),
                    );
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    Navigator.pop(context);
                    messenger?.showSnackBar(
                      SnackBar(content: Text(l.copied(reference))),
                    );
                  }),
                  action(LucideIcons.share2, l.share, () {
                    final navigator = Navigator.of(context);
                    final reader = navigator.context;
                    navigator.pop();
                    showShareSheet(reader, surah, ayah);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
