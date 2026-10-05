// A Mushaf page shows as live text until its picture is prepared in idle
// time, then switches to the picture; freeing pictures on low memory is safe
// while one is on screen.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/theme.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/mushaf_text_page.dart';
import 'package:mushaf15/features/reader/page_snapshot.dart';
import 'package:mushaf15/features/reader/quran_line.dart';

void main() {
  late QuranDb db;

  setUpAll(() async {
    ShapePrefetcher.enabled = false;
    final bytes = File('assets/fonts/IndoPakNastaleeq.ttf').readAsBytesSync();
    await (FontLoader(
      'IndoPak',
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    db = QuranDb.openFile('assets/db/quran.db');
  });

  testWidgets('live page switches to its prepared picture', (tester) async {
    tester.view.physicalSize = const Size(411, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    PageSnapshots.enabled = true;
    addTearDown(() {
      PageSnapshots.clear();
      PageSnapshots.enabled = false;
    });

    final page = db.page('indopak-15-qudratullah', 562);
    Widget pageWidget(String key) => SnapshotPage(
      snapshotKey: key,
      page: () => MushafTextPage(page: page, db: db),
      label: '',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Palette.day),
        home: Scaffold(body: pageWidget('p562')),
      ),
    );

    // First frame: live text, picture queued.
    expect(find.byType(MushafTextPage), findsOneWidget);
    expect(find.byType(RawImage), findsNothing);

    // Idle time: the picture is drawn, and the page switches to it.
    for (var i = 0; i < 20 && find.byType(RawImage).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(RawImage), findsOneWidget);
    expect(find.byType(MushafTextPage), findsNothing);

    // Low memory while the picture is on screen: freeing it must be safe
    // (the screen keeps its own handle to the image).
    PageSnapshots.clear();
    await tester.pump();
    expect(tester.takeException(), isNull);

    PageSnapshots.enabled = false;
    await tester.pumpWidget(const SizedBox());
  });
}
