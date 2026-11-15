// A free read can be saved: the reader's Save button offers to carry the
// current session on from here or to start a new one, from the ayah at the
// top of the screen, or where the reader was brought to until it moves.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
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

  for (final textLayout in ['reflow', 'mushaf']) {
    testWidgets('$textLayout: Save offers to keep this place', (tester) async {
      // Tall enough that Al-Ikhlas, ending its page,
      // can't scroll its header to the top.
      tester.view.physicalSize = const Size(460, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'onboarded': true,
        'language': 'en',
        'textLayout': textLayout,
        'reflowTranslation': true,
        'translation': 'en-sahih',
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
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ReaderScreen(
                initialPage: db.surahStartPage(layout, 112),
                at: (112, 1),
              ),
            ),
          );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      if (textLayout == 'reflow') {
        // The case this is about: the end of Al-Masad is above the header.
        final header = find.byWidgetPredicate(
          (w) => w is SurahHeader && w.surah.id == 112,
        );
        expect(tester.getTopLeft(header).dy, greaterThan(150));
      }

      await tester.tapAt(const Offset(205, 500)); // the controls
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.tap(find.byTooltip('Save this place as a session'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('Save as a new session'), findsOneWidget);
      // Opened at Al-Ikhlas and not moved: Al-Ikhlas, whatever else shares
      // the screen.
      final moves = tester
          .widgetList<Text>(find.textContaining('Moves Daily reading to'))
          .single
          .data!;
      expect(moves, endsWith('Al-Ikhlas 112:1'));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
