import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/settings.dart';
import '../../data/models.dart';

/// One Quran word (or ayah-end marker), shaped on its own.
///
/// Words must never share a text run with their neighbours:
/// - The IndoPak font's ayah markers, and a few special letter forms, are
///   private-use characters, which Unicode treats as left-to-right. Two of them
///   side by side across a word gap (20 places, e.g. 67:1-2) would be
///   reordered by the bidi algorithm if laid out as one paragraph.
/// - Many words contain an internal space before a waqf sign. Justified text
///   would stretch that space and detach the sign from its word.
class QuranWord extends StatelessWidget {
  const QuranWord({
    super.key,
    required this.word,
    required this.typeface,
    required this.style,
    required this.markerStyle,
  });

  final Word word;
  final QuranTypeface typeface;
  final TextStyle style;
  final TextStyle markerStyle;

  /// The string whose width equals this word's rendered width.
  static String measureText(Word w, QuranTypeface typeface) =>
      w.isAyahEnd && typeface.drawMarkers
      ? DrawnAyahMarker.measureText(w.text)
      : w.text;

  /// Rendered width of [w] at [style]'s font and size.
  ///
  /// Glyph advances scale linearly with font size, so each distinct word is
  /// shaped once, at a reference size, and every later request is arithmetic.
  /// Laying out pages this way keeps page turns smooth.
  static double widthOf(Word w, QuranTypeface typeface, TextStyle style) =>
      textWidth(measureText(w, typeface), style);

  static const _refSize = 100.0;
  static final _widths = <(String?, String), double>{};

  /// Width of [text] set in [style] (only family and size are considered).
  static double textWidth(String text, TextStyle style) {
    final ref = _widths.putIfAbsent((style.fontFamily, text), () {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontFamily: style.fontFamily, fontSize: _refSize),
        ),
        textDirection: TextDirection.rtl,
        maxLines: 1,
      )..layout();
      final width = tp.width;
      tp.dispose();
      return width;
    });
    return ref * style.fontSize! / _refSize;
  }

  @override
  Widget build(BuildContext context) {
    final child = word.isAyahEnd && typeface.drawMarkers
        ? DrawnAyahMarker(word.text, markerStyle)
        : Text(
            word.text,
            style: word.isAyahEnd ? markerStyle : style,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            softWrap: false,
          );
    // Room for ink reaching past the word's box (Word.inkLeft, inkRight),
    // and for signs that reach towards the next word (Word.gapAfter).
    final left = math.max(word.gapAfter, word.inkLeft);
    if (left == 0 && word.inkRight == 0) return child;
    return Padding(
      padding: EdgeInsets.only(
        left: left * style.fontSize!,
        right: word.inkRight * style.fontSize!,
      ),
      child: child,
    );
  }
}

/// An ayah-end marker drawn by the app: the font's U+06DD ornament with the
/// ayah number centred over it, followed by any sign the word carries after
/// the digits (e.g. a waqf mark). Used for scripts whose text ends ayahs with
/// bare digits.
class DrawnAyahMarker extends StatelessWidget {
  const DrawnAyahMarker(this.text, this.style, {super.key});

  final String text;
  final TextStyle style;

  static bool _isDigit(int c) => c >= 0x0660 && c <= 0x0669;

  static String _digits(String text) =>
      String.fromCharCodes(text.runes.takeWhile(_isDigit));

  static String measureText(String text) =>
      '۝${text.substring(_digits(text).length)}';

  @override
  Widget build(BuildContext context) {
    final digits = _digits(text);
    final rest = text.substring(digits.length);
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Text('۝', style: style),
            Text(
              digits,
              style: style.copyWith(
                fontSize: style.fontSize! * (digits.length > 2 ? 0.42 : 0.55),
              ),
            ),
          ],
        ),
        if (rest.isNotEmpty)
          Text(rest, style: style, textDirection: TextDirection.rtl),
      ],
    );
  }
}
