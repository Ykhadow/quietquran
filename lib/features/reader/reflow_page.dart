import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/quran_db.dart';
import 'mushaf_text_page.dart';
import 'quran_line.dart';
import 'quran_word.dart';
import 'translation_text.dart';

/// A Mushaf page's text reflowed at the reader's chosen font size ("Easy
/// read") — for readers who want larger text than the fixed Mushaf page
/// allows. It still reads as a page: the surah and juz above, the page
/// number below, and each surah opening with the Mushaf's own header.
///
/// Lines are built here, not by the text engine: each word is measured and
/// placed in a right-to-left row, the same way the Mushaf page draws its
/// lines. Letting the engine lay out a paragraph of word widgets gave a wrong
/// word order on some lines, so reading order must never depend on it.
class ReflowPage extends StatelessWidget {
  const ReflowPage({
    super.key,
    required this.page,
    required this.db,
    required this.fontSize,
    this.translation,
    this.onAyahLongPress,
    this.marked = const {},
    this.highlight,
    this.juzLabel,
    this.wordSpacing = 0.08,
    this.scrolls = true,
  });

  /// Scrolls its own text (a page of its own); false when the page sits in
  /// a longer scroll (vertical reading), taking the height its text needs.
  final bool scrolls;

  /// Space between words, as a share of [fontSize] (see
  /// Settings.reflowWordSpacing).
  final double wordSpacing;

  /// The running head's juz label in the app's language (see
  /// MushafTextPage.juzLabel).
  final String? juzLabel;

  /// Ayahs to tint (bookmarked ones).
  final Set<(int, int)> marked;

  /// The ayah being recited: shown more strongly, and scrolled into view.
  final (int, int)? highlight;

  final MushafPage page;
  final QuranDb db;
  final double fontSize;

  /// Shown under each ayah (on the page where the ayah ends), or null.
  final Translation? translation;

  /// Called with the ayah under a long press (to show its translation and
  /// actions), as on a Mushaf page.
  final void Function(int surah, int ayah)? onAyahLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens;
    final typeface = page.typeface;
    final style = TextStyle(
      fontFamily: typeface.fontFamily,
      fontSize: fontSize,
      height: typeface.script == QuranScript.indopak ? 2.1 : 1.9,
      color: colors.ink,
    );
    final markerStyle = style.copyWith(color: colors.acc);

    Widget paragraph(
      List<List<Word>> units, {
      bool center = false,
      bool ayahs = true,
    }) => QuranParagraph(
      units: units,
      typeface: typeface,
      style: style,
      markerStyle: markerStyle,
      center: center,
      wordGap: wordSpacing,
      // A surah's opening bismillah isn't an ayah a bookmark or the
      // recitation can mean.
      marked: ayahs ? marked : const {},
      highlight: ayahs ? highlight : null,
    );

