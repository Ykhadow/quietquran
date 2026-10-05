import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/quran_db.dart';
import 'quran_line.dart';

/// Largest enlargement of the opening pages' text (pages 1 and 2).
const _openingMaxScale = 1.6;

/// Largest growth for a line with room to spare (see QuranLinePainter.maxGrow).
const _maxGrow = 1.3;

/// Renders one Mushaf page from live text, line for line as in the printed
/// edition: justified to the page width, or centred where the print centres.
class MushafTextPage extends StatelessWidget {
  const MushafTextPage({
    super.key,
    required this.page,
    required this.db,
    this.juzLabel,
    this.marked = const {},
  });

  final MushafPage page;
  final QuranDb db;

  /// Ayahs to tint (bookmarked ones).
  final Set<(int, int)> marked;

  /// The running head's juz label in the app's language ("JUZ 29",
  /// "پارہ 29"). Pages can be drawn offscreen, away from the app's
  /// localizations, so the reader passes it in.
  final String? juzLabel;

  QuranTypeface get typeface => page.typeface;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // The page has its own fixed layout: the phone's text size setting would
    // resize its labels (and differently from its prepared picture, which is
    // drawn without it). Reflow is where text size is chosen.
    return MediaQuery.withNoTextScaling(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          final head = RunningHead(
            page: page,
            db: db,
            width: w,
            juzLabel: juzLabel ?? 'JUZ ${page.juz}',
          );
          final number = Padding(
            padding: EdgeInsets.only(top: h * 0.015),
            child: Text(
              '${page.number}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppType.sans,
                fontSize: w * 0.028,
                color: t.mut,
              ),
            ),
          );
          return ColoredBox(
            color: t.bg,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                w * 0.045,
                h * 0.06,
                w * 0.045,
                h * 0.035,
              ),
              child: Column(
                children: [
                  head,
                  PageRule(color: t.mut.withValues(alpha: 0.45)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: h * 0.008),
                      child: _body(context),
                    ),
                  ),
                  PageRule(color: t.mut.withValues(alpha: 0.45)),
                  number,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// The edition's lines, each an equal share of the height, except that a
  /// line holding both a surah name and its bismillah gets
  /// [QuranDb.openingLineWeight] shares.
  Widget _body(BuildContext context) {
    final t = context.tokens;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final edition = page.edition.id;
        final linesPerPage = page.edition.linesPerPage;
        double weight(PageLine l) =>
            l.kind == LineKind.surahHeader && l.bismillahInline
            ? QuranDb.openingLineWeight
            : 1;
        final pageWeight = page.lines.fold(0.0, (sum, l) => sum + weight(l));
        var lineHeight =
            box.maxHeight / math.max(linesPerPage.toDouble(), pageWeight);
        // One size for the whole edition: as large as the most crowded page's
        // lines allow, and small enough that nearly every justified line fits
        // the width.
        var fontSize = math.min(
          box.maxHeight / db.maxPageWeight(edition) * typeface.lineFill,
          width * 100 / db.lineFit(edition, typeface),
        );
        // The opening pages (Al-Fatihah, the start of Al-Baqarah) hold a few
        // short centred lines; like a printed Mushaf, set them larger. The
        // whole page scales together, until the widest line meets the width
        // or the lines fill the height, so line spacing keeps its proportions.
        if (page.number <= 2 && page.lines.length < linesPerPage) {
          final base = TextStyle(
            fontFamily: typeface.fontFamily,
            fontSize: fontSize,
            color: t.ink,
            height: 1.0,
          );
          final widest = [
            for (final l in page.lines)
              if (l.kind == LineKind.text || l.kind == LineKind.bismillah)
                QuranLinePainter(
                  words: l.kind == LineKind.text
                      ? l.words
                      : db.bismillah(typeface),
                  typeface: typeface,
                  style: base,
                  markerStyle: base,
                  align: LineAlign.center,
                ).naturalWidth,
          ].fold(0.0, math.max);
          final scale = [
            _openingMaxScale,
            0.9 * box.maxHeight / (pageWeight * lineHeight),
            if (widest > 0) 0.96 * width / widest,
          ].reduce(math.min);
          if (scale > 1) {
            fontSize *= scale;
            lineHeight *= scale;
          }
        }
        final style = TextStyle(
          fontFamily: typeface.fontFamily,
          fontSize: fontSize,
          color: t.ink,
          height: 1.0,
        );
        final markerStyle = style.copyWith(color: t.acc);
        // Lines with room to spare grow to fill the width, as each line of a
        // printed Mushaf is sized by its calligrapher: up to [_maxGrow], and
        // only as far as the line height leaves room (with a margin), so a
        // grown line's marks never reach its neighbours'. Checked glyph by
        // glyph for every page of every edition at many screen shapes by
        // tool/check_line_spacing.py.
        final grow = math.max(
          1.0,
          math.min(_maxGrow, lineHeight * typeface.lineFill * 0.96 / fontSize),
        );
        // Surah names and bismillahs share one size across the edition (see
        // TextEdition.sharedBismillah).
        final openingSize = page.edition.sharedBismillah
            ? fontSize * 0.75
            : fontSize;
        final openingStyle = style.copyWith(fontSize: openingSize);

        // Opening pages hold fewer lines; keep them vertically centred.
        final short = page.lines.length < linesPerPage;
        QuranLine line(PageLine l, LineAlign align) => QuranLine(
          words: l.words,
          typeface: typeface,
          style: style,
          markerStyle: markerStyle,
          align: align,
          height: lineHeight,
          maxGrow: grow,
          marked: marked,
        );
        final lines = [
          for (final l in page.lines)
            SizedBox(
              height: lineHeight * weight(l),
              child: switch (l.kind) {
                LineKind.text => line(
                  l,
                  l.centered || short ? LineAlign.center : LineAlign.justify,
                ),
                LineKind.surahHeader => SurahHeader(
                  surah: db.surah(l.surah),
                  script: typeface.script,
                  style: openingStyle,
                  width: width,
                  bismillah: l.bismillahInline
                      ? QuranLine(
                          words: db.bismillah(typeface),
                          typeface: typeface,
                          style: openingStyle,
                          markerStyle: markerStyle,
                          align: LineAlign.center,
                          height: lineHeight * weight(l) / 2,
                        )
                      : null,
                ),
                LineKind.bismillah => QuranLine(
                  words: db.bismillah(typeface),
                  typeface: typeface,
                  style: openingStyle,
                  markerStyle: markerStyle,
                  align: LineAlign.center,
                  height: lineHeight,
                ),
              },
            ),
        ];

        // Shape this page's words in idle time, so it draws instantly when a
        // swipe brings it on screen (neighbouring pages are laid out early).
        ShapePrefetcher.add([
          for (final l in page.lines)
            if (l.kind == LineKind.text)
              QuranLinePainter(
                words: l.words,
                typeface: typeface,
                style: style,
                markerStyle: markerStyle,
                align: LineAlign.justify,
              ),
        ]);

        return Column(
          mainAxisAlignment: short
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: lines,
        );
      },
    );
  }
}

