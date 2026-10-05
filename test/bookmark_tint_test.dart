// Bookmarked ayahs are tinted where they're read: a soft band behind their
// words, in reflow and on Mushaf pages, and nothing for other ayahs.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/core/theme.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/mushaf_text_page.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/features/reader/reflow_page.dart';

void main() {
  late QuranDb db;

  setUpAll(() {
    ShapePrefetcher.enabled = false;
    db = QuranDb.openFile('assets/db/quran.db');
  });

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(411, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Palette.day),
        home: Scaffold(body: page),
      ),
    );
  }

  /// The lines drawing a band, and the ayahs of their words.
  List<Set<(int, int)>> tinted(WidgetTester tester) => [
    for (final e in find.byType(CustomPaint).evaluate())
      if ((e.widget as CustomPaint).painter case final QuranLinePainter p
          when p.marked.isNotEmpty)
        if (p.words.any((w) => p.marked.contains((w.surah, w.ayah))))
          {for (final w in p.words) (w.surah, w.ayah)},
  ];

  for (final layout in TextLayout.values) {
    testWidgets('$layout: only the bookmarked ayah is tinted', (tester) async {
      final page = db.page('indopak-15-qudratullah', 562);
      const mark = (67, 3);
      await pump(
        tester,
        layout == TextLayout.reflow
            ? ReflowPage(page: page, db: db, fontSize: 28, marked: {mark})
            : MushafTextPage(page: page, db: db, marked: {mark}),
      );
      final lines = tinted(tester);
      expect(lines, isNotEmpty);
      for (final ayahs in lines) {
        expect(ayahs, contains(mark));
      }
      // Each tinted line draws its band before its words.
      final line = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter is QuranLinePainter &&
            (w.painter! as QuranLinePainter).words.any(
              (x) => (x.surah, x.ayah) == mark,
            ),
      );
      expect(tester.renderObject(line.first), paints..rrect());
    });
  }

  testWidgets('no bookmarks, no bands', (tester) async {
    await pump(
      tester,
      MushafTextPage(page: db.page('indopak-15-qudratullah', 562), db: db),
    );
    expect(tinted(tester), isEmpty);
  });
}
