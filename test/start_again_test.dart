// Starting a session again: Al-Kahf on Fridays or Al-Mulk at night goes back
// to where it began, without deleting and making it again.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/data/library.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late QuranDb db;

  setUpAll(() => db = QuranDb.openFile('assets/db/quran.db'));

  Future<ProviderContainer> device([
    Map<String, Object> prefs = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(p),
        quranDbProvider.overrideWithValue(db),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('a session goes back to where it began', () async {
    final c = await device();
    final lib = c.read(libraryProvider.notifier);
    final kahf = lib.add(name: 'Friday', surah: 18, ayah: 1);
    lib.setPosition(kahf, 18, 110);
    // Saved from a free read part-way through a surah: it began there.
    final tail = lib.add(name: 'Rest of Yasin', surah: 36, ayah: 13);
    lib.setPosition(tail, 37, 4);

    lib.startAgain(kahf);
    lib.startAgain(tail);
    final got = c.read(libraryProvider);
    expect((got.session(kahf).surah, got.session(kahf).ayah), (18, 1));
    expect((got.session(tail).surah, got.session(tail).ayah), (36, 13));
    // And it stays so after a restart of the app.
    final again = await device({
      'sessions': c.read(prefsProvider).getString('sessions')!,
    });
    expect(again.read(libraryProvider).session(tail).ayah, 13);
  });

  test('a session made before the start was kept starts from its surah', () {
    final old = Session.fromJson({
      'id': 's1',
      'name': 'Night',
      'surah': 67,
      'ayah': 20,
      'kind': 'resume',
    });
    expect(old.start, (67, 1));
  });
}
