// Easy read remembers the ayah being read, not just the page: scrolled part
// of the way down a page and closed, a session opens again with that ayah at
// the top, and opening and closing it again and again doesn't move it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/data/library.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/page_snapshot.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/features/reader/reader_screen.dart';
import 'package:mushaf15/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late QuranDb db;
  const layout = 'indopak-15-qudratullah';
  const height = 860.0;

  setUpAll(() {
    ShapePrefetcher.enabled = false;
    PageSnapshots.enabled = false;
    db = QuranDb.openFile('assets/db/quran.db');
  });

  Future<ProviderContainer> start(
    WidgetTester tester, {
    required bool vertical,
    required bool translation,
    String mode = 'text',
  }) async {
    tester.view.physicalSize = const Size(411, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'language': 'en',
      'mode': mode,
      'textLayout': 'reflow',
      'reflowFontSize': 40.0,
      'verticalScroll': vertical,
      'reflowTranslation': translation,
      'translation': 'en-sahih',
      // Daily reading at Al-Baqarah 2:5, the top of a page.
      'lastSurah': 2,
      'lastAyah': 5,
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        quranDbProvider.overrideWithValue(db),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MushafApp()),
    );
    await tester.pumpAndSettle();
    return c;
  }

  (int, int) saved(ProviderContainer c) {
    final s = c.read(libraryProvider).session(Session.dailyId);
    return (s.surah, s.ayah);
  }

  Future<void> resume(WidgetTester tester) async {
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  Future<void> close(WidgetTester tester) async {
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  /// Where on screen the line [ayah] starts on is, or null if not laid out.
  double? startTop(WidgetTester tester, (int, int) ayah) {
    final id = db.firstWordOf(ayah.$1, ayah.$2);
    final root = tester.renderObject(find.byType(ReaderScreen));
    for (final (w, r) in collectPlacements(root)) {
      if (w.id == id && r.right > 0 && r.left < 411) return r.top;
    }
    return null;
  }

  for (final vertical in [false, true]) {
    for (final translation in [false, true]) {
      final how =
          '${vertical ? 'vertical' : 'paged'}'
          '${translation ? ', with translation' : ''}';
      testWidgets('$how: opens again at the ayah it was left at', (
        tester,
      ) async {
        final c = await start(
          tester,
          vertical: vertical,
          translation: translation,
        );
        final page = db.pageOfAyah(layout, 2, 5);
        await resume(tester);

        // Part of the way down the page, still on it.
        final scroll = vertical
            ? find.byType(CustomScrollView)
            : find.byType(ListView).hitTestable().first;
        // (With translations, past the first ayah's.)
        for (var i = 0; i < (translation ? 2 : 1); i++) {
          await tester.drag(scroll, const Offset(0, -700));
          await tester.pumpAndSettle(const Duration(milliseconds: 100));
        }
        await tester.pump(const Duration(seconds: 2)); // the save
        final place = saved(c);
        expect(place, isNot((2, 5)), reason: 'moved within the page');
        expect(db.pageOfAyah(layout, place.$1, place.$2), page);
        final top = startTop(tester, place)!;
        await close(tester);

        // Opened again (several times): the same ayah, at the top.
        for (var i = 0; i < 3; i++) {
          await resume(tester);
          await tester.pump(const Duration(seconds: 2));
          expect(saved(c), place, reason: 'opening $i');
          final again = startTop(tester, place)!;
          expect(again, inInclusiveRange(0, height * 0.3));
          // Where it was left. (Reading an ayah's translation, its start was
          // above the screen: it opens from the start of that ayah.)
          if (!translation) {
            expect((again - top).abs(), lessThan(height * 0.3));
          }
          await close(tester);
        }

        // Scrolled back to the top: the page's first ayah again.
        await resume(tester);
        await tester.drag(scroll, const Offset(0, 3000));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 2));
        if (!vertical) expect(saved(c), (2, 5));
        await close(tester);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 5));
      });
    }
  }

  testWidgets('a Mushaf page opened and left keeps the place within it', (
    tester,
  ) async {
    final c = await start(tester, vertical: false, translation: false);
    c.read(libraryProvider.notifier).setPosition(Session.dailyId, 2, 10);
    c.read(settingsProvider.notifier).setTextLayout(TextLayout.mushaf);
    await tester.pumpAndSettle();
    await resume(tester);
    await tester.pump(const Duration(seconds: 2));
    await close(tester);
    expect(saved(c), (2, 10));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
