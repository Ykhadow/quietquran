// Opening a surah in Easy read lands on the surah, not on the top of the page
// it starts on: Al-Falaq and An-Nas share a page.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/data/library.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/mushaf_text_page.dart';
import 'package:mushaf15/features/reader/page_snapshot.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/features/reader/reader_screen.dart';
import 'package:mushaf15/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late QuranDb db;
  const layout = 'indopak-15-qudratullah';

  setUpAll(() {
    ShapePrefetcher.enabled = false;
    PageSnapshots.enabled = false;
    db = QuranDb.openFile('assets/db/quran.db');
  });

  Future<ProviderContainer> app(WidgetTester tester, bool vertical) async {
    tester.view.physicalSize = const Size(411, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'language': 'en',
      'textLayout': 'reflow',
      'reflowFontSize': 40.0,
      'verticalScroll': vertical,
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
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> open(WidgetTester tester, bool vertical, int? surah) async {
    await app(tester, vertical);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ReaderScreen(
              initialPage: db.surahStartPage(layout, 114),
              at: surah == null ? null : (surah, 1),
            ),
          ),
        );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  /// Where the surah's header is on screen; infinite when not built at all
  /// (a long way below, in a page's own list).
  double headerTop(WidgetTester tester, int surah) {
    final f = find.byWidgetPredicate(
      (w) => w is SurahHeader && w.surah.id == surah,
    );
    return f.evaluate().isEmpty ? double.infinity : tester.getTopLeft(f).dy;
  }

  for (final vertical in [false, true]) {
    final how = vertical ? 'vertical' : 'paged';
    testWidgets('$how: An-Nas opens at its header', (tester) async {
      expect(db.surahStartPage(layout, 114), db.surahStartPage(layout, 113));
      await open(tester, vertical, null);
      final unrevealed = headerTop(tester, 114);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));

      await open(tester, vertical, 114);
      final top = headerTop(tester, 114);
      expect(unrevealed, greaterThan(860), reason: 'below the screen as is');
      expect(top, inInclusiveRange(0, 200));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('a new or started-again session opens at its surah', (
    tester,
  ) async {
    final c = await app(tester, false);
    final lib = c.read(libraryProvider.notifier);
    final night = lib.add(name: 'Night', surah: 114, ayah: 1);
    await tester.pumpAndSettle();

    Future<double> openNight() async {
      await tester.tap(find.text('Night'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      final top = headerTop(tester, 114);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      return top;
    }

    expect(await openNight(), inInclusiveRange(0, 200));
    // Read on: it resumes at the top of the page, where it was saved.
    lib.setPosition(night, 113, 1);
    await tester.pumpAndSettle();
    expect(await openNight(), greaterThan(860));
    // Started again: at the surah once more.
    lib.startAgain(night);
    await tester.pumpAndSettle();
    expect(await openNight(), inInclusiveRange(0, 200));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
