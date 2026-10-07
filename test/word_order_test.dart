// Guards the reading order of rendered Quran text.
//
// For every rendered word, its on-screen position must follow the Quran's
// order: lines top to bottom, and within a line right to left. The test reads
// positions back from the laid-out widgets, so it catches any layout or bidi
// bug that puts a word or ayah marker in the wrong place — no eyeballing.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/core/theme.dart';
import 'package:mushaf15/data/models.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/mushaf_text_page.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/features/reader/quran_word.dart';
import 'package:mushaf15/features/reader/reflow_page.dart';
import 'package:mushaf15/features/reader/translation_text.dart';

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

/// Word ids in visual reading order: lines top to bottom, right to left.
List<int> _visualOrder(WidgetTester tester, MushafPage page) {
  final placed = <(Rect, Word)>[];
  // Skip the bismillah drawn above surahs (it repeats 1:1's word ids).
  bool skip(Word w) => page.number != 1 && w.surah == 1 && w.ayah == 1;
  for (final e in find.byType(QuranWord).evaluate()) {
    final w = (e.widget as QuranWord).word;
    if (!skip(w)) placed.add((tester.getRect(find.byWidget(e.widget)), w));
  }
  // Painted lines: each word's box exactly as QuranLinePainter draws it.
  for (final r in tester.allRenderObjects.whereType<RenderCustomPaint>()) {
    final painter = r.painter;
    if (painter is! QuranLinePainter) continue;
    final origin = r.localToGlobal(Offset.zero);
    for (final (w, rect) in painter.place(r.size).$1) {
      if (!skip(w)) placed.add((rect.shift(origin), w));
    }
  }
  // Group into visual lines by vertical overlap of the word boxes.
  placed.sort((a, b) => a.$1.center.dy.compareTo(b.$1.center.dy));
  final lines = <List<(Rect, Word)>>[];
  for (final p in placed) {
    final line = lines.isEmpty ? null : lines.last;
    if (line != null &&
        (p.$1.center.dy - line.first.$1.center.dy).abs() < p.$1.height / 2) {
      line.add(p);
    } else {
      lines.add([p]);
    }
  }
  return [
    for (final line in lines)
      ...(line..sort((a, b) => b.$1.center.dx.compareTo(a.$1.center.dx))).map(
        (p) => p.$2.id,
      ),
  ];
}

void _expectInOrder(List<int> ids, String where) {
  for (var i = 1; i < ids.length; i++) {
    if (ids[i] <= ids[i - 1]) {
      fail('$where: word ${ids[i]} is shown after word ${ids[i - 1]}');
    }
  }
}

