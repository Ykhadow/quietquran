import 'dart:math' as math;

import '../core/settings.dart';

class Surah {
  const Surah({
    required this.id,
    required this.nameArabic,
    required this.nameSimple,
    required this.nameTranslated,
    required this.revelationPlace,
    required this.versesCount,
  });

  final int id;
  final String nameArabic;
  final String nameSimple;
  final String nameTranslated;
  final String revelationPlace;
  final int versesCount;

  bool get isMakki => revelationPlace == 'makkah';
}

/// A text layout: one printed Mushaf's line and page breaks.
class TextEdition {
  const TextEdition({
    required this.id,
    required this.name,
    required this.script,
    required this.linesPerPage,
    required this.pages,
    required this.sharedBismillah,
  });

  final String id;
  final String name;
  final QuranScript script;
  final int linesPerPage;
  final int pages;

  /// The print sometimes puts the bismillah inside the surah-header line
  /// (Taj 16-line, Gaba). Such editions draw every surah name and bismillah
  /// at the smaller size a shared line needs, so they all match.
  final bool sharedBismillah;
}

class JuzStart {
  const JuzStart(this.juz, this.page, this.surah, this.ayah);
  final int juz;
  final int page;
  final int surah;
  final int ayah;
}

class Word {
  const Word(
    this.id,
    this.surah,
    this.ayah,
    this.isAyahEnd,
    this.text, {
    this.gapAfter = 0,
    this.touchAfter,
    this.inkLeft = 0,
    this.inkRight = 0,
  });

  /// The Mushaf pages' space between words, as a share of the font size
  /// (WORD_GAP in tool/build_quran_db.py).
  static const mushafGap = 0.18;
  final int id;
  final int surah;
  final int ayah;
  final bool isAyahEnd;
  final String text;

  /// Extra space (em) needed between this word and the next (word [id] + 1)
  /// so their ink doesn't touch: some words' signs reach past the word's edge
  /// (see word_gap in tool/build_quran_db.py). Usually 0.
  final double gapAfter;

  /// The space (em) between this word and the next at which their ink
  /// would just touch; very negative where it can't meet. Null if the
  /// database doesn't say (see word_need in tool/build_quran_db.py).
  final double? touchAfter;

  /// How far (em) this word's ink reaches past its box on the left and on
  /// the right: a returning tail, a sign spreading past its space. A line
  /// keeps this room at its ends, so nothing is cut off (see word_ink in
  /// tool/build_quran_db.py).
  final double inkLeft;
  final double inkRight;

  /// Extra space (em) before [next] when it follows this word.
  double gapBefore(Word next) => next.id == id + 1 ? gapAfter : 0;

  /// The space (em) to leave before [next] for a chosen [gap] between words.
  /// From the Mushaf spacing up, it is [gap] plus what the pair needs to
  /// keep clear (as on Mushaf pages). Below it, each pair comes as close as
  /// its ink allows: never nearer than [gap], nor closer than a small clear
  /// space (which shrinks with [gap]) between the two words' ink.
  double spaceBefore(Word next, double gap) {
    final touch = touchAfter;
    if (gap >= mushafGap || touch == null || next.id != id + 1) {
      return gap + gapBefore(next);
    }
    // At least 0.07 em of clear space, so each word still reads as its own;
    // 0.12 at the Mushaf spacing, as on the pages (WORD_CLEAR).
    final clear = next.isAyahEnd ? 0.04 : 0.07 + 0.05 * gap / mushafGap;
    return math.max(0.02, math.max(gap, touch + clear));
  }
}

enum LineKind { text, surahHeader, bismillah }

class PageLine {
  const PageLine({
    required this.number,
    required this.kind,
    required this.surah,
    required this.words,
    required this.centered,
    required this.bismillahInline,
  });

  final int number;
  final LineKind kind;
  final int surah;
  final List<Word> words;

  /// The print centres this line instead of justifying it.
  final bool centered;

  /// Surah header that also carries the bismillah (no separate line for it).
  final bool bismillahInline;
}

class MushafPage {
  const MushafPage(
    this.number,
    this.lines,
    this.juz,
    this.edition,
    this.typeface,
  );
  final int number;
  final List<PageLine> lines;
  final int juz;
  final TextEdition edition;

  /// Text and font the words were loaded in.
  final QuranTypeface typeface;

  /// Surahs whose text appears on this page, in order.
  List<int> get surahs => {
    for (final l in lines)
      if (l.kind == LineKind.text) l.surah,
  }.toList();

  /// The first ayah whose text starts on this page, or the first ayah shown.
  (int, int) get firstAyah {
    for (final l in lines) {
      if (l.words.isNotEmpty) return (l.words.first.surah, l.words.first.ayah);
    }
    return (surahs.firstOrNull ?? 1, 1);
  }
}

/// A translation of the Quran's meanings, shown with (never instead of) the
/// Arabic text.
class Translation {
  const Translation({
    required this.id,
    required this.language,
    required this.translator,
  });

  final String id;

  /// Language code: 'en', 'ur'.
  final String language;
  final String translator;

  bool get rtl => language == 'ur' || language == 'ar';
}
