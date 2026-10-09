import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../core/settings.dart';
import 'models.dart';

/// Read-only access to the bundled Quran database (built by
/// tool/build_quran_db.py). Queries are small and synchronous.
class QuranDb {
  QuranDb._(this._db) {
    surahs = _loadSurahs();
    editions = _loadEditions();
  }

  /// Bump when assets/db/quran.db changes so installs pick up the new copy.
  static const _schemaVersion = 9;

  final Database _db;
  late final List<Surah> surahs;
  late final List<TextEdition> editions;
  final _pageCache = <(String, int, QuranTypeface), MushafPage>{};
  final _juzCache = <String, List<JuzStart>>{};
  final _bismillahCache = <QuranTypeface, List<Word>>{};

  static Future<QuranDb> open() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'quran_v$_schemaVersion.db'));
    if (!file.existsSync()) {
      final data = await rootBundle.load('assets/db/quran.db');
      await file.parent.create(recursive: true);
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await tmp.rename(file.path);
      // Copies left by earlier versions of the app (16 MB each).
      for (final old in dir.listSync()) {
        final name = p.basename(old.path);
        if (old is File &&
            name.startsWith('quran_v') &&
            name != p.basename(file.path)) {
          try {
            old.deleteSync();
          } on FileSystemException {
            // In use or already gone; tried again after the next update.
          }
        }
      }
    }
    return QuranDb.openFile(file.path);
  }

  factory QuranDb.openFile(String path) =>
      QuranDb._(sqlite3.open(path, mode: OpenMode.readOnly));

  List<Surah> _loadSurahs() => [
    for (final r in _db.select('SELECT * FROM surahs ORDER BY id'))
      Surah(
        id: r['id'] as int,
        nameArabic: r['name_arabic'] as String,
        nameSimple: r['name_simple'] as String,
        nameTranslated: r['name_translated'] as String,
        revelationPlace: r['revelation_place'] as String,
        versesCount: r['verses_count'] as int,
      ),
  ];

  List<TextEdition> _loadEditions() => [
    for (final r in _db.select('SELECT * FROM editions ORDER BY sort'))
      TextEdition(
        id: r['id'] as String,
        name: r['name'] as String,
        script: QuranScript.values.byName(r['script'] as String),
        linesPerPage: r['lines_per_page'] as int,
        pages: r['pages'] as int,
        sharedBismillah: _db.select(
          'SELECT 1 FROM lines WHERE edition = ? AND bismillah_inline = 1 LIMIT 1',
          [r['id']],
        ).isNotEmpty,
      ),
  ];

  Surah surah(int id) => surahs[id - 1];

  TextEdition edition(String id) =>
      editions.firstWhere((e) => e.id == id, orElse: () => editions.first);

  List<TextEdition> editionsFor(QuranScript script) =>
      editions.where((e) => e.script == script).toList();

  /// Translations of the meanings, in display order.
  late final List<Translation> translations = [
    for (final r in _db.select(
      'SELECT id, language, translator FROM translations ORDER BY sort',
    ))
      Translation(
        id: r['id'] as String,
        language: r['language'] as String,
        translator: r['translator'] as String,
      ),
  ];

  Translation? translation(String? id) =>
      translations.where((t) => t.id == id).firstOrNull;

  /// The translation of one ayah, exactly as published.
  String? translationText(String id, int surah, int ayah) {
    final rows = _translationQuery.select([id, surah, ayah]);
    return rows.isEmpty ? null : rows.first['text'] as String;
  }

  late final _translationQuery = _db.prepare(
    'SELECT text FROM translation_text '
    'WHERE translation = ? AND surah = ? AND ayah = ?',
  );

  /// Where each part of the database came from, as recorded by the build
  /// script: part (e.g. "words.indopak", "lines:madani-1405") -> (source, url).
  late final Map<String, (String, String)> sources = {
    for (final r in _db.select('SELECT part, source, url FROM sources'))
      r['part'] as String: (r['source'] as String, r['url'] as String),
  };

  /// Page (in [edition]) on which the given word appears.
  int pageOfWord(String edition, int wordId) =>
      _db.select(
            'SELECT page FROM lines WHERE edition = ? AND kind = 0 AND first_word <= ? '
            'ORDER BY first_word DESC LIMIT 1',
            [edition, wordId],
          ).first['page']
          as int;

  int pageOfAyah(String edition, int surah, int ayah) {
    final rows = _db.select(
      'SELECT first_word FROM ayahs WHERE surah = ? AND ayah = ?',
      [surah, ayah],
    );
    if (rows.isEmpty) return 1;
    return pageOfWord(edition, rows.first['first_word'] as int);
  }

  /// Natural width (words and gaps, at a 100px font) that 99% of the
  /// edition's justified lines fit in, for [typeface]'s text. Sizing text so
  /// this fills the page gives one font size for the whole edition.
  double lineFit(String edition, QuranTypeface typeface) =>
      _lineFit.putIfAbsent((edition, typeface), () {
        final rows = _db.select(
          'SELECT width FROM line_fit WHERE edition = ? AND column_name = ?',
          [edition, typeface.column],
        );
        return rows.isEmpty ? 2000.0 : (rows.first['width'] as num).toDouble();
      });
  final _lineFit = <(String, QuranTypeface), double>{};

  /// Height of a line holding both a surah name and its bismillah (editions
  /// that print them together), in ordinary lines: the two need more room
  /// than one line. Other lines on that page give up the difference.
  static const openingLineWeight = 1.6;

  /// The most line heights any page of [edition] needs, counting shared
  /// name-and-bismillah lines as [openingLineWeight]. Sizing text for this
  /// page keeps one font size across the edition.
  double maxPageWeight(String edition) => _maxPageWeight.putIfAbsent(
    edition,
    () =>
        (_db.select(
                  'SELECT MAX(w) AS w FROM ('
                  '  SELECT COUNT(*) + ? * SUM(kind = 1 AND bismillah_inline = 1) AS w'
                  '  FROM lines WHERE edition = ? GROUP BY page)',
                  [openingLineWeight - 1, edition],
                ).first['w']
                as num?)
            ?.toDouble() ??
        this.edition(edition).linesPerPage.toDouble(),
  );
  final _maxPageWeight = <String, double>{};

  /// Page holding the surah's header (not just its first ayah).
  /// Page holding the surah's header; all 114 read in one query per edition
  /// and kept (the surah list asks for every row).
  int surahStartPage(String edition, int surah) =>
      _surahStarts.putIfAbsent(edition, () {
        final pages = List<int>.filled(115, 1);
        for (final r in _db.select(
          'SELECT surah, MIN(page) AS page FROM lines '
          'WHERE edition = ? AND kind = 1 GROUP BY surah',
          [edition],
        )) {
          pages[r['surah'] as int] = r['page'] as int;
        }
        return pages;
      })[surah];
  final _surahStarts = <String, List<int>>{};

  /// First and last word id of an ayah (from its indexed row in `ayahs`), so
  /// its words are read by id instead of scanning the whole words table.
  (int, int)? _wordRange(int surah, int ayah) {
    final rows = _wordRangeQuery.select([surah, ayah]);
    if (rows.isEmpty) return null;
    return (rows.first['first_word'] as int, rows.first['last_word'] as int);
  }

  late final _wordRangeQuery = _db.prepare(
    'SELECT first_word, last_word FROM ayahs WHERE surah = ? AND ayah = ?',
  );

  List<JuzStart> juzStarts(String edition) =>
      _juzCache.putIfAbsent(edition, () {
        final rows = _db.select('''
      SELECT juz, surah, ayah, first_word FROM ayahs
      WHERE surah * 1000 + ayah IN (SELECT MIN(surah * 1000 + ayah) FROM ayahs GROUP BY juz)
      ORDER BY juz''');
        return [
          for (final r in rows)
            JuzStart(
              r['juz'] as int,
              pageOfWord(edition, r['first_word'] as int),
              r['surah'] as int,
              r['ayah'] as int,
            ),
        ];
      });

  /// The printed line (in [edition]) on which the given ayah ends, with its
  /// words in [typeface]: the natural "you stopped here" line.
  PageLine? lineEndingAyah(
    String edition,
    int surah,
    int ayah,
    QuranTypeface typeface,
  ) {
    final rows = _db.select(
      'SELECT last_word FROM ayahs WHERE surah = ? AND ayah = ?',
      [surah, ayah],
    );
    if (rows.isEmpty) return null;
    final last = rows.first['last_word'] as int;
    final page = this.page(edition, pageOfWord(edition, last), typeface);
    return page.lines
        .where((l) => l.words.any((w) => w.id == last))
        .firstOrNull;
  }

  /// The last [count] words of an ayah and its end marker, in [typeface]:
  /// "where you stopped", independent of line breaks.
  List<Word> ayahTail(
    int surah,
    int ayah,
    QuranTypeface typeface, {
    int count = 5,
  }) {
    final range = _wordRange(surah, ayah);
    if (range == null) return const [];
    final (first, last) = range;
    // The last [count] words and the end marker.
    final rows = _db.select(
      'SELECT id, surah, ayah, is_end, ${typeface.column} AS text FROM words '
      'WHERE id BETWEEN ? AND ? ORDER BY id',
      [(last - count).clamp(first, last), last],
    );
    return [
      for (final r in rows)
        Word(
          r['id'] as int,
          r['surah'] as int,
          r['ayah'] as int,
          r['is_end'] == 1,
          r['text'] as String,
          gapAfter: _gaps(typeface)[r['id'] as int] ?? 0,
          touchAfter: _touch(typeface, r['id'] as int),
          inkLeft: _ink(typeface, r['id'] as int, 0),
          inkRight: _ink(typeface, r['id'] as int, 1),
        ),
    ];
  }

  /// Extra space after each word whose ink would otherwise touch the next
  /// word's, for one typeface (see Word.gapAfter).
  Map<int, double> _gaps(QuranTypeface typeface) =>
      _gapCache.putIfAbsent(typeface, () {
        final exists = _db
            .select(
              "SELECT 1 FROM sqlite_master WHERE type = 'table' "
              "AND name = 'word_gap'",
            )
            .isNotEmpty;
        if (!exists) return const {};
        return {
          for (final r in _db.select(
            'SELECT id, extra FROM word_gap WHERE column_name = ?',
            [typeface.column],
          ))
            r['id'] as int: (r['extra'] as num).toDouble(),
        };
      });
  final _gapCache = <QuranTypeface, Map<int, double>>{};

  /// Where word [id]'s ink and the next's would touch (see Word.touchAfter).
  double? _touch(QuranTypeface typeface, int id) {
    final data = _touchData.putIfAbsent(typeface, () {
      final exists = _db
          .select(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' "
            "AND name = 'word_need'",
          )
          .isNotEmpty;
      if (!exists) return null;
      final rows = _db.select(
        'SELECT data FROM word_need WHERE column_name = ?',
        [typeface.column],
      );
      return rows.isEmpty ? null : rows.first['data'] as Uint8List;
    });
    if (data == null || id < 1 || id > data.length) return null;
    final b = data[id - 1];
    return b == 0 ? -1.0 : (b - 128) / 100;
  }

  final _touchData = <QuranTypeface, Uint8List?>{};

  /// How far word [id]'s ink reaches past its box, on the left ([side] 0)
  /// or the right (1), in em (see Word.inkLeft).
  double _ink(QuranTypeface typeface, int id, int side) {
    final data = _inkData.putIfAbsent(typeface, () {
      final exists = _db
          .select(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' "
            "AND name = 'word_ink'",
          )
          .isNotEmpty;
      if (!exists) return null;
      final rows = _db.select(
        'SELECT data FROM word_ink WHERE column_name = ?',
        [typeface.column],
      );
      return rows.isEmpty ? null : rows.first['data'] as Uint8List;
    });
    final i = (id - 1) * 2 + side;
    if (data == null || id < 1 || i >= data.length) return 0;
    return data[i] / 100;
  }

  final _inkData = <QuranTypeface, Uint8List?>{};

  /// A juz's traditional name: the opening words of its first ayah.
  String juzName(int juz, QuranTypeface typeface, {int words = 2}) =>
      _juzNames.putIfAbsent((juz, typeface, words), () {
        // Juz boundaries are ayahs, so any edition's list gives the same ayah.
        final start = juzStarts(typeface.script.defaultTextEdition)[juz - 1];
        // The first juz is known by Al-Baqarah's opening, "Alif Lam Mim"
        // (2:1, a single word), not by Al-Fatihah's bismillah.
        final range = juz == 1
            ? _wordRange(2, 1)
            : _wordRange(start.surah, start.ayah);
        if (range == null) return '';
        return _db
            .select(
              'SELECT ${typeface.column} AS text FROM words '
              'WHERE id BETWEEN ? AND ? AND is_end = 0 ORDER BY id LIMIT ?',
              [range.$1, range.$2, juz == 1 ? 1 : words],
            )
            .map((r) => r['text'] as String)
            .join(' ');
      });
  final _juzNames = <(int, QuranTypeface, int), String>{};

  /// The words of "Bismillah…" (ayah 1:1) in the given typeface, for header
  /// lines.
  List<Word> bismillah(QuranTypeface typeface) =>
      _bismillahCache.putIfAbsent(typeface, () {
        final (first, last) = _wordRange(1, 1)!;
        final rows = _db.select(
          'SELECT id, ${typeface.column} AS text FROM words '
          'WHERE id BETWEEN ? AND ? AND is_end = 0 ORDER BY id',
          [first, last],
        );
        return [
          for (final r in rows)
            Word(
              r['id'] as int,
              1,
              1,
              false,
              r['text'] as String,
              gapAfter: _gaps(typeface)[r['id'] as int] ?? 0,
              touchAfter: _touch(typeface, r['id'] as int),
              inkLeft: _ink(typeface, r['id'] as int, 0),
              inkRight: _ink(typeface, r['id'] as int, 1),
            ),
        ];
      });

  /// Path of a page in an image set that has no URL pattern.
  String? imagePath(String imageEdition, int page) {
    final rows = _db.select(
      'SELECT path FROM image_paths WHERE image_edition = ? AND page = ?',
      [imageEdition, page],
    );
    return rows.isEmpty ? null : rows.first['path'] as String;
  }

  /// A page of [editionId], its words in [typeface] (by default the first
  /// typeface of the edition's script).
  MushafPage page(String editionId, int number, [QuranTypeface? typeface]) {
    final edition = this.edition(editionId);
    typeface ??= QuranTypeface.forScript(edition.script).first;
    final key = (editionId, number, typeface);
    final cached = _pageCache.remove(key);
    if (cached != null) return _pageCache[key] = cached; // move to MRU end

    final column = typeface.column;
    final lineRows = _db.select(
      'SELECT line, kind, centered, first_word, last_word, surah, bismillah_inline '
      'FROM lines WHERE edition = ? AND page = ? ORDER BY line',
      [editionId, number],
    );
    final wordRows = _db.select(
      'SELECT w.id, w.surah, w.ayah, w.is_end, w.$column AS text FROM words w '
      'WHERE w.id BETWEEN '
      '(SELECT MIN(first_word) FROM lines WHERE edition = ?1 AND page = ?2) AND '
      '(SELECT MAX(last_word) FROM lines WHERE edition = ?1 AND page = ?2) ORDER BY w.id',
      [editionId, number],
    );
    final words = {
      for (final r in wordRows)
        r['id'] as int: Word(
          r['id'] as int,
          r['surah'] as int,
          r['ayah'] as int,
          r['is_end'] == 1,
          r['text'] as String,
          gapAfter: _gaps(typeface)[r['id'] as int] ?? 0,
          touchAfter: _touch(typeface, r['id'] as int),
          inkLeft: _ink(typeface, r['id'] as int, 0),
          inkRight: _ink(typeface, r['id'] as int, 1),
        ),
    };
    final lines = [
      for (final r in lineRows)
        PageLine(
          number: r['line'] as int,
          kind: LineKind.values[r['kind'] as int],
          surah: r['surah'] as int? ?? 1,
          centered: r['centered'] == 1,
          bismillahInline: r['bismillah_inline'] == 1,
          words: r['first_word'] == null
              ? const []
              : [
                  for (
                    var id = r['first_word'] as int;
                    id <= (r['last_word'] as int);
                    id++
                  )
                    words[id]!,
                ],
        ),
    ];
    final first = lines.expand((l) => l.words).firstOrNull;
    final juz = first == null
        ? 1
        : _db.select('SELECT juz FROM ayahs WHERE surah = ? AND ayah = ?', [
                first.surah,
                first.ayah,
              ]).first['juz']
              as int;

    final page = MushafPage(number, lines, juz, edition, typeface);
    _pageCache[key] = page;
    if (_pageCache.length > 40) _pageCache.remove(_pageCache.keys.first);
    return page;
  }
}

/// Overridden in main() once the database has been opened.
final quranDbProvider = Provider<QuranDb>(
  (ref) => throw UnimplementedError('quranDbProvider must be overridden'),
);
