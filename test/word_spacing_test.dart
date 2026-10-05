// Easy read's word spacing: at the Mushaf spacing and above, words are
// spaced exactly as on Mushaf pages; below it, each pair of words comes as
// close as its ink allows, never touching, and never further apart than on
// the Mushaf pages.
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/data/models.dart';
import 'package:mushaf15/data/quran_db.dart';

void main() {
  late QuranDb db;

  setUpAll(() => db = QuranDb.openFile('assets/db/quran.db'));

  List<Word> wordsOf(String edition, int page, QuranTypeface typeface) => [
    for (final line in db.page(edition, page, typeface).lines)
      if (line.kind == LineKind.text) ...line.words,
  ];

  for (final (edition, typeface) in [
    ('indopak-15-qudratullah', QuranTypeface.indopakNastaleeq),
    ('indopak-15-qudratullah', QuranTypeface.kfgqpcNastaleeq),
    ('madani-1405', QuranTypeface.qpcHafs),
  ]) {
    test('${typeface.name}: spacing rules hold for every pair', () {
      for (final page in [1, 2, 300, 562, 600]) {
        final words = wordsOf(edition, page, typeface);
        for (var i = 0; i + 1 < words.length; i++) {
          final a = words[i], b = words[i + 1];
          if (b.id != a.id + 1) continue;
          final touch = a.touchAfter;
          expect(touch, isNotNull, reason: 'the database has touch data');
          final mushaf = Word.mushafGap + a.gapAfter;
          // The Mushaf spacing is exactly what the Mushaf pages use.
          expect(a.spaceBefore(b, Word.mushafGap), mushaf);
          expect(a.spaceBefore(b, 0.3), closeTo(0.3 + a.gapAfter, 1e-9));
          for (final gap in [0.0, 0.05, 0.1, 0.15]) {
            final space = a.spaceBefore(b, gap);
            // Never wider than the Mushaf pages, never narrower than chosen.
            expect(space, lessThanOrEqualTo(mushaf + 0.011));
            expect(space, greaterThanOrEqualTo(gap));
            // The ink stays clear of the next word's.
            final clear = b.isAyahEnd ? 0.04 : 0.07;
            expect(space - touch!, greaterThanOrEqualTo(clear - 1e-9));
          }
        }
      }
    });
  }
}
