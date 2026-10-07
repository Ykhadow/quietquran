// Leak check: walks through the main flows with Flutter's leak tracker on,
// which fails if a disposable object (controllers, focus nodes, painters,
// images, notifiers…) is never disposed or is disposed but still held.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/page_snapshot.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/features/settings/palette_editor.dart';
import 'package:mushaf15/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late QuranDb db;

  setUpAll(() {
    ShapePrefetcher.enabled = false;
    PageSnapshots.enabled = false;
    db = QuranDb.openFile('assets/db/quran.db');
  });

  Future<void> app(WidgetTester tester, Map<String, Object> prefs) async {
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(p),
          quranDbProvider.overrideWithValue(db),
        ],
        child: const MushafApp(),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  final leaks = LeakTesting.settings
      .withTrackedAll()
      // Framework-internal notices unrelated to our code.
      .withIgnored(createdByTestHelpers: true);

  for (final layout in ['reflow', 'mushaf']) {
    testWidgets(
      'reader ($layout): pages, sheets, zoom, long press',
      experimentalLeakTesting: leaks,
      (tester) async {
        await app(tester, {
          'onboarded': true,
          'language': 'en',
          'textLayout': layout,
        });
        await tester.tap(find.text('Resume'));
        await settle(tester);
        for (var i = 0; i < 6; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          await settle(tester);
        }
        // Long press a word (opens the ayah sheet), then close it.
        await tester.longPressAt(const Offset(205, 420));
        await settle(tester);
        // Closes a bottom sheet if one is open (a press between words opens
        // none).
        Future<void> closeSheet() async {
          if (find.byType(BottomSheet).evaluate().isEmpty) return;
          tester.state<NavigatorState>(find.byType(Navigator).first).pop();
          await settle(tester);
        }

        await closeSheet();
        // Overlay and the Aa sheet.
        for (
          var i = 0;
          i < 2 &&
              find
                  .byIcon(LucideIcons.settings2)
                  .hitTestable()
                  .evaluate()
                  .isEmpty;
          i++
        ) {
          await tester.tapAt(const Offset(205, 450));
          await settle(tester);
        }
        await tester.tap(find.byIcon(LucideIcons.settings2));
        await settle(tester);
        await tester.tap(find.text('English'));
        await settle(tester);
        await tester.tap(find.text('Mushaf'));
        await settle(tester);
        await closeSheet();
        // Back home, then away.
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await settle(tester);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 5));
      },
    );
  }

  testWidgets(
    'settings, palette editor, sources',
    experimentalLeakTesting: leaks,
    (tester) async {
      await app(tester, {'onboarded': true, 'language': 'en'});
      NavigatorState nav() =>
          tester.state<NavigatorState>(find.byType(Navigator).first);
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester);
      // The palette editor (its colour picker has controllers to dispose).
      nav().push(
        MaterialPageRoute<void>(builder: (_) => const PaletteEditor()),
      );
      await settle(tester);
      await tester.drag(find.byType(Slider).first, const Offset(40, 0));
      await settle(tester);
      nav().pop();
      await settle(tester);
      await tester.scrollUntilVisible(
        find.text('Sources'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Sources'));
      await settle(tester);
      nav().pop();
      await settle(tester);
      nav().pop();
      await settle(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets('setup, all steps', experimentalLeakTesting: leaks, (
    tester,
  ) async {
    await app(tester, {'onboarded': false, 'language': 'en'});
    Future<void> next() async {
      await tester.tap(find.byType(FilledButton));
      await settle(tester);
    }

    Future<void> pick() async {
      await tester.tap(
        find
            .byWidgetPredicate(
              (w) =>
                  const {
                    '_ChoiceCard',
                    'PageChoice',
                  }.contains(w.runtimeType.toString()) ||
                  w is RadioListTile,
            )
            .first,
      );
      await settle(tester);
    }

    await next();
    await pick();
    await next();
    await pick();
    await next();
    await pick();
    await next();
    await next(); // text size
    await next(); // translation: start reading
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
