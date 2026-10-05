import '../../data/models.dart';

/// Surahs matching [query] by number, transliterated name, English meaning or
/// Arabic name. Matching ignores case, accents, hyphens and apostrophes
/// ("al-baqara" and "baqarah" both find Al-Baqarah), and Arabic harakat and
/// letter variants ("الملك" finds Al-Mulk).
List<Surah> searchSurahs(List<Surah> surahs, String query) {
  final q = query.trim();
  if (q.isEmpty) return surahs;
  final number = int.tryParse(q);
  if (number != null) return surahs.where((s) => s.id == number).toList();
  final latin = _latin(q);
  final arabic = _arabic(q);
  return surahs.where((s) {
    final (simple, translated, arabicName) = _keys.putIfAbsent(
      s.id,
      () => (
        _latin(s.nameSimple),
        _latin(s.nameTranslated),
        _arabic(s.nameArabic),
      ),
    );
    if (latin.isNotEmpty &&
        (simple.contains(latin) || translated.contains(latin))) {
      return true;
    }
    return arabic.isNotEmpty && arabicName.contains(arabic);
  }).toList();
}

const _accents = {
  'ā': 'a',
  'á': 'a',
  'â': 'a',
  'ī': 'i',
  'í': 'i',
  'ū': 'u',
  'ú': 'u',
  'ḥ': 'h',
  'ṣ': 's',
  'ḍ': 'd',
  'ṭ': 't',
  'ẓ': 'z',
  'ĥ': 'h',
  'ʿ': '',
  'ʾ': '',
};

/// Each surah's names, folded for matching once (not on every keystroke).
final _keys = <int, (String, String, String)>{};

/// Lower-case Latin letters and digits only.
String _latin(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final c = _accents[ch] ?? ch;
    final u = c.codeUnitAt(0);
    if ((u >= 0x61 && u <= 0x7A) || (u >= 0x30 && u <= 0x39)) b.write(c);
  }
  return b.toString();
}

/// Arabic letters only: harakat and Quranic marks removed, and alef, yeh and
/// teh marbuta variants folded together.
String _arabic(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if ((r >= 0x064B && r <= 0x065F) ||
        r == 0x0670 ||
        (r >= 0x06D6 && r <= 0x06ED)) {
      continue;
    }
    final c = switch (r) {
      0x0623 || 0x0625 || 0x0622 || 0x0671 => 0x0627, // أ إ آ ٱ -> ا
      0x0649 || 0x06CC => 0x064A, // ى ی -> ي
      0x0629 ||
      0x06C3 ||
      0x06C1 ||
      0x06BE ||
      0x06D5 => 0x0647, // ة ۃ ہ ھ ە -> ه
      0x06A9 => 0x0643, // Urdu ک -> ك
      _ => r,
    };
    if (c >= 0x0621 && c <= 0x064A) b.writeCharCode(c);
  }
  return b.toString();
}
