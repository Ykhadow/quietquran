import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../core/settings.dart';
import '../../data/models.dart';

/// Laid-out text for single Quran words, shared by every page.
///
/// Shaping Arabic text is the expensive part of drawing a page. Each distinct
/// (font, size, colour, word) is shaped once and reused; with one font size
/// per edition, most words on a new page are already here.
class WordShapes {
  WordShapes._();

  /// Enough for the words of about 25 pages: the neighbouring pages need
  /// about 1000.
  static const _capacity = 4000;
  // Insertion-ordered, so the first key is the least recently used.
  static final _cache = <(String?, double, int, String), TextPainter>{};

  static TextPainter of(String text, TextStyle style) {
    final key = (
      style.fontFamily,
      style.fontSize!,
      style.color!.toARGB32(),
      text,
    );
    final hit = _cache.remove(key);
    if (hit != null) return _cache[key] = hit; // most recently used
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout();
    _cache[key] = painter;
    if (_cache.length > _capacity) _cache.remove(_cache.keys.first)!.dispose();
    return painter;
  }

  /// Frees every shaped word (shaped again when next drawn). For low memory.
  static void clear() {
    for (final painter in _cache.values) {
      painter.dispose();
    }
    _cache.clear();
  }
}

/// How a line fills its width.
enum LineAlign { justify, right, center }

/// Draws one line of Quran words right to left.
///
/// Words are placed by hand, never by the text engine, so reading order can
/// not be disturbed by bidi rules (see [QuranLinePainter.place]). A word and
/// the ayah-end marker after it are kept together; justification widens only
/// the other gaps.
class QuranLinePainter extends CustomPainter {
  QuranLinePainter({
    required this.words,
    required this.typeface,
    required this.style,
    required this.markerStyle,
    required this.align,
    this.maxGrow = 1,
    this.marked = const {},
    this.highlight,
    this.wordGap = 0.18,
  });

  final List<Word> words;
  final QuranTypeface typeface;
  final TextStyle style;
  final TextStyle markerStyle;
  final LineAlign align;

  /// Ayahs (surah, ayah) to tint, such as bookmarked ones.
  final Set<(int, int)> marked;

  /// The ayah being recited, shown more strongly than [marked].
  final (int, int)? highlight;

  /// How much larger than [style] a justified line with room to spare may be
  /// drawn. Mushaf pages grow such lines to fill the width, as calligraphers
  /// size each line of a printed Mushaf, instead of spreading the words apart.
  /// Lines that grow the full amount spread their words over what's left.
  final double maxGrow;

  /// Space between words, as a share of the font size (see
  /// Word.spaceBefore). On Mushaf pages it must be Word.mushafGap, which the
  /// build script sizes text to fit with; Easy read lets the reader choose.
  final double wordGap;

  /// Shapes every word of the line (warming [WordShapes]).
  void shape() {
    for (final w in words) {
      _pieces(w);
    }
  }

  /// A word as one or more shaped pieces, right to left.
  List<(TextPainter, double dy)> _pieces(Word w) {
    if (!(w.isAyahEnd && typeface.drawMarkers)) {
      return [(WordShapes.of(w.text, w.isAyahEnd ? markerStyle : style), 0)];
    }
    // Drawn marker: the U+06DD ornament, then any sign after the digits.
    final digits = String.fromCharCodes(
      w.text.runes.takeWhile((c) => c >= 0x0660 && c <= 0x0669),
    );
    final rest = w.text.substring(digits.length);
    return [
      (WordShapes.of('۝', markerStyle), 0),
      if (rest.isNotEmpty) (WordShapes.of(rest, markerStyle), 0),
    ];
  }

  double _width(Word w) => _pieces(w).fold(0.0, (s, p) => s + p.$1.width);

  /// The line's width with plain gaps: its words, the gaps between them, and
  /// any extra space pairs need (see Word.gapAfter).
  double get naturalWidth {
    var width = 0.0;
    for (var i = 0; i < words.length; i++) {
      width += _width(words[i]);
      if (i > 0) {
        width += words[i - 1].spaceBefore(words[i], wordGap) * style.fontSize!;
      }
    }
    return width;
  }

