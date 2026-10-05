// Switching between text and printed pages (or between editions) changes the
// page numbering. The page shown must be the reader's page in the new
// numbering, and it must agree with the page named in the bottom bar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/data/image_editions.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/page_snapshot.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late QuranDb db;

  setUpAll(() {
    ShapePrefetcher.enabled = false;
    PageSnapshots.enabled = false;
    db = QuranDb.openFile('assets/db/quran.db');
  });

  testWidgets('text → printed → text → further → printed stays in step', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Text in the 16-line Taj layout; printed pages follow the 15-line one,
    // so the page numbers differ between the two.
    const text = 'indopak-16-taj';
    const printed = 'indopak-15-plain';
    final printedLayout = ImageEdition.byId(printed).layout;
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'language': 'en',
      'textEdition': text,
      'imageEdition': printed,
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
    final settings = container.read(settingsProvider.notifier);

    // Open the reader from Home (Resume on the Daily reading card).
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    /// The page the PageView is showing, in the current layout's numbering.
    int shown() {
      final c = tester.widget<PageView>(find.byType(PageView)).controller!;
      return c.page!.round() + 1;
    }

    /// The page the bottom bar names ("Juz 1 · 5 of 548").
    int named() {
      final meta = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .firstWhere((s) => RegExp(r'^Juz \d+ · \d+ of \d+$').hasMatch(s));
      return int.parse(RegExp(r'· (\d+) of').firstMatch(meta)!.group(1)!);
    }

    Future<void> turn(int pages) async {
      for (var i = 0; i < pages; i++) {
        // Next page is to the left.
        await tester.fling(find.byType(PageView), const Offset(300, 0), 2000);
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
      }
    }

    Future<void> setMode(ReadingMode m) async {
      settings.setMode(m);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    await turn(3);
    final textPage = shown();
    expect(named(), textPage);

    await setMode(ReadingMode.pages);
    final (s1, a1) = db.page(text, textPage).firstAyah;
    expect(shown(), db.pageOfAyah(printedLayout, s1, a1));
    expect(named(), shown());

    await setMode(ReadingMode.text);
    expect(named(), shown());

    await turn(20);
    final textPage2 = shown();
    expect(named(), textPage2);

    await setMode(ReadingMode.pages);
    final (s2, a2) = db.page(text, textPage2).firstAyah;
    expect(shown(), db.pageOfAyah(printedLayout, s2, a2));
    expect(named(), shown());

    // Leave the reader so its timers stop.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
