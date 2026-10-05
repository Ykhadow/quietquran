// Saving the reader's places to a file and bringing them back, on this
// device or another: sessions (with reminders), bookmarks (with notes) and
// which session is current, all as they were. Anything else is refused.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/data/library.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late QuranDb db;

  setUpAll(() => db = QuranDb.openFile('assets/db/quran.db'));

  Future<ProviderContainer> device() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        quranDbProvider.overrideWithValue(db),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('what is saved comes back as it was', () async {
    final a = await device();
    final lib = a.read(libraryProvider.notifier);
    lib.setPosition(Session.dailyId, 2, 255);
    final kahf = lib.add(
      name: 'Friday',
      surah: 18,
      ayah: 1,
      reminder: const Reminder(hour: 7, minute: 30, weekdays: {5}),
    );
    lib.setPosition(kahf, 18, 46);
    lib.toggleBookmark(36, 58);
    lib.setBookmarkNote(36, 58, 'Salam, a word from a merciful Lord');
    final file = lib.export();

    final b = await device();
    final n = b.read(libraryProvider.notifier).import(file);
    expect(n, (sessions: 2, bookmarks: 1));
    final got = b.read(libraryProvider);
    final had = a.read(libraryProvider);
    expect(
      jsonEncode([for (final s in got.sessions) s.toJson()]),
      jsonEncode([for (final s in had.sessions) s.toJson()]),
    );
    expect(got.currentId, kahf);
    expect(got.session(kahf).reminder?.weekdays, {5});
    expect(got.bookmarks.single.note, 'Salam, a word from a merciful Lord');
    // And it is saved on that device too.
    expect(b.read(prefsProvider).getString('bookmarks'), contains('Salam'));
  });

  test('anything else is refused, and nothing changes', () async {
    final c = await device();
    final lib = c.read(libraryProvider.notifier);
    lib.toggleBookmark(1, 1);
    for (final text in [
      'not json',
      '{"kind": "something else", "sessions": []}',
      '[1, 2, 3]',
      '{"kind": "library", "sessions": [{"id": 4}]}',
    ]) {
      expect(() => lib.import(text), throwsFormatException, reason: text);
    }
    expect(c.read(libraryProvider).bookmarks.single.surah, 1);
  });

  test('places outside the Quran are left out; Daily reading stays', () async {
    final c = await device();
    final n = c
        .read(libraryProvider.notifier)
        .import(
          jsonEncode({
            'kind': 'library',
            'currentSession': 'gone',
            'sessions': [
              {'id': 's1', 'name': 'Odd', 'surah': 200, 'ayah': 1},
              {'id': 's2', 'name': 'Yasin', 'surah': 36, 'ayah': 83},
              {'id': 's3', 'name': 'Past the end', 'surah': 1, 'ayah': 8},
            ],
            'bookmarks': [
              {'surah': 112, 'ayah': 4, 'createdAt': 1},
              {'surah': 112, 'ayah': 5, 'createdAt': 2},
            ],
          }),
        );
    final got = c.read(libraryProvider);
    expect([for (final s in got.sessions) s.id], [Session.dailyId, 's2']);
    expect(got.currentId, Session.dailyId);
    expect(n, (sessions: 2, bookmarks: 1));
  });
}