/// The rule that opens and closes the text block, like the printed border
/// of a Mushaf page.
class PageRule extends StatelessWidget {
  const PageRule({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(height: 1, color: color);
}

final _latin = RegExp(r'^[\x00-\x7F]*$');

/// Surah names on the page (right) and the juz (left), above the text.
class RunningHead extends StatelessWidget {
  const RunningHead({
    super.key,
    required this.page,
    required this.db,
    required this.width,
    required this.juzLabel,
  });

  final MushafPage page;
  final QuranDb db;
  final double width;
  final String juzLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final names = page.surahs.map((s) => db.surah(s).nameArabic).join(' · ');
    return Padding(
      padding: EdgeInsets.only(bottom: width * 0.02),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              names,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppType.arabicSmall,
                fontSize: width * 0.034,
                height: 1.3,
                color: t.acc,
              ),
            ),
          ),
          Text(
            juzLabel,
            style: TextStyle(
              fontFamily: AppType.sans,
              fontFamilyFallback: AppType.fallback,
              fontSize: width * 0.026,
              // Spacing letters apart would break up joined Arabic script.
              letterSpacing: _latin.hasMatch(juzLabel)
                  ? width * 0.026 * 0.12
                  : null,
              color: t.mut,
            ),
          ),
        ],
      ),
    );
  }
}

