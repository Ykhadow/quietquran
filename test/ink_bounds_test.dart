// Nothing of the Quran may be cut off or moved.
//
// 1. No word's ink, as Flutter draws it, reaches past its box further than
//    the database records (word_ink, measured with HarfBuzz): lines keep
//    exactly that room at their ends. Fonts place some signs outside a
//    word's box on purpose, e.g. a waqf sign after a zero-width space
//    ("يَوۡمٍ ؕ"), which sits in the gap before the next word.
// 2. Every line, as the app draws it, keeps its ink inside the line: on
//    Mushaf pages and in Easy read at several sizes. A few pages always;
//    every page with INK_AUDIT=1 (a few minutes):
//
//      INK_AUDIT=1 flutter test test/ink_bounds_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/core/theme.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/mushaf_text_page.dart';
import 'package:mushaf15/features/reader/page_snapshot.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/features/reader/reflow_page.dart';
import 'package:sqlite3/sqlite3.dart';

import 'indopak_font.dart';

Future<void> _font(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

/// The leftmost and rightmost columns with ink in each band of rows.
List<(int, int)?> _inkColumns(ByteData px, int width, List<(int, int)> bands) {
  return [
    for (final (top, bottom) in bands)
      () {
        int? lo, hi;
        for (var y = top; y < bottom; y++) {
          for (var x = 0; x < width; x++) {
            if (px.getUint8((y * width + x) * 4 + 3) > 24) {
              lo = lo == null ? x : math.min(lo, x);
              hi = hi == null ? x : math.max(hi, x);
            }
          }
        }
        return lo == null ? null : (lo, hi!);
      }(),
  ];
}

void main() {
  late QuranDb db;
  final full = Platform.environment['INK_AUDIT'] != null;

  setUpAll(() async {
    ShapePrefetcher.enabled = false;
    PageSnapshots.enabled = false;
    db = QuranDb.openFile('assets/db/quran.db');
  });

  Future<void> loadFonts(WidgetTester tester) => tester.runAsync(() async {
    await _font('IndoPak', 'assets/fonts/IndoPakNastaleeq.ttf');
    await _font('KFGQPCNastaleeq', 'assets/fonts/KFGQPCNastaleeq.ttf');
    await _font('UthmanicHafs', 'assets/fonts/UthmanicHafs.ttf');
    await _font('SurahName', 'assets/fonts/SurahNameV2.ttf');
  });

  testWidgets(
    'no word ink reaches past its box beyond what is recorded',
    (tester) async {
      await loadFonts(tester);
      final raw = sqlite3.open('assets/db/quran.db', mode: OpenMode.readOnly);
      addTearDown(raw.close);
      const size = 40.0;
      var checked = 0;
      for (final (column, family) in const [
        ('indopak', 'IndoPak'),
        ('qpc_nastaleeq', 'KFGQPCNastaleeq'),
        ('madani', 'UthmanicHafs'),
      ]) {
        final ink =
            raw.select('SELECT data FROM word_ink WHERE column_name = ?', [
                  column,
                ]).first['data']
                as Uint8List;
        // Each distinct text once, with the first word that has it. The app
        // draws its own markers for qpc_nastaleeq's ayah ends.
        final first = <String, int>{};
        for (final r in raw.select(
          'SELECT id, is_end, $column AS t FROM words ORDER BY id',
        )) {
          if (column == 'qpc_nastaleeq' && r['is_end'] == 1) continue;
          first.putIfAbsent(r['t'] as String, () => r['id'] as int);
        }
        // Every word with an inner space (where waqf signs sit), and the rest
        // too in the full audit, or a spread of them.
        final texts = [
          for (final (i, t) in first.keys.indexed)
            if (full || t.contains(' ') || i % 25 == 0) t,
        ];
        final style = TextStyle(fontFamily: family, fontSize: size);
        // Many words per picture, one per row, to keep it quick.
        const perImage = 40;
        const rowH = 120.0;
        const margin = 60.0;
        for (var start = 0; start < texts.length; start += perImage) {
          final batch = texts.sublist(
            start,
            math.min(texts.length, start + perImage),
          );
          final rec = ui.PictureRecorder();
          final canvas = Canvas(rec);
          var widest = 0.0;
          final widths = <double>[];
          for (final (row, t) in batch.indexed) {
            final tp = TextPainter(
              text: TextSpan(text: t, style: style),
              textDirection: TextDirection.rtl,
              maxLines: 1,
            )..layout();
            tp.paint(canvas, Offset(margin, row * rowH + 30));
            widths.add(tp.width);
            widest = math.max(widest, tp.width + margin * 2);
            tp.dispose();
          }
          final width = widest.ceil();
          final px = (await tester.runAsync(() async {
            final image = await rec.endRecording().toImage(
              width,
              (batch.length * rowH).ceil(),
            );
            final data = await image.toByteData();
            image.dispose();
            return data!;
          }))!;
          final columns = _inkColumns(px, width, [
            for (var row = 0; row < batch.length; row++)
              ((row * rowH).toInt(), ((row + 1) * rowH).toInt()),
          ]);
          for (final (row, t) in batch.indexed) {
            final found = columns[row];
            if (found == null) continue;
            final (lo, hi) = found;
            final id = first[t]!;
            final pastLeft = ink[(id - 1) * 2] / 100 * size;
            final pastRight = ink[(id - 1) * 2 + 1] / 100 * size;
            expect(
              lo - margin >= -pastLeft - 1.5 &&
                  hi - margin <= widths[row] + pastRight + 1.5,
              isTrue,
              reason:
                  '$column "$t" (word $id): ink ${lo - margin}..'
                  '${hi - margin}, box 0..${widths[row].toStringAsFixed(1)}, '
                  'recorded past it ${pastLeft.toStringAsFixed(1)} / '
                  '${pastRight.toStringAsFixed(1)}',
            );
          }
          checked += batch.length;
        }
      }
      debugPrint('checked $checked words');
      expect(checked, greaterThan(5000));
    },
    timeout: const Timeout(Duration(minutes: 30)),
    tags: indopakFont,
  );

  /// Draws every Quran line [build] shows, each on its own row, and returns
  /// the lines whose ink leaves the line's width.
  Future<List<String>> overflowing(
    WidgetTester tester,
    Widget page,
    String where,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Palette.day),
        home: Scaffold(body: page),
      ),
    );
    final lines = [
      for (final r in tester.allRenderObjects.whereType<RenderCustomPaint>())
        if (r.painter case final QuranLinePainter p
            when r.attached && r.hasSize && p.words.isNotEmpty)
          (p, r.size),
    ];
    const margin = 40.0;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    var y = 0.0;
    var widest = 0.0;
    final bands = <(int, int)>[];
    for (final (p, s) in lines) {
      final rowTop = y;
      canvas.save();
      canvas.translate(margin, y + s.height / 2);
      p.paint(canvas, s);
      canvas.restore();
      y += s.height * 2;
      bands.add((rowTop.floor(), y.floor()));
      widest = math.max(widest, s.width + margin * 2);
    }
    final width = widest.ceil();
    final px = (await tester.runAsync(() async {
      final image = await rec.endRecording().toImage(width, y.ceil());
      final data = await image.toByteData();
      image.dispose();
      return data!;
    }))!;
    final ink = _inkColumns(px, width, bands);
    return [
      for (final (i, (p, s)) in lines.indexed)
        if (ink[i] case (
          final lo,
          final hi,
        ) when lo - margin < -1 || hi - margin > s.width + 1)
          '$where line ${i + 1}: ink ${(lo - margin).toStringAsFixed(0)}'
              '..${(hi - margin).toStringAsFixed(0)} of '
              '0..${s.width.toStringAsFixed(0)}, ending '
              '${p.words.last.surah}:${p.words.last.ayah} "${p.words.last.text}"',
    ];
  }

  Iterable<int> pagesOf(String edition) => full
      ? [for (var n = 1; n <= db.edition(edition).pages; n++) n]
      : [1, 2, 3, 50, 295, 296, 400, 562, db.edition(edition).pages];

  for (final (edition, typeface) in const [
    ('indopak-15-qudratullah', QuranTypeface.indopakNastaleeq),
    ('indopak-15-qudratullah', QuranTypeface.kfgqpcNastaleeq),
    ('madani-1405', QuranTypeface.qpcHafs),
  ]) {
    testWidgets(
      '$edition ${typeface.name}: no ink leaves its line',
      (tester) async {
        await loadFonts(tester);
        final problems = <String>[];
        // Mushaf pages at a phone's size, and Easy read at small, usual and
        // large text with the default spacing.
        tester.view.physicalSize = const Size(411, 860);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final n in pagesOf(edition)) {
          final page = db.page(edition, n, typeface);
          problems.addAll(
            await overflowing(
              tester,
              MushafTextPage(page: page, db: db),
              'mushaf p$n',
            ),
          );
          for (final size in const [24.0, 30.0, 44.0]) {
            problems.addAll(
              await overflowing(
                tester,
                SingleChildScrollView(
                  child: ReflowPage(
                    page: page,
                    db: db,
                    fontSize: size,
                    scrolls: false,
                  ),
                ),
                'easy read $size p$n',
              ),
            );
          }
        }
        expect(problems, isEmpty, reason: problems.take(40).join('\n'));
      },
      timeout: const Timeout(Duration(minutes: 30)),
      tags: typeface == QuranTypeface.indopakNastaleeq ? indopakFont : null,
    );
  }
}