void main() {
  late QuranDb db;

  setUpAll(() async {
    ShapePrefetcher.enabled = false;
    await _loadFont('IndoPak', 'assets/fonts/IndoPakNastaleeq.ttf');
    await _loadFont('UthmanicHafs', 'assets/fonts/UthmanicHafs.ttf');
    await _loadFont('KFGQPCNastaleeq', 'assets/fonts/KFGQPCNastaleeq.ttf');
    db = QuranDb.openFile('assets/db/quran.db');
  });

  // The app runs left to right in English and right to left in Urdu and
  // Arabic; the Quran text must come out the same either way.
  var ambient = TextDirection.ltr;

  Future<void> pump(WidgetTester tester, Size size, Widget child) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Palette.day),
        home: Scaffold(
          body: Directionality(textDirection: ambient, child: child),
        ),
      ),
    );
  }

  // Al-Fatihah's first ayah is its bismillah, which every print sets on a
  // line of its own; Easy read must too, even where the next words would
  // fit beside it (a wide page, with and without a translation).
  for (final typeface in QuranTypeface.values) {
    for (final tid in [null, 'en-sahih']) {
      testWidgets('reflow Al-Fatihah bismillah alone ${typeface.name} $tid', (
        tester,
      ) async {
        ambient = TextDirection.ltr;
        final p = db.page(typeface.script.defaultTextEdition, 1, typeface);
        await pump(
          tester,
          const Size(800, 20000),
          ReflowPage(
            page: p,
            db: db,
            fontSize: 30,
            translation: db.translation(tid),
          ),
        );
        final placed = collectPlacements(
          tester.renderObject(find.byType(ReflowPage)),
        );
        bool opening((Word, Rect) e) => (e.$1.surah, e.$1.ayah) == (1, 1);
        final rows = {
          for (final e in placed.where(opening)) e.$2.center.dy.round(),
        };
        expect(rows, hasLength(1), reason: 'the bismillah is one line');
        expect(
          placed
              .where((e) => !opening(e))
              .where((e) => (e.$2.center.dy - rows.first).abs() < 5),
          isEmpty,
          reason: 'nothing else shares its line',
        );
      });
    }
  }

  // Pages with known hazards (67:1-2, 4:36, 12:8, Ya-Sin, Al-Fatihah, the
  // last page) plus a spread of ordinary pages.
  const pages = [1, 2, 84, 236, 440, 562, 600, 610];

  for (final dir in TextDirection.values) {
    for (final typeface in QuranTypeface.values) {
      final edition = typeface.script.defaultTextEdition;
      for (final pageNo in pages) {
        MushafPage page() => db.page(
          edition,
          pageNo.clamp(1, db.edition(edition).pages),
          typeface,
        );

        // Phone and tablet widths, and a large text size that wraps a lot.
        for (final (width, fontSize) in [
          (411.0, 30.0),
          (411.0, 44.0),
          (800.0, 30.0),
        ]) {
          testWidgets(
            '${dir.name} reflow ${typeface.name} p$pageNo w$width f$fontSize',
            (tester) async {
              ambient = dir;
              final p = page();
              await pump(
                tester,
                Size(width, 20000),
                ReflowPage(page: p, db: db, fontSize: fontSize),
              );
              _expectInOrder(
                _visualOrder(tester, p),
                'reflow page ${p.number}',
              );
            },
          );
        }

        // With a translation under each ayah (the Quran text becomes one
        // paragraph per ayah, with translation text in between).
        for (final tid in ['en-sahih', 'ur-jalandhari']) {
          testWidgets('${dir.name} reflow+$tid ${typeface.name} p$pageNo', (
            tester,
          ) async {
            ambient = dir;
            final p = page();
            await pump(
              tester,
              const Size(411, 30000),
              ReflowPage(
                page: p,
                db: db,
                fontSize: 30,
                translation: db.translation(tid),
              ),
            );
            expect(find.byType(TranslationText), findsWidgets);
            _expectInOrder(
              _visualOrder(tester, p),
              'reflow+translation page ${p.number}',
            );
          });
        }

        testWidgets('${dir.name} mushaf page ${typeface.name} p$pageNo', (
          tester,
        ) async {
          ambient = dir;
          final p = page();
          await pump(
            tester,
            const Size(411, 700),
            MushafTextPage(page: p, db: db),
          );
          _expectInOrder(_visualOrder(tester, p), 'mushaf page ${p.number}');
        });
      }
    }
  }

  // Every page of every edition, both renderers. Slow, so opt-in:
  //   FULL_QURAN=1 flutter test test/word_order_test.dart
  if (Platform.environment['FULL_QURAN'] == '1') {
    for (final dir in TextDirection.values) {
      for (final edition in QuranDb.openFile('assets/db/quran.db').editions) {
        for (final typeface in QuranTypeface.forScript(edition.script)) {
          testWidgets(
            'ALL pages ${dir.name} ${edition.id} ${typeface.name}',
            (tester) async {
              ambient = dir;
              for (var n = 1; n <= edition.pages; n++) {
                final p = db.page(edition.id, n, typeface);
                await pump(
                  tester,
                  const Size(411, 20000),
                  ReflowPage(page: p, db: db, fontSize: 30),
                );
                _expectInOrder(
                  _visualOrder(tester, p),
                  '${edition.id} reflow page $n',
                );
                await pump(
                  tester,
                  const Size(411, 30000),
                  ReflowPage(
                    page: p,
                    db: db,
                    fontSize: 30,
                    translation: db.translation(
                      n.isEven ? 'en-sahih' : 'ur-jalandhari',
                    ),
                  ),
                );
                _expectInOrder(
                  _visualOrder(tester, p),
                  '${edition.id} reflow+translation page $n',
                );
                await pump(
                  tester,
                  const Size(411, 700),
                  MushafTextPage(page: p, db: db),
                );
                _expectInOrder(
                  _visualOrder(tester, p),
                  '${edition.id} mushaf page $n',
                );
              }
            },
            timeout: const Timeout(Duration(minutes: 30)),
          );
        }
      }
    }
  }
}
