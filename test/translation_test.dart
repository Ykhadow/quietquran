// Translations: complete, matched to the right ayah, and shown where the
// reader expects them.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/core/theme.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/features/reader/reflow_page.dart';
import 'package:mushaf15/features/reader/translation_text.dart';

void main() {
  late QuranDb db;

  setUpAll(() {
    ShapePrefetcher.enabled = false;
    db = QuranDb.openFile('assets/db/quran.db');
  });

  test('every translation has every ayah', () {
    expect(db.translations.map((t) => t.id), ['en-sahih', 'ur-jalandhari']);
    for (final t in db.translations) {
      for (final s in db.surahs) {
        for (var a = 1; a <= s.versesCount; a++) {
          final text = db.translationText(t.id, s.id, a);
          expect(text, isNotNull, reason: '${t.id} ${s.id}:$a');
          expect(text!.trim(), isNotEmpty, reason: '${t.id} ${s.id}:$a');
        }
      }
    }
  });

  test('known ayahs read as published', () {
    expect(
      db.translationText('en-sahih', 67, 1),
      'Blessed is He in whose hand is dominion, and He is over all things '
      'competent -',
    );
    expect(
      db.translationText('ur-jalandhari', 67, 1),
      'وہ (خدا) جس کے ہاتھ میں بادشاہی ہے بڑی برکت والا ہے۔ اور وہ ہر چیز '
      'پر قادر ہے',
    );
  });

  test('auto picks the reader\'s language', () {
    const s = Settings.defaults;
    expect(s.translationFor('ur'), 'ur-jalandhari');
    expect(s.translationFor('en'), 'en-sahih');
    expect(s.translationFor('ar'), isNull);
    expect(s.copyWith(translation: 'none').translationFor('ur'), isNull);
    expect(
      s.copyWith(translation: 'en-sahih').translationFor('ur'),
      'en-sahih',
    );
  });

  testWidgets('reflow puts each ayah\'s translation after that ayah', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 30000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Al-Mulk's opening page: ayahs 67:1 onwards.
    final page = db.page('indopak-15-qudratullah', 562);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Palette.day),
        home: Scaffold(
          body: ReflowPage(
            page: page,
            db: db,
            fontSize: 30,
            translation: db.translation('en-sahih'),
          ),
        ),
      ),
    );

    // Each translation sits below the last word of its own ayah and above
    // the first word of the next.
    double wordTop(int surah, int ayah, {required bool last}) {
      final tops = <double>[];
      for (final r in tester.allRenderObjects.whereType<RenderObject>()) {
        if (r is! RenderBox) continue;
        final w = r.debugCreator?.toString() ?? '';
        if (!w.startsWith('CustomPaint')) continue;
        final painter = (r as dynamic).painter;
        if (painter is! QuranLinePainter) continue;
        for (final (word, rect) in painter.place(r.size).$1) {
          if (word.surah == surah && word.ayah == ayah) {
            tops.add(r.localToGlobal(rect.topLeft).dy);
          }
        }
      }
      tops.sort();
      return last ? tops.last : tops.first;
    }

    final shown = tester
        .widgetList<TranslationText>(find.byType(TranslationText))
        .toList();
    expect(shown.first.text, db.translationText('en-sahih', 67, 1));
    for (var a = 1; a <= 3; a++) {
      final text = db.translationText('en-sahih', 67, a)!;
      final y = tester
          .getTopLeft(
            find.byWidgetPredicate(
              (w) => w is TranslationText && w.text == text,
            ),
          )
          .dy;
      expect(y, greaterThan(wordTop(67, a, last: true)), reason: '67:$a');
      expect(y, lessThan(wordTop(67, a + 1, last: false)), reason: '67:$a');
    }
  });
}
