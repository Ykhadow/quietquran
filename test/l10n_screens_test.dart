// The main screens in English, Urdu and Arabic at phone width: builds without
// overflow or missing strings. With SHOTS=<dir> set, also saves a picture of
// each for review.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/home/home_screen.dart';
import 'package:mushaf15/features/onboarding/onboarding_screen.dart';
import 'package:mushaf15/features/reader/page_snapshot.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/features/reader/reader_screen.dart';
import 'package:mushaf15/features/settings/palette_editor.dart';
import 'package:mushaf15/features/settings/settings_screen.dart';
import 'package:mushaf15/features/settings/sources_screen.dart';
import 'package:mushaf15/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(p).readAsBytesSync())),
    );
  }
  await loader.load();
}

void main() {
  late QuranDb db;
  final shots = Platform.environment['SHOTS'];

  setUpAll(() async {
    ShapePrefetcher.enabled = false;
    PageSnapshots.enabled = false;
    await _loadFont('IndoPak', ['assets/fonts/IndoPakNastaleeq.ttf']);
    await _loadFont('Newsreader', [
      'assets/fonts/ui/Newsreader-400.ttf',
      'assets/fonts/ui/Newsreader-400-italic.ttf',
    ]);
    await _loadFont('SourceSans3', [
      'assets/fonts/ui/SourceSans3-400.ttf',
      'assets/fonts/ui/SourceSans3-600.ttf',
    ]);
    await _loadFont('Amiri', ['assets/fonts/ui/Amiri-400.ttf']);
    await _loadFont('NotoNaskhArabic', [
      'assets/fonts/ui/NotoNaskhArabic-400.ttf',
      'assets/fonts/ui/NotoNaskhArabic-600.ttf',
    ]);
    db = QuranDb.openFile('assets/db/quran.db');
  });

  final screens = <String, (bool, Widget Function())>{
    'onboarding': (false, () => const OnboardingScreen()),
    'onboarding-script': (false, () => const OnboardingScreen()),
    'onboarding-mode': (false, () => const OnboardingScreen()),
    'onboarding-size': (false, () => const OnboardingScreen()),
    'onboarding-translation': (false, () => const OnboardingScreen()),
    'aa-sheet': (true, () => const ReaderScreen(initialPage: 562)),
    'home': (true, () => const HomeScreen()),
    'settings': (true, () => const SettingsScreen()),
    'reader': (true, () => const ReaderScreen(initialPage: 562)),
    'sources': (true, () => const SourcesScreen()),
    'palette': (true, () => const PaletteEditor()),
  };

  for (final language in ['en', 'ur', 'ar']) {
    for (final MapEntry(key: name, value: (onboarded, screen))
        in screens.entries) {
      testWidgets('$name in $language', (tester) async {
        tester.view.physicalSize = const Size(411, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({
          'language': language,
          'onboarded': onboarded,
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
        await tester.pump();
        if (name.startsWith('onboarding-')) {
          Future<void> next() async {
            await tester.tap(find.byType(FilledButton));
            await tester.pump();
            await tester.pump(const Duration(seconds: 1));
          }

          await next(); // past the language step
          if (name == 'onboarding-size' || name == 'onboarding-translation') {
            for (var i = 0; i < 3; i++) {
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
              await tester.pump();
              await next();
            }
            // Past the text size step, to the translation step.
            if (name == 'onboarding-translation') await next();
          }
          if (name == 'onboarding-mode') {
            // Pick the first script, then go on to the mode step.
            await tester.tap(
              find
                  .byWidgetPredicate(
                    (w) => const {
                      '_ChoiceCard',
                      'PageChoice',
                    }.contains(w.runtimeType.toString()),
                  )
                  .first,
            );
            await tester.pump();
            await next();
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 300)),
            );
            await tester.pump();
          }
        } else if (name != 'home' && name != 'onboarding') {
          final nav = tester.state<NavigatorState>(find.byType(Navigator));
          nav.push(MaterialPageRoute(builder: (_) => screen()));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
        }
        if (name == 'aa-sheet') {
          await tester.tapAt(const Offset(200, 450));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.byIcon(LucideIcons.settings2));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
        }
        if (name == 'reader') {
          // Bring up the overlay.
          await tester.tapAt(const Offset(200, 450));
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(tester.takeException(), isNull);

        if (shots != null) {
          final layer =
              tester.binding.renderViews.first.debugLayer! as OffsetLayer;
          final image = await tester.runAsync(
            () => layer.toImage(Offset.zero & const Size(411, 900)),
          );
          final bytes = await tester.runAsync(
            () => image!.toByteData(format: ui.ImageByteFormat.png),
          );
          File(
            '$shots/${name}_$language.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
        }
        // Let the reader's overlay timer run out.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 5));
      });
    }
  }
}
