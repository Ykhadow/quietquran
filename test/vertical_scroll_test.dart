// Vertical reading: pages follow one another in one column, opening at the
// reader's page; scrolling on moves the reading position, which is saved, and
// switching back to page turning keeps the page.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/data/library.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/mushaf_text_page.dart';
import 'package:mushaf15/features/reader/page_snapshot.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/features/reader/reflow_page.dart';
import 'package:mushaf15/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late QuranDb db;

  setUpAll(() {
    ShapePrefetcher.enabled = false;
    PageSnapshots.enabled = false;
    db = QuranDb.openFile('assets/db/quran.db');
  });

  Future<ProviderContainer> start(WidgetTester tester, String layout) async {
    tester.view.physicalSize = const Size(411, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'language': 'en',
      'textLayout': layout,
      'verticalScroll': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        quranDbProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MushafApp()),
    );
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    return container;
  }

  int pageOf(ProviderContainer c) {
    final s = c.read(libraryProvider).session(Session.dailyId);
    return db.pageOfAyah('indopak-15-qudratullah', s.surah, s.ayah);
  }

  for (final layout in ['mushaf', 'reflow']) {
    testWidgets('$layout: scrolling down reads on, and the place is saved', (
      tester,
    ) async {
      final c = await start(tester, layout);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      if (layout == 'mushaf') {
        expect(find.byType(MushafTextPage), findsWidgets);
      } else {
        expect(find.byType(ReflowPage), findsWidgets);
      }
      expect(pageOf(c), 1);

      // Several screens down.
      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(seconds: 2)); // the save
      expect(pageOf(c), greaterThan(1));
      final read = pageOf(c);

      // Back to turning pages: the same page.
      c.read(settingsProvider.notifier).setVerticalScroll(false);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.byType(PageView), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(pageOf(c), read);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('a jump opens the column at that page', (tester) async {
    final c = await start(tester, 'mushaf');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));
    expect(pageOf(c), db.edition('indopak-15-qudratullah').pages);
    // And reading on upwards from there.
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 2));
    expect(pageOf(c), lessThan(db.edition('indopak-15-qudratullah').pages));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