  /// Each word's box, in the line's coordinates, in reading order. Also the
  /// scale the line is drawn at: below 1 when the line is too long for
  /// [size], above 1 when it grows (see [maxGrow]).
  (List<(Word, Rect)>, double) place(Size size) {
    if (words.isEmpty) return (const [], 1);
    final widths = [for (final w in words) _width(w)];
    // A gap before a marker is fixed; the rest can stretch.
    final glued = [for (var i = 1; i < words.length; i++) words[i].isAyahEnd];
    // Each gap: the plain gap, plus any extra that pair needs to keep their
    // ink apart (see Word.gapAfter).
    final gaps = [
      for (var i = 1; i < words.length; i++)
        words[i - 1].spaceBefore(words[i], wordGap) * style.fontSize!,
    ];
    final natural =
        widths.fold(0.0, (a, b) => a + b) + gaps.fold(0.0, (a, b) => a + b);
    // The ink of the line's first word (on the right) and last (on the
    // left) can reach past their boxes; that room is kept inside the line,
    // so nothing is cut off at the page's edge.
    final inkRight = words.first.inkRight * style.fontSize!;
    final inkLeft = words.last.inkLeft * style.fontSize!;
    final needed = natural + inkRight + inkLeft;
    final fits = size.width / needed;
    final justify = align == LineAlign.justify;
    final scale = fits < 1
        ? fits
        : justify
        ? fits.clamp(1.0, maxGrow)
        : 1.0;
    final free = glued.where((g) => !g).length;
    // Space left over after growing, shared between the words (in unscaled
    // units, like the gaps).
    final extra = justify && free > 0
        ? math.max(0.0, size.width / scale - needed) / free
        : 0.0;
    var x = switch (align) {
      _ when scale < 1 => size.width - inkRight * scale,
      LineAlign.justify || LineAlign.right => size.width - inkRight * scale,
      LineAlign.center => size.width - (size.width - needed) / 2 - inkRight,
    };
    final out = <(Word, Rect)>[];
    for (var i = 0; i < words.length; i++) {
      if (i > 0) x -= (gaps[i - 1] + (glued[i - 1] ? 0 : extra)) * scale;
      final w = widths[i] * scale;
      final h = _pieces(words[i]).first.$1.height * scale;
      out.add((words[i], Rect.fromLTWH(x - w, (size.height - h) / 2, w, h)));
      x -= w;
    }
    return (out, scale);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final (placed, scale) = place(size);
    if (marked.isNotEmpty) {
      _paintMarks(canvas, size, placed, marked.contains, 0.12);
    }
    final h = highlight;
    if (h != null) _paintMarks(canvas, size, placed, (a) => a == h, 0.24);
    for (final (word, rect) in placed) {
      canvas.save();
      // Draw at the line's scale around the word's vertical centre.
      canvas.translate(rect.right, rect.center.dy);
      canvas.scale(scale);
      canvas.translate(0, -rect.height / scale / 2);
      var x = 0.0;
      for (final (piece, dy) in _pieces(word)) {
        x -= piece.width;
        piece.paint(canvas, Offset(x, dy));
      }
      if (word.isAyahEnd && typeface.drawMarkers) _paintDigits(canvas, word);
      canvas.restore();
    }
  }

