// Pinching a Mushaf page zooms it; while zoomed a drag moves around the page
// instead of turning it; moving to another page zooms back out.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
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

  testWidgets('pinch zooms; zoomed pages pan instead of turning', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'language': 'en',
      'textLayout': 'mushaf', // zoom is for Mushaf pages
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          quranDbProvider.overrideWithValue(db),
        ],
        child: const MushafApp(),
      ),
    );
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    PageController controller() =>
        tester.widget<PageView>(find.byType(PageView)).controller!;
    bool locked() =>
        tester.widget<PageView>(find.byType(PageView)).physics
            is NeverScrollableScrollPhysics;
    double scale() => tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer).first)
        .transformationController!
        .value
        .getMaxScaleOnAxis();

    final start = controller().page;
    expect(locked(), isFalse);

    // Pinch out with two fingers.
    const centre = Offset(205, 450);
    final a = await tester.startGesture(centre - const Offset(30, 0));
    final b = await tester.startGesture(centre + const Offset(30, 0));
    for (var i = 1; i <= 10; i++) {
      await a.moveTo(centre - Offset(30.0 + i * 10, 0));
      await b.moveTo(centre + Offset(30.0 + i * 10, 0));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(scale(), greaterThan(1.5));
    expect(locked(), isTrue);

    // A swipe now pans the page; it doesn't turn it.
    await tester.fling(find.byType(PageView), const Offset(300, 0), 2000);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(controller().page, start);

    // Turning the page (keyboard) zooms back out and frees swipes.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(controller().page, isNot(start));
    expect(locked(), isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