/// A surah's opening: its name on a soft band, with its revelation place on
/// the right and verse count on the left.
class SurahHeader extends StatelessWidget {
  const SurahHeader({
    super.key,
    required this.surah,
    required this.script,
    required this.style,
    required this.width,
    this.bismillah,
  });

  final Surah surah;
  final QuranScript script;
  final TextStyle style;
  final double width;

  /// Shown under the name when the print has no separate bismillah line
  /// (Taj 16-line, Gaba): the two then share the line, half each.
  final Widget? bismillah;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final label = TextStyle(
      fontFamily: AppType.arabicSmall,
      fontSize: width * 0.03,
      color: t.mut,
    );
    final digits = script == QuranScript.indopak
        ? urduDigits(surah.versesCount)
        : arabicDigits(surah.versesCount);
    // The labels sit at the band's ends; the space between is left open.
    Widget rule() => const Expanded(child: SizedBox());
    // Labels keep their natural width (shrinking only if they must), so each
    // rule takes all the remaining space and the name stays centred.
    final gapWidth = width * 0.025;
    final gap = SizedBox(width: gapWidth);
    // One half of the header: a label and a rule. The label keeps its natural
    // width but never more than the half has room for (a long surah name
    // leaves the halves narrow), shrinking to fit.
    Widget half(String text, {required bool labelFirst}) => Expanded(
      child: LayoutBuilder(
        builder: (context, box) {
          final labelBox = ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.max(
                0,
                math.min(width * 0.16, box.maxWidth - gapWidth),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text, style: label, textDirection: TextDirection.rtl),
            ),
          );
          return Row(
            textDirection: TextDirection.rtl,
            children: labelFirst
                ? [labelBox, gap, rule()]
                : [rule(), gap, labelBox],
          );
        },
      ),
    );
    // Two equal halves either side of the name keep it exactly centred,
    // whatever the widths of the labels.
    final header = Row(
      textDirection: TextDirection.rtl,
      children: [
        half(surah.isMakki ? 'مكية' : 'مدنية', labelFirst: true),
        gap,
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width * 0.6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            // The name as a calligraphic title (its own lettering, so it
            // doesn't read as one more line of text beside the bismillah):
            // the font draws "surahNNN" as that surah's name.
            child: Text(
              'surah${surah.id.toString().padLeft(3, '0')}',
              semanticsLabel: 'سُورَةُ ${surah.nameArabic}',
              style: TextStyle(
                fontFamily: AppType.surahName,
                fontSize: style.fontSize! * 1.4,
                height: 1,
                color: t.acc,
              ),
            ),
          ),
        ),
        gap,
        half('آياتها $digits', labelFirst: false),
      ],
    );
    // A soft band in the page's surface colour, within the header's own
    // line (so the page's text size is unaffected): no rules, which stacked
    // up with the page rule above and crowded the bismillah below.
    // Square-cornered, like the printed page's frame and rules.
    final band = DecoratedBox(
      decoration: BoxDecoration(color: t.surf),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.03),
        child: header,
      ),
    );
    final shown = LayoutBuilder(
      builder: (context, box) => box.hasBoundedHeight
          // On a Mushaf page: most of the header's line.
          ? Center(child: FractionallySizedBox(heightFactor: 0.78, child: band))
          // In Easy read, where it takes the height it needs.
          : Padding(
              padding: EdgeInsets.symmetric(vertical: width * 0.01),
              child: band,
            ),
    );
    if (bismillah == null) return shown;
    return Column(
      children: [
        Expanded(child: shown),
        Expanded(child: bismillah!),
      ],
    );
  }
}
