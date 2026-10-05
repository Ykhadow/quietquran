import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';

/// One ayah's translation of the meanings, in its own direction and script:
/// Urdu right to left in Nastaliq, English left to right. Shown as published.
class TranslationText extends StatelessWidget {
  const TranslationText({
    super.key,
    required this.translation,
    required this.text,
    this.fontSize = 16,
    this.color,
    this.textAlign = TextAlign.start,
    this.italic = false,
  });

  final Translation translation;
  final String text;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;

  /// Italic (in English), for a quieter translation under a large ayah.
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final urdu = translation.language == 'ur';
    return Text(
      text,
      textDirection: translation.rtl ? TextDirection.rtl : TextDirection.ltr,
      textAlign: textAlign,
      style: TextStyle(
        // Nastaliq for Urdu, as Urdu readers know it: its words slope down
        // and stack, so it needs much more line height. The reading serif for
        // English.
        fontFamily: urdu ? AppType.urdu : AppType.serif,
        fontFamilyFallback: AppType.fallback,
        fontSize: urdu ? fontSize * 1.12 : fontSize,
        height: urdu ? 2.3 : 1.5,
        color: color ?? t.ink,
        fontStyle: italic && !urdu ? FontStyle.italic : null,
      ),
    );
  }
}
