import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/home/surah_search.dart';

void main() {
  final surahs = QuranDb.openFile('assets/db/quran.db').surahs;
  List<int> ids(String q) => searchSurahs(surahs, q).map((s) => s.id).toList();

  test('empty query lists every surah', () => expect(ids('  ').length, 114));
  test('number', () => expect(ids('67'), [67]));
  test('transliteration, ignoring hyphens and case', () {
    expect(ids('mulk'), [67]);
    expect(ids('Al-Baqara'), contains(2));
    expect(ids('imran'), [3]);
    expect(ids('ya-sin'), [36]);
    expect(ids('yasin'), [36]);
  });
  test('English meaning', () => expect(ids('opener'), [1]));
  test('Arabic, ignoring harakat', () {
    expect(ids('الملك'), [67]);
    expect(ids('الْبَقَرَة'), [2]);
  });
}
