// A shared ayah image holds the whole ayah: the largest text that fits the
// post or story shape, and for the longest ayahs a taller image rather than
// a cut one. The text version carries the Quran text, the credited
// translation and the reference.
//
// SHARE_CARDS=<dir> saves the cards as PNGs there, to look at.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/core/theme.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/features/reader/share_card.dart';
import 'package:mushaf15/l10n/l10n.dart';
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

  setUpAll(() async {
    ShapePrefetcher.enabled = false;
    await _loadFont('IndoPak', ['assets/fonts/IndoPakNastaleeq.ttf']);
    await _loadFont('UthmanicHafs', ['assets/fonts/UthmanicHafs.ttf']);
    await _loadFont('Newsreader', ['assets/fonts/ui/Newsreader-400.ttf']);
    await _loadFont('SourceSans3', ['assets/fonts/ui/SourceSans3-400.ttf']);
    await _loadFont('NotoNaskhArabic', [
      'assets/fonts/ui/NotoNaskhArabic-400.ttf',
    ]);
    db = QuranDb.openFile('assets/db/quran.db');
  });

  ui.Image card(
    int surah,
    int ayah,
    CardFormat format,
    Palette palette,
    QuranTypeface typeface,
  ) {
    final translation = db.translation('en-sahih');
    return ShareCards.draw(
      card: (size, {fill = false}) => ShareCard(
        words: db.ayahTail(surah, ayah, typeface, count: 1000),
        typeface: typeface,
        quranSize: size,
        surah: db.surah(surah),
        reference: '${db.surah(surah).nameSimple} $surah:$ayah',
        brand: 'Quiet Quran',
        translation: translation,
        translated: db.translationText('en-sahih', surah, ayah),
        fill: fill,
      ),
      format: format,
      theme: buildTheme(palette),
    );
  }

  Future<void> save(WidgetTester tester, ui.Image image, String name) async {
    final dir = Platform.environment['SHARE_CARDS'];
    if (dir == null) return;
    await tester.runAsync(() async {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  testWidgets('a short ayah fits the post and story shapes', (tester) async {
    for (final format in CardFormat.values) {
      final image = card(
        67,
        3,
        format,
        Palette.day,
        QuranTypeface.indopakNastaleeq,
      );
      expect(image.width, 1080);
      expect(image.height, ShareCards.heightOf(format) * 2);
      await save(tester, image, 'card_67_3_${format.name}');
      image.dispose();
    }
    final night = card(
      112,
      1,
      CardFormat.post,
      Palette.night,
      QuranTypeface.qpcHafs,
    );
    expect(night.height, 1080);
    await save(tester, night, 'card_112_1_night');
    night.dispose();
  });

  testWidgets('the longest ayah is never cut: the image grows instead', (
    tester,
  ) async {
    final image = card(
      2,
      282,
      CardFormat.post,
      Palette.day,
      QuranTypeface.indopakNastaleeq,
    );
    expect(image.width, 1080);
    expect(image.height, greaterThan(1080));
    await save(tester, image, 'card_2_282_post');
    image.dispose();
  });

  test('text: Quran text, credited translation, reference and app name', () {
    final text = shareText(
      db: db,
      surah: 112,
      ayah: 1,
      translationId: 'en-sahih',
      reference: 'Al-Ikhlas 112:1',
      brand: 'Quiet Quran',
    );
    final parts = text.split('\n\n');
    expect(parts, hasLength(3));
    expect(parts[0], isNotEmpty);
    expect(parts[1], contains('— Saheeh International'));
    expect(parts[2], 'Al-Ikhlas 112:1 · Quiet Quran');
  });

  testWidgets('the share sheet previews the card, as a post or a story', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'language': 'en'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          quranDbProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          theme: buildTheme(Palette.day),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showShareSheet(context, 67, 3),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // The logo loads first, then the card is drawn.
    for (var i = 0; i < 20 && find.byType(RawImage).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    RawImage preview() => tester.widget<RawImage>(find.byType(RawImage));
    expect(preview().image!.height, 1080);
    expect(find.text('Share image'), findsOneWidget);
    expect(find.text('Share text'), findsOneWidget);

    await tester.pumpAndSettle(); // the sheet finishes sliding up
    await tester.tap(find.text('Story'));
    await tester.pump();
    expect(preview().image!.height, 1920);
    await tester.pumpWidget(const SizedBox());
  });
}
