// The reader's Aa sheet switches theme and translation; first-run setup ends
// with a translation choice.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/data/library.dart';
import 'package:mushaf15/data/quran_db.dart';
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
    // Saved printed pages live in the app's folder: an empty one here.
    final folder = Directory.systemTemp.createTempSync('quietquran_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => folder.path,
        );
  });

  Future<ProviderContainer> start(
    WidgetTester tester, {
    required bool onboarded,
    String textLayout = 'reflow',
  }) async {
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'onboarded': onboarded,
      'language': 'en',
      'textLayout': textLayout,
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
    return container;
  }

  testWidgets('Aa sheet: view, translation and Day/Night', (tester) async {
    final c = await start(tester, onboarded: true);
    Settings s() => c.read(settingsProvider);
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Show the overlay, then open the Aa sheet.
    await tester.tapAt(const Offset(205, 450));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.byIcon(LucideIcons.settings2));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    // Fixed waits: printed pages show an endless loading animation here.
    Future<void> tap(Finder f) async {
      await tester.tap(f);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    // Reflow is the default.
    expect(s().textLayout, TextLayout.reflow);

    // In Reflow, a language shows the translation under each ayah; Off hides
    // it there but keeps it for a held ayah.
    await tap(find.text('Urdu'));
    expect(s().translation, 'ur-jalandhari');
    expect(s().reflowTranslation, isTrue);
    await tap(find.text('None'));
    expect(s().reflowTranslation, isFalse);
    expect(s().translationFor('en'), 'ur-jalandhari');

    // Switch to Mushaf pages; there, None turns the translation off.
    await tap(find.text('Mushaf'));
    expect(s().mode, ReadingMode.text);
    expect(s().textLayout, TextLayout.mushaf);
    await tap(find.text('None'));
    expect(s().translationFor('en'), isNull);

    // Printed pages open at once, asking whether to save the whole set
    // (in the background) or load pages as they're read.
    await tester.tap(find.text('Printed'));
    // Counting the saved pages reads the disk: real time, not the test's.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(s().mode, ReadingMode.pages);
    expect(
      find.text('Save printed pages for offline reading?'),
      findsOneWidget,
    );
    await tap(find.text('Load as I read'));
    expect(s().mode, ReadingMode.pages);
    await tap(find.text('Easy read'));
    expect(s().mode, ReadingMode.text);
    expect(s().textLayout, TextLayout.reflow);

    // Day/Night icons.
    await tap(find.byTooltip('Night'));
    expect(s().appearance, 'night');
    await tap(find.byTooltip('Auto'));
    expect(s().appearance, 'system');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  // Four steps: language, script, text or printed, translation. The
  // edition starts as the usual one and text size is set while reading.
  testWidgets('setup ends with a translation choice', (tester) async {
    final c = await start(tester, onboarded: false);
    Future<void> next() async {
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
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
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }

    await next(); // language: follow the phone
    await pick(); // script
    await next();
    await pick(); // text or printed
    await next();
    expect(find.text('Would you like a translation?'), findsOneWidget);
    await tester.tap(find.text('Fateh Muhammad Jalandhari'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await next(); // Start reading
    expect(c.read(settingsProvider).onboarded, isTrue);
    expect(c.read(settingsProvider).translation, 'ur-jalandhari');
    expect(c.read(settingsProvider).textEdition, 'indopak-15-qudratullah');
  });

  testWidgets('wide screens: two pages, or one if the reader prefers', (
    tester,
  ) async {
    final c = await start(tester, onboarded: true, textLayout: 'mushaf');
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pump();
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    final spread = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_Spread',
    );
    expect(spread, findsWidgets);
    final before = c.read(settingsProvider).textEdition;

    c.read(settingsProvider.notifier).setTwoPages(false);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(spread, findsNothing);
    expect(c.read(settingsProvider).twoPages, isFalse);
    expect(c.read(settingsProvider).textEdition, before);

    c.read(settingsProvider.notifier).setTwoPages(true);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(spread, findsWidgets);

    // Easy read too: two pages side by side, each scrolling on its own.
    c.read(settingsProvider.notifier).setTextLayout(TextLayout.reflow);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(spread, findsWidgets);
    expect(find.byType(ReflowPage), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('reading position is saved after a pause, and on leaving', (
    tester,
  ) async {
    final c = await start(tester, onboarded: true, textLayout: 'mushaf');
    (int, int) daily() {
      final d = c.read(libraryProvider).session('daily');
      return (d.surah, d.ayah);
    }

    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final opened = daily();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 300));
    expect(daily(), opened, reason: 'not saved on every turn');
    await tester.pump(const Duration(milliseconds: 1200));
    final turned = daily();
    expect(turned, isNot(opened), reason: 'saved once turns stop');

    // Turn again and leave at once: saved on the way out.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 300));
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 10)); // the save runs next
    expect(daily(), isNot(turned));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
