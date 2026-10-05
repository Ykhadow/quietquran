import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/l10n.dart';

/// A strip of cells, one per juz (30) or per surah (114), laid out right to
/// left so the first is on the right. Every [landmark]th cell is a shade darker;
/// the current one is accented. Drag or tap anywhere on the strip to choose.
class Scrubber extends StatefulWidget {
  const Scrubber({
    super.key,
    required this.count,
    required this.current,
    required this.landmark,
    required this.unit,
    required this.onScrub,
    required this.onCommit,
    this.large = false,
  });

  /// Number of cells, e.g. 30 juz or 114 surahs.
  final int count;

  /// The cell the reader is in (1-based).
  final int current;

  /// Every this many cells is drawn darker, as a landmark.
  final int landmark;

  /// What a cell is, for screen readers ("Juz", "Surah").
  final String unit;

  /// Called while dragging, with the cell under the finger (null when the
  /// drag ends).
  final ValueChanged<int?> onScrub;

  /// Called when the finger lifts, with the chosen cell.
  final ValueChanged<int> onCommit;

  /// The bigger handle shown while scrubbing.
  final bool large;

  @override
  State<Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends State<Scrubber> {
  int? _drag;

  int _cellAt(double dx, double width) {
    // Right to left: the right edge is the first cell.
    final fromRight = (width - dx).clamp(0.0, width - 0.001);
    return (fromRight / width * widget.count).floor() + 1;
  }

  void _update(double dx, double width) {
    final j = _cellAt(dx, width);
    if (j != _drag) {
      HapticFeedback.selectionClick();
      setState(() => _drag = j);
      widget.onScrub(j);
    }
  }

  void _end() {
    final j = _drag;
    setState(() => _drag = null);
    widget.onScrub(null);
    if (j != null) widget.onCommit(j);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final current = _drag ?? widget.current;
    final large = widget.large || _drag != null;
    final count = widget.count;
    return Semantics(
      label: context.l10n.scrubberLabel(widget.unit, current, count),
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth;
          final cellGap = count > 40 ? 1.0 : 2.0;
          final cellWidth = (width - cellGap * (count - 1)) / count;
          // Centre of the current juz's cell, measured from the left.
          final handleX = width - (current - 0.5) * (cellWidth + cellGap);
          final handleW = large ? 18.0 : 14.0;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _update(d.localPosition.dx, width),
            onHorizontalDragUpdate: (d) => _update(d.localPosition.dx, width),
            onHorizontalDragEnd: (_) => _end(),
            onTapDown: (d) => _update(d.localPosition.dx, width),
            onTapUp: (_) => _end(),
            child: SizedBox(
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      for (var j = 1; j <= count; j++) ...[
                        if (j > 1) SizedBox(width: cellGap),
                        Expanded(
                          child: Container(
                            height: 22,
                            decoration: BoxDecoration(
                              color: j == current
                                  ? t.acc
                                  : j % widget.landmark == 0
                                  ? t.juzCell5
                                  : t.juzCell,
                              borderRadius: BorderRadius.circular(
                                count > 40 ? 1 : 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Positioned(
                    left: handleX - handleW / 2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: handleW,
                      height: 36,
                      decoration: BoxDecoration(
                        color: t.ink,
                        borderRadius: BorderRadius.circular(large ? 9 : 7),
                        border: Border.all(
                          color: large ? t.ring : t.bg,
                          width: large ? 4 : 3,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
