// A long press on a word must identify that word's ayah.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/theme.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/mushaf_text_page.dart';
import 'package:mushaf15/features/reader/page_snapshot.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/features/reader/reflow_page.dart';

void main() {
  late QuranDb db;

  setUpAll(() async {
    ShapePrefetcher.enabled = false;
    PageSnapshots.enabled = false;
    final bytes = File('assets/fonts/IndoPakNastaleeq.ttf').readAsBytesSync();
    await (FontLoader(
      'IndoPak',
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    db = QuranDb.openFile('assets/db/quran.db');
  });

  testWidgets('long press finds the ayah under the finger', (tester) async {
    tester.view.physicalSize = const Size(411, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final page = db.page('indopak-15-qudratullah', 562);
    (int, int)? pressed;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Palette.night),
        home: Scaffold(
          body: SnapshotPage(
            snapshotKey: 'p562',
            page: () => MushafTextPage(page: page, db: db),
            label: '',
            onAyahLongPress: (s, a) => pressed = (s, a),
          ),
        ),
      ),
    );

    // Press the centre of several words, read from what was painted.
    final placed = <(int, int, Offset)>[];
    for (final r in tester.allRenderObjects.whereType<RenderCustomPaint>()) {
      final painter = r.painter;
      if (painter is! QuranLinePainter) continue;
      final origin = r.localToGlobal(Offset.zero);
      for (final (w, rect) in painter.place(r.size).$1) {
        if (w.surah == 67) {
          placed.add((w.surah, w.ayah, rect.shift(origin).center));
        }
      }
    }
    expect(placed, isNotEmpty);
    for (final (surah, ayah, centre) in [
      placed.first,
      placed[placed.length ~/ 2],
      placed.last,
    ]) {
      pressed = null;
      await tester.longPressAt(centre);
      await tester.pump();
      expect(pressed, (surah, ayah), reason: 'pressed at $centre');
    }
  });

  testWidgets('long press in reflow finds the ayah, after scrolling too', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final page = db.page('indopak-15-qudratullah', 562);
    (int, int)? pressed;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Palette.night),
        home: Scaffold(
          body: ReflowPage(
            page: page,
            db: db,
            fontSize: 40,
            onAyahLongPress: (s, a) => pressed = (s, a),
          ),
        ),
      ),
    );

    Future<void> pressWords() async {
      final placed = <(int, int, Offset)>[];
      // Only words in view: the list lays out a little beyond its edges,
      // under the running head and the page number.
      final view = tester.getRect(find.byType(ListView)).deflate(8);
      for (final r in tester.allRenderObjects.whereType<RenderCustomPaint>()) {
        final painter = r.painter;
        if (painter is! QuranLinePainter) continue;
        final origin = r.localToGlobal(Offset.zero);
        for (final (w, rect) in painter.place(r.size).$1) {
          final c = rect.shift(origin).center;
          if (w.surah == 67 && view.contains(c)) {
            placed.add((w.surah, w.ayah, c));
          }
        }
      }
      expect(placed, isNotEmpty);
      for (final (surah, ayah, centre) in [
        placed.first,
        placed[placed.length ~/ 2],
        placed.last,
      ]) {
        pressed = null;
        await tester.longPressAt(centre);
        await tester.pump();
        expect(pressed, (surah, ayah), reason: 'pressed at $centre');
      }
    }

    await pressWords();
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await pressWords();
  });
}