  /// A soft band behind each run of words whose ayah is [marks], gaps
  /// included, kept within the line so bands on neighbouring lines don't
  /// overlap.
  void _paintMarks(
    Canvas canvas,
    Size size,
    List<(Word, Rect)> placed,
    bool Function((int, int) ayah) marks,
    double alpha,
  ) {
    final paint = Paint()
      ..color = (markerStyle.color ?? const Color(0xFF888888)).withValues(
        alpha: alpha,
      );
    final line = Offset.zero & size;
    final pad = style.fontSize! * 0.12;
    Rect? run;
    void flush() {
      if (run == null) return;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            run!.left - pad,
            line.top + size.height * 0.08,
            run!.right + pad,
            line.bottom - size.height * 0.08,
          ).intersect(line),
          Radius.circular(size.height * 0.2),
        ),
        paint,
      );
      run = null;
    }

    for (final (w, r) in placed) {
      if (marks((w.surah, w.ayah))) {
        run = run?.expandToInclude(r) ?? r;
      } else {
        flush();
      }
    }
    flush();
  }

  /// The ayah number over a drawn marker's ornament.
  void _paintDigits(Canvas canvas, Word w) {
    final digits = String.fromCharCodes(
      w.text.runes.takeWhile((c) => c >= 0x0660 && c <= 0x0669),
    );
    final ornament = WordShapes.of('۝', markerStyle);
    final number = WordShapes.of(
      digits,
      markerStyle.copyWith(
        fontSize: markerStyle.fontSize! * (digits.length > 2 ? 0.42 : 0.55),
      ),
    );
    canvas.translate(-ornament.width, 0);
    number.paint(
      canvas,
      Offset(
        (ornament.width - number.width) / 2,
        (ornament.height - number.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(QuranLinePainter old) =>
      !identical(old.words, words) ||
      old.style != style ||
      old.markerStyle != markerStyle ||
      old.align != align ||
      old.typeface != typeface ||
      old.maxGrow != maxGrow ||
      old.wordGap != wordGap ||
      old.highlight != highlight ||
      !setEquals(old.marked, marked);
}

/// A painted line of Quran words, readable by screen readers.
class QuranLine extends StatelessWidget {
  const QuranLine({
    super.key,
    required this.words,
    required this.typeface,
    required this.style,
    required this.markerStyle,
    required this.align,
    this.height,
    this.maxGrow = 1,
    this.marked = const {},
    this.highlight,
    this.wordGap = 0.18,
  });

  final List<Word> words;
  final QuranTypeface typeface;
  final TextStyle style;
  final TextStyle markerStyle;
  final LineAlign align;
  final double? height;

  /// See [QuranLinePainter.highlight].
  final (int, int)? highlight;

  /// See [QuranLinePainter.maxGrow].
  final double maxGrow;

  /// See [QuranLinePainter.marked].
  final Set<(int, int)> marked;

  /// See [QuranLinePainter.wordGap].
  final double wordGap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: words.where((w) => !w.isAyahEnd).map((w) => w.text).join(' '),
    textDirection: TextDirection.rtl,
    child: CustomPaint(
      size: Size(
        double.infinity,
        height ?? style.fontSize! * (style.height ?? 1),
      ),
      painter: QuranLinePainter(
        words: words,
        typeface: typeface,
        style: style,
        markerStyle: markerStyle,
        align: align,
        maxGrow: maxGrow,
        marked: marked,
        highlight: highlight,
        wordGap: wordGap,
      ),
    ),
  );
}

/// Shapes lines ahead of time in idle moments, so turning to a page only has
/// to draw it. Work is split into small tasks that never block a frame.
class ShapePrefetcher {
  ShapePrefetcher._();

  static final _queue = Queue<QuranLinePainter>();
  static bool _scheduled = false;

  /// Tests switch this off: queued idle tasks would outlive a test.
  @visibleForTesting
  static bool enabled = true;

  static void add(Iterable<QuranLinePainter> lines) {
    if (!enabled) return;
    _queue.addAll(lines);
    _schedule();
  }

  static void _schedule() {
    if (_scheduled || _queue.isEmpty) return;
    _scheduled = true;
    SchedulerBinding.instance.scheduleTask(() {
      _scheduled = false;
      // About one line per task keeps each task well under a frame.
      if (_queue.isNotEmpty) _queue.removeFirst().shape();
      _schedule();
    }, Priority.idle);
  }
}

/// Every painted Quran word under [root], with its box in [root]'s
/// coordinates. Used to find the ayah under a finger and to highlight it.
/// The word under [p], or the nearest on the same line (within 40px), from
/// [collectPlacements].
Word? wordAt(List<(Word, Rect)> words, Offset p) {
  Word? best;
  var bestDistance = double.infinity;
  for (final (w, r) in words) {
    if (p.dy < r.top - r.height * 0.3 || p.dy > r.bottom + r.height * 0.3) {
      continue;
    }
    final dx = p.dx < r.left
        ? r.left - p.dx
        : (p.dx > r.right ? p.dx - r.right : 0.0);
    if (dx < bestDistance) {
      bestDistance = dx;
      best = w;
    }
  }
  return bestDistance < 40 ? best : null;
}

List<(Word, Rect)> collectPlacements(RenderObject root) {
  final out = <(Word, Rect)>[];
  void visit(RenderObject r) {
    if (r is RenderCustomPaint && r.hasSize) {
      final painter = r.painter;
      if (painter is QuranLinePainter) {
        final origin = MatrixUtils.transformPoint(
          r.getTransformTo(root),
          Offset.zero,
        );
        for (final (w, rect) in painter.place(r.size).$1) {
          out.add((w, rect.shift(origin)));
        }
      }
    }
    r.visitChildren(visit);
  }

  visit(root);
  return out;
}
