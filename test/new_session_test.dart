// Making a session: its surah is picked from a list that can be searched,
// as on home, rather than scrolled to through all 114.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/core/theme.dart';
import 'package:mushaf15/data/library.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/home/new_session_sheet.dart';
import 'package:mushaf15/features/home/surah_list.dart';
import 'package:mushaf15/features/reader/page_snapshot.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/l10n/l10n.dart';
import 'package:mushaf15/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late QuranDb db;

  setUpAll(() {
    ShapePrefetcher.enabled = false;
    PageSnapshots.enabled = false;
    db = QuranDb.openFile('assets/db/quran.db');
  });

  testWidgets('a surah is found by searching, and the session starts there', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'language': 'en',
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

    String? created;
    showNewSessionSheet(
      tester.element(find.byType(Scaffold).first),
    ).then((id) => created = id);
    await tester.pumpAndSettle();
    expect(find.text('67. Al-Mulk'), findsOneWidget); // the suggestion

    await tester.tap(find.text('67. Al-Mulk'));
    await tester.pumpAndSettle();
    // The picker's (home has one of its own, below the sheets).
    final search = find
        .descendant(
          of: find.byType(SurahSearchField),
          matching: find.byType(TextField),
        )
        .last;
    await tester.enterText(search, 'kahf');
    await tester.pumpAndSettle();
    // Home's list shows Al-Kahf too, below; the picker's is the last.
    final kahf = find.widgetWithText(SurahRow, 'Al-Kahf').last;
    await tester.tap(kahf);
    await tester.pumpAndSettle();

    // Chosen, and the name follows it.
    expect(find.text('18. Al-Kahf'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Al-Kahf'), findsOneWidget);
    await tester.tap(find.text('Create session'));
    await tester.pumpAndSettle();
    final s = c.read(libraryProvider).session(created!);
    expect((s.name, s.surah, s.ayah), ('Al-Kahf', 18, 1));
  });

  testWidgets('a search with no match says so', (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'en'});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        quranDbProvider.overrideWithValue(db),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: buildTheme(Palette.day),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSurahPicker(context),
              child: const Text('pick'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.byType(SurahRow), findsNothing);
    expect(find.text('No surah matches "zzz".'), findsOneWidget);
  });
}
