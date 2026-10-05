// Screenshots of the app for the website (website/img/), drawn from the
// real screens with the real fonts. Runs only when asked:
//
//   SITE_SHOTS=website/img flutter test test/site_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/core/theme.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/reader/quran_word.dart';
import 'package:mushaf15/features/reader/mushaf_text_page.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/features/reader/reflow_page.dart';
import 'package:mushaf15/features/reader/share_card.dart';
import 'package:mushaf15/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _font(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(p).readAsBytesSync())),
    );
  }
  await loader.load();
}

void main() {
  final out = Platform.environment['SITE_SHOTS'];

  testWidgets('website screenshots', (tester) async {
    if (out == null) return;
    ShapePrefetcher.enabled = false;
    await tester.runAsync(() async {
      await _font('IndoPak', ['assets/fonts/IndoPakNastaleeq.ttf']);
      await _font('UthmanicHafs', ['assets/fonts/UthmanicHafs.ttf']);
      await _font('SurahName', ['assets/fonts/SurahNameV2.ttf']);
      await _font('Newsreader', [
        'assets/fonts/ui/Newsreader-400.ttf',
        'assets/fonts/ui/Newsreader-400-italic.ttf',
      ]);
      await _font('SourceSans3', [
        'assets/fonts/ui/SourceSans3-400.ttf',
        'assets/fonts/ui/SourceSans3-600.ttf',
      ]);
      await _font('packages/lucide_icons_flutter/Lucide', [
        '${Platform.environment['LOCALAPPDATA']}/Pub/Cache/hosted/pub.dev/'
            'lucide_icons_flutter-3.1.20/assets/lucide.ttf',
      ]);
      await _font('MaterialIcons', [
        'C:/src/flutter/bin/cache/artifacts/material_fonts/'
            'materialicons-regular.otf',
      ]);
      await _font('NotoNaskhArabic', [
        'assets/fonts/ui/NotoNaskhArabic-400.ttf',
        'assets/fonts/ui/NotoNaskhArabic-600.ttf',
      ]);
    });
    final db = QuranDb.openFile('assets/db/quran.db');
    const indopak = QuranTypeface.indopakNastaleeq;
    const madani = QuranTypeface.qpcHafs;
    final english = db.translation('en-sahih');

    // In physical pixels (2 per logical pixel).
    const statusBar = FakeViewPadding(top: 64, bottom: 28);

    Future<void> shot(
      String name,
      Size size,
      Palette palette,
      Widget Function() build,
    ) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      // Pages shown on their own (no device frame) need no status bar; only
      // the home screen, in the hero phone, keeps one.
      tester.view.padding = FakeViewPadding.zero;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(palette),
          themeAnimationDuration: Duration.zero,
          home: Scaffold(
            backgroundColor: palette.bg,
            body: RepaintBoundary(
              key: key,
              // Painted, so no part of the screenshot is transparent.
              child: ColoredBox(
                color: palette.bg,
                // Phones get a little extra room around the page, so it
                // breathes inside the device frame on the website.
                child: SafeArea(
                  child: Padding(
                    padding: size.width < 600
                        ? const EdgeInsets.fromLTRB(14, 6, 14, 6)
                        : EdgeInsets.zero,
                    child: build(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
        image.dispose();
      });
    }

    // Each matches its device frame's screen on the website: the phone, and
    // the laptop (devices.css's Surface Book).
    const phone = Size(376, 816);
    // Pages shown on their own on the site, in the printed page's shape.
    const pageCard = Size(440, 630);
    final mulk = db.surahStartPage('indopak-15-qudratullah', 67);
    final mulkMadani = db.surahStartPage('madani-1405', 67);

    for (final (name, palette) in [
      ('easy-read', Palette.day),
      ('easy-read-night', Palette.night),
    ]) {
      await shot(
        name,
        pageCard,
        palette,
        () => ReflowPage(
          page: db.page('indopak-15-qudratullah', mulk, indopak),
          db: db,
          fontSize: 30,
          juzLabel: 'JUZ 29',
        ),
      );
    }

    // The reader on a phone (Easy read), for the hero.
    for (final (name, palette) in [
      ('reader', Palette.day),
      ('reader-night', Palette.night),
    ]) {
      await shot(
        name,
        phone,
        palette,
        () => ReflowPage(
          page: db.page('indopak-15-qudratullah', mulk, indopak),
          db: db,
          fontSize: 28,
          juzLabel: 'JUZ 29',
        ),
      );
    }

    // The tablet beside the IndoPak / Madani switch: page 511, the opening
    // of Al-Fath, which is the same page in both 15-line Mushafs (the same
    // 15 lines, starting at 48:1 and ending at 48:9). Day and Night.
    const tablet = Size(600, 860);
    for (final (edition, typeface) in [
      ('indopak-15-qudratullah', indopak),
      ('madani-1405', madani),
    ]) {
      for (final (suffix, palette) in [
        ('', Palette.day),
        ('-night', Palette.night),
      ]) {
        await shot('layout-$edition$suffix', tablet, palette, () {
          final page = db.page(edition, 511, typeface);
          return MushafTextPage(
            page: page,
            db: db,
            juzLabel: 'JUZ ${page.juz}',
          );
        });
      }
    }
    // Easy read as a recitation plays: the ayah being heard is lit.
    // Two ayahs in turn, as the site's player moves from one to the next.
    for (final (name, palette, ayah) in [
      ('listen-day', Palette.day, 2),
      ('listen-night', Palette.night, 2),
      ('listen-day-3', Palette.day, 3),
      ('listen-night-3', Palette.night, 3),
    ]) {
      await shot(
        name,
        pageCard,
        palette,
        () => ReflowPage(
          page: db.page('indopak-15-qudratullah', mulk, indopak),
          db: db,
          fontSize: 30,
          juzLabel: 'JUZ 29',
          highlight: (67, ayah),
        ),
      );
    }
    await shot(
      'madani-night',
      pageCard,
      Palette.night,
      () => MushafTextPage(
        page: db.page('madani-1405', mulkMadani, madani),
        db: db,
        juzLabel: 'JUZ 29',
      ),
    );
    await shot(
      'sepia',
      pageCard,
      Palette.sepia,
      () => MushafTextPage(
        page: db.page('indopak-15-qudratullah', mulk + 1, indopak),
        db: db,
        juzLabel: 'JUZ 29',
      ),
    );

    // The app's home screen, as a first-time reader sees it after setup, in
    // Day and in Night.
    for (final (name, appearance) in [
      ('home', 'day'),
      ('home-night', 'night'),
    ]) {
      tester.view.physicalSize = phone * 2;
      tester.view.devicePixelRatio = 2;
      tester.view.padding = statusBar;
      SharedPreferences.setMockInitialValues({
        'onboarded': true,
        'language': 'en',
        'appearance': appearance,
      });
      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      final homeKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: homeKey,
          child: ProviderScope(
            overrides: [
              prefsProvider.overrideWithValue(prefs!),
              quranDbProvider.overrideWithValue(db),
            ],
            child: const MushafApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() async {
        final boundary =
            homeKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    }

    // Sessions: the end of the daily reading's ayah (2:255), as the home
    // card shows it, in Day and Night ink on a clear background. The site
    // draws the card around it.
    final words = db.ayahTail(2, 255, indopak, count: 5);
    for (final (name, palette) in [
      ('day', Palette.day),
      ('night', Palette.night),
    ]) {
      tester.view.physicalSize = const Size(520, 80) * 2;
      tester.view.devicePixelRatio = 2;
      tester.view.padding = FakeViewPadding.zero;
      final key = GlobalKey();
      final style = TextStyle(
        fontFamily: indopak.fontFamily,
        fontSize: 32,
        height: 1.9,
        color: palette.ink,
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.centerRight,
            child: RepaintBoundary(
              key: key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.rtl,
                children: [
                  for (final (i, w) in words.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    QuranWord(
                      word: w,
                      typeface: indopak,
                      style: style,
                      markerStyle: style.copyWith(color: palette.acc),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$out/session-ayah-$name.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
        image.dispose();
      });
    }

    // Two Mushaf pages side by side, no translation, in Day and in Night.
    for (final (name, palette) in [
      ('laptop', Palette.day),
      ('laptop-night', Palette.night),
    ]) {
      await shot(
        name,
        const Size(1200, 800),
        palette,
        () => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 10),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              for (final (i, n) in [mulk, mulk + 1].indexed) ...[
                if (i == 1)
                  SizedBox(
                    width: 28,
                    child: Center(
                      child: FractionallySizedBox(
                        heightFactor: 0.84,
                        child: Container(
                          width: 1,
                          color: palette.ink.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: MushafTextPage(
                    page: db.page('indopak-15-qudratullah', n, indopak),
                    db: db,
                    juzLabel: 'JUZ 29',
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // A shared ayah, as the share sheet draws it, in Day and in Night.
    for (final (name, palette, mark) in [
      ('share-card', Palette.day, 'mark_day'),
      ('share-card-night', Palette.night, 'mark_night'),
    ]) {
      final logo = await tester.runAsync(
        () =>
            vg.loadPicture(SvgFileLoader(File('assets/brand/$mark.svg')), null),
      );
      final card = ShareCards.draw(
        card: (size, {fill = false}) => ShareCard(
          words: db.ayahTail(67, 3, indopak, count: 1000),
          typeface: indopak,
          quranSize: size,
          surah: db.surah(67),
          reference: 'Al-Mulk 67:3',
          brand: appName,
          translation: english,
          translated: db.translationText('en-sahih', 67, 3),
          logo: logo!.picture,
          fill: fill,
        ),
        format: CardFormat.post,
        theme: buildTheme(palette),
      );
      await tester.runAsync(() async {
        final png = await card.toByteData(format: ui.ImageByteFormat.png);
        File('$out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
      card.dispose();
    }
    await tester.pumpWidget(const SizedBox());
  });
}