    final blocks = <Widget>[];
    final pairRule = Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(height: 1, color: colors.line2),
    );
    // Consecutive text lines form one paragraph, broken by surah headers.
    // A unit is a group of words that must stay on one line: an ayah's last
    // word travels with its end marker.
    var units = <List<Word>>[];
    void flush({bool center = false}) {
      if (units.isEmpty) return;
      blocks.add(paragraph(units, center: center));
      units = [];
    }

    void addBismillah() => blocks.add(
      paragraph(
        [
          for (final w in db.bismillah(typeface)) [w],
        ],
        center: true,
        ayahs: false,
      ),
    );

    for (final line in page.lines) {
      switch (line.kind) {
        case LineKind.surahHeader:
          flush();
          blocks.add(
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 10),
              child: LayoutBuilder(
                builder: (context, box) => SurahHeader(
                  surah: db.surah(line.surah),
                  script: typeface.script,
                  style: style.copyWith(height: 1.6),
                  // Its labels are sized from the width; kept to what a
                  // phone shows, so they don't grow huge on a desktop.
                  width: box.maxWidth.clamp(0, 560).toDouble(),
                ),
              ),
            ),
          );
          if (line.bismillahInline) addBismillah();
        case LineKind.bismillah:
          flush();
          addBismillah();
        case LineKind.text:
          for (final w in line.words) {
            // Al-Fatihah's first ayah is its bismillah, and every print sets
            // it on a line of its own, centred: so does Easy read.
            final opening = (w.surah, w.ayah) == (1, 1);
            if (opening && units.isNotEmpty && !_opens(units.first)) flush();
            if (!opening && units.isNotEmpty && _opens(units.first)) {
              flush(center: true);
            }
            if (w.isAyahEnd && units.isNotEmpty && !units.last.last.isAyahEnd) {
              units.last.add(w);
            } else {
              units.add([w]);
            }
            // With a translation, each ayah is its own paragraph, followed
            // by its meaning.
            final tr = translation;
            if (tr != null && w.isAyahEnd) {
              flush(center: opening);
              final text = db.translationText(tr.id, w.surah, w.ayah);
              if (text != null) {
                blocks.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
                    child: TranslationText(
                      translation: tr,
                      text: text,
                      fontSize: (fontSize * 0.55).clamp(15.0, 26.0),
                    ),
                  ),
                );
                // A faint rule closes each ayah and its translation, so
                // pairs don't run together (most of all when both read right
                // to left).
                blocks.add(pairRule);
              }
            }
          }
      }
    }
    flush(center: units.isNotEmpty && _opens(units.first));
    // The page's own rule follows the last pair.
    if (blocks.isNotEmpty && identical(blocks.last, pairRule)) {
      blocks.removeLast();
    }

    // The page number closes the page's text: on a page that scrolls it
    // comes into view only at the end, so the reader knows the page is done
    // before turning it.
    final rule = PageRule(color: colors.mut.withValues(alpha: 0.45));
    final footer = Column(
      children: [
        rule,
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${page.number}',
            style: TextStyle(
              fontFamily: AppType.sans,
              fontSize: 13,
              color: colors.mut,
            ),
          ),
        ),
      ],
    );

    const listPadding = EdgeInsets.fromLTRB(4, 12, 4, 24);
    final list = scrolls
        ? ListView(
            padding: listPadding.copyWith(bottom: 4),
            children: [...blocks, const SizedBox(height: 20), footer],
          )
        : Padding(
            padding: listPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: blocks,
            ),
          );
    final onPress = onAyahLongPress;
    // Find the word under the finger from the lines as they're painted.
    final text = onPress == null
        ? list
        : Builder(
            builder: (context) => GestureDetector(
              onLongPressStart: (d) {
                final box = context.findRenderObject();
                if (box == null) return;
                final hit = wordAt(collectPlacements(box), d.localPosition);
                if (hit != null) onPress(hit.surah, hit.ayah);
              },
              child: list,
            ),
          );

    // Framed like a Mushaf page: where you are above, the page number below
    // the text.
    return MediaQuery.withNoTextScaling(
      child: LayoutBuilder(
        builder: (context, box) {
          // Header sizes follow the width, up to what a phone shows.
          final w = box.maxWidth.clamp(0, 520).toDouble();
          return ColoredBox(
            color: colors.bg,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                mainAxisSize: scrolls ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  RunningHead(
                    page: page,
                    db: db,
                    width: w,
                    juzLabel: juzLabel ?? 'JUZ ${page.juz}',
                  ),
                  rule,
                  if (scrolls) Expanded(child: text) else ...[text, footer],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Whether [unit] is part of Al-Fatihah's first ayah, its bismillah.
bool _opens(List<Word> unit) => (unit.first.surah, unit.first.ayah) == (1, 1);

/// Words broken into right-to-left lines that fill the available width.
/// Every line but the last is justified; the last is right-aligned, or
/// centred ([centerLast]). [center] centres every line (the bismillah).
class QuranParagraph extends StatelessWidget {
  const QuranParagraph({
    super.key,
    required this.units,
    required this.typeface,
    required this.style,
    required this.markerStyle,
    this.center = false,
    this.centerLast = false,
    this.marked = const {},
    this.highlight,
    this.wordGap = 0.3,
  });

  /// Space between words, as a share of the font size: the least they have
  /// (lines are then justified to the full width). See Word.spaceBefore.
  final double wordGap;

  /// [words] as units that must stay on one line: an ayah's last word
  /// travels with its end marker.
  static List<List<Word>> unitsOf(Iterable<Word> words) {
    final units = <List<Word>>[];
    for (final w in words) {
      if (w.isAyahEnd && units.isNotEmpty && !units.last.last.isAyahEnd) {
        units.last.add(w);
      } else {
        units.add([w]);
      }
    }
    return units;
  }

  final Set<(int, int)> marked;

  /// The ayah being recited (see QuranLinePainter.highlight); the line it
  /// starts on is kept in view.
  final (int, int)? highlight;
  final List<List<Word>> units;
  final QuranTypeface typeface;
  final TextStyle style;
  final TextStyle markerStyle;
  final bool center;
  final bool centerLast;

  /// The space the painter leaves between [a] and the word after it.
  double _space(Word a, Word b) => a.spaceBefore(b, wordGap) * style.fontSize!;

  double _unitWidth(List<Word> unit) {
    var width = 0.0;
    for (var i = 0; i < unit.length; i++) {
      width += QuranWord.widthOf(unit[i], typeface, style);
      if (i > 0) width += _space(unit[i - 1], unit[i]);
    }
    return width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final maxWidth = box.maxWidth;
        // Greedy line filling, in reading order.
        // Room is kept for ink reaching past a line's first and last words
        // (see QuranLinePainter.place).
        final fontSize = style.fontSize!;
        double inkRight(List<Word> unit) => unit.first.inkRight * fontSize;
        double inkLeft(List<Word> unit) => unit.last.inkLeft * fontSize;
        final lines = <List<List<Word>>>[];
        var current = <List<Word>>[];
        var used = 0.0; // without the last unit's ink on the left
        for (final unit in units) {
          final w = _unitWidth(unit);
          final next = current.isEmpty
              ? inkRight(unit) + w
              : used + _space(current.last.last, unit.first) + w;
          if (current.isNotEmpty && next + inkLeft(unit) > maxWidth) {
            lines.add(current);
            current = [unit];
            used = inkRight(unit) + w;
          } else {
            current.add(unit);
            used = next;
          }
        }
        if (current.isNotEmpty) lines.add(current);

        final h = highlight;
        final first = h == null
            ? -1
            : lines.indexWhere(
                (l) => l.any((u) => u.any((w) => (w.surah, w.ayah) == h)),
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < lines.length; i++)
              if (i == first)
                _KeepInView(
                  key: ValueKey(h),
                  child: _line(
                    lines[i],
                    justify: i < lines.length - 1 && !center,
                  ),
                )
              else
                _line(lines[i], justify: i < lines.length - 1 && !center),
          ],
        );
      },
    );
  }

  Widget _line(List<List<Word>> line, {required bool justify}) => QuranLine(
    words: [for (final unit in line) ...unit],
    typeface: typeface,
    style: style,
    markerStyle: markerStyle,
    align: justify && line.length > 1
        ? LineAlign.justify
        : center || centerLast
        ? LineAlign.center
        : LineAlign.right,
    height: style.fontSize! * (style.height ?? 1),
    marked: marked,
    highlight: highlight,
    wordGap: wordGap,
  );
}

/// Scrolls its child (the line a recited ayah starts on) into view of the
/// nearest scroll view when it first appears, unless it's already in view.
class _KeepInView extends StatefulWidget {
  const _KeepInView({super.key, required this.child});

  final Widget child;

  @override
  State<_KeepInView> createState() => _KeepInViewState();
}

class _KeepInViewState extends State<_KeepInView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  void _reveal() {
    if (!mounted) return;
    final box = context.findRenderObject();
    final scrollable = Scrollable.maybeOf(context);
    if (box is! RenderBox || !box.attached || scrollable == null) return;
    final position = scrollable.position;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null || !position.hasContentDimensions) return;
    // Where the scroll would put the line at the top, so where it is now.
    final atTop = viewport.getOffsetToReveal(box, 0).offset;
    final top = atTop - position.pixels;
    final view = position.viewportDimension;
    if (top >= 0 && top + box.size.height <= view * 0.9) return;
    position.animateTo(
      (atTop - view * 0.2).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
