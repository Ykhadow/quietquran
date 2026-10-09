// The fast word lookups (by an ayah's word-id range) return exactly the words
// the plain query does, for every ayah, typeface and juz.
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late QuranDb db;
  late Database raw;

  setUpAll(() {
    db = QuranDb.openFile('assets/db/quran.db');
    raw = sqlite3.open('assets/db/quran.db', mode: OpenMode.readOnly);
  });
  tearDownAll(() => raw.close());

  test('every ayah: ayahTail matches the words table', () {
    for (final t in QuranTypeface.values) {
      final all = raw.select(
        'SELECT id, surah, ayah, is_end, ${t.column} AS text FROM words ORDER BY id',
      );
      final byAyah = <(int, int), List<Row>>{};
      for (final r in all) {
        byAyah
            .putIfAbsent((r['surah'] as int, r['ayah'] as int), () => [])
            .add(r);
      }
      for (final MapEntry(key: (s, a), value: rows) in byAyah.entries) {
        final whole = db.ayahTail(s, a, t, count: 1000);
        expect(
          [for (final w in whole) (w.id, w.text, w.isAyahEnd)],
          [for (final r in rows) (r['id'], r['text'], r['is_end'] == 1)],
          reason: '${t.name} $s:$a',
        );
        // The short tail: the last 5 words and the marker.
        final tail = db.ayahTail(s, a, t);
        final expected = rows.skip(rows.length > 6 ? rows.length - 6 : 0);
        expect(
          [for (final w in tail) w.id],
          [for (final r in expected) r['id']],
        );
      }
    }
  });

  test('juz names and bismillah match the words table', () {
    for (final t in QuranTypeface.values) {
      for (var juz = 1; juz <= 30; juz++) {
        final start = db.juzStarts(t.script.defaultTextEdition)[juz - 1];
        // Juz 1 is known by "Alif Lam Mim" (2:1, one word); the others by
        // their opening two words.
        final (surah, ayah, count) = juz == 1
            ? (2, 1, 1)
            : (start.surah, start.ayah, 2);
        final expected = raw
            .select(
              'SELECT ${t.column} AS text FROM words WHERE surah = ? AND ayah = ? '
              'AND is_end = 0 ORDER BY id LIMIT ?',
              [surah, ayah, count],
            )
            .map((r) => r['text'] as String)
            .join(' ');
        expect(db.juzName(juz, t), expected, reason: '${t.name} juz $juz');
      }
      final bismillah = raw.select(
        'SELECT id FROM words WHERE surah = 1 AND ayah = 1 AND is_end = 0 ORDER BY id',
      );
      expect(
        [for (final w in db.bismillah(t)) w.id],
        [for (final r in bismillah) r['id']],
      );
    }
  });

  test('surah start pages match a direct query', () {
    for (final e in db.editions) {
      for (var s = 1; s <= 114; s++) {
        final expected = raw.select(
          'SELECT MIN(page) AS page FROM lines WHERE edition = ? AND kind = 1 AND surah = ?',
          [e.id, s],
        ).first['page'];
        expect(db.surahStartPage(e.id, s), expected, reason: '${e.id} $s');
      }
    }
  });
}
