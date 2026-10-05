// Renders real Mushaf pages with the bundled fonts, for visual review.
// Regenerate with: flutter test --update-goldens test/mushaf_page_golden_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/core/theme.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/mushaf_text_page.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/features/reader/reflow_page.dart';

import 'indopak_font.dart';

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
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

  // Opening page, a mid-book surah start, and the last page of each edition.
  const samples = {
    'indopak-15-qudratullah': [1, 440, 610],
    'indopak-16-taj': [2, 396, 548],
    'indopak-13-qudratullah': [611, 849],
    'indopak-13-taj': [610],
    'indopak-9-gaba': [151],
    'madani-1405': [1, 50, 604],
    'madani-1421': [50],
  };
  final cases = [
    for (final MapEntry(key: edition, value: pages) in samples.entries)
      for (final page in pages) (edition, page, null),
    // The alternative IndoPak typeface on the same layouts.
    for (final (edition, page) in [
      ('indopak-15-qudratullah', 1),
      ('indopak-15-qudratullah', 440),
      ('indopak-16-taj', 396),
      ('indopak-13-qudratullah', 611),
    ])
      (edition, page, QuranTypeface.kfgqpcNastaleeq),
  ];
  for (final (edition, page, typeface) in cases) {
    final name = [edition, page, ?typeface?.name].join('_');
    {
      // IndoPak layouts draw in the IndoPak font unless another is given.
      final indopak = typeface == null ? edition.startsWith('indopak') : false;
      testWidgets(name, tags: indopak ? indopakFont : null, (tester) async {
        tester.view.physicalSize = const Size(640, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(Palette.day),
            home: Scaffold(
              backgroundColor: Palette.day.bg,
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: MushafTextPage(
                  page: db.page(edition, page, typeface),
                  db: db,
                ),
              ),
            ),
          ),
        );
        await expectLater(
          find.byType(MushafTextPage),
          matchesGoldenFile('goldens/$name.png'),
        );
      });
    }
  }
  reflowGoldens();
}

/// Reflow view of pages with known hazards: 67:1-2 and 4:36 put two
/// left-to-right private-use characters side by side across a word gap, and
/// most pages have words with an internal space before a waqf sign.
void reflowGoldens() {
  late QuranDb db;
  setUpAll(() async {
    db = QuranDb.openFile('assets/db/quran.db');
  });
  for (final (page, typeface) in [
    (562, QuranTypeface.indopakNastaleeq),
    (84, QuranTypeface.indopakNastaleeq),
    (562, QuranTypeface.kfgqpcNastaleeq),
  ]) {
    testWidgets(
      'reflow $page ${typeface.name}',
      tags: typeface == QuranTypeface.indopakNastaleeq ? indopakFont : null,
      (tester) async {
        tester.view.physicalSize = const Size(640, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(Palette.day),
            home: Scaffold(
              backgroundColor: Palette.day.bg,
              body: ReflowPage(
                page: db.page('indopak-15-qudratullah', page, typeface),
                db: db,
                fontSize: 30,
              ),
            ),
          ),
        );
        await expectLater(
          find.byType(ReflowPage),
          matchesGoldenFile('goldens/reflow_${page}_${typeface.name}.png'),
        );
      },
    );
  }
}
