import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Pick a colour with one tap on a honeycomb: white at the centre, each hue
/// in its direction around it, growing more vivid towards the edge. A
/// brightness slider darkens the whole comb (for night palettes), a row of
/// greys runs from white to black, and a hex field takes an exact colour.
class ColourPicker extends StatefulWidget {
  const ColourPicker({super.key, required this.color, required this.onChanged});

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<ColourPicker> createState() => _ColourPickerState();
}

class _ColourPickerState extends State<ColourPicker> {
  late HSVColor _hsv = HSVColor.fromColor(widget.color);

  final _hex = TextEditingController();
  final _hexFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _hex.text = _hexOf(widget.color);
    _hexFocus.addListener(() {
      // Leaving the field shows the colour actually in use.
      if (!_hexFocus.hasFocus) _hex.text = _hexOf(_hsv.toColor());
    });
  }

  @override
  void dispose() {
    _hex.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ColourPicker old) {
    super.didUpdateWidget(old);
    // Follow outside changes (a swatch was tapped, another colour chosen for
    // editing).
    if (widget.color.toARGB32() != _hsv.toColor().toARGB32()) {
      _adopt(widget.color);
    }
  }

  void _adopt(Color c) {
    final next = HSVColor.fromColor(c);
    // Greys have no hue: keep ours, so the comb's mark doesn't jump.
    _hsv = next.saturation == 0 ? next.withHue(_hsv.hue) : next;
    if (!_hexFocus.hasFocus) _hex.text = _hexOf(c);
  }

  void _set(HSVColor v) {
    setState(() {
      _hsv = v;
      if (!_hexFocus.hasFocus) _hex.text = _hexOf(v.toColor());
    });
    widget.onChanged(v.toColor());
  }

  /// The comb's brightness: the colour's own, except near black, where a
  /// black comb would show nothing to pick from.
  double get _combValue => _hsv.value < 0.15 ? 1 : _hsv.value;

  static String _hexOf(Color c) =>
      (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final comb = _Comb.fit(box.maxWidth);
            final selected = comb.nearest(_hsv);
            void pick(Offset p) {
              final cell = comb.cellAt(p);
              if (cell != null) {
                _set(comb.colourOf(cell, _combValue));
              }
            }

            return Center(
              child: GestureDetector(
                onTapDown: (d) => pick(d.localPosition),
                onPanUpdate: (d) => pick(d.localPosition),
                child: CustomPaint(
                  size: comb.size,
                  painter: _CombPainter(
                    comb,
                    _combValue,
                    selected,
                    ring: t.ink,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _Greys(
          value: _hsv.saturation == 0 ? _hsv.value : null,
          ring: t.ink,
          onPick: (v) => _set(_hsv.withSaturation(0).withValue(v)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(l.colourBrightness, style: AppType.caption(t.mut)),
            Expanded(
              child: Slider(
                value: _hsv.value,
                onChanged: (v) => _set(_hsv.withValue(v)),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(l.hexCode, style: AppType.caption(t.mut)),
            const SizedBox(width: 12),
            SizedBox(
              width: 132,
              // Codes read left to right in every language, "#" first.
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _hex,
                  focusNode: _hexFocus,
                  style: AppType.body(t.ink),
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                  ],
                  decoration: InputDecoration(
                    counterText: '',
                    prefixText: '#',
                    prefixStyle: AppType.body(t.mut),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    if (v.length != 6) return;
                    final c = Color(0xFF000000 | int.parse(v, radix: 16));
                    setState(() => _adopt(c));
                    widget.onChanged(c);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The honeycomb's geometry: hexagonal cells (pointy-topped) in a large
/// hexagon [rings] cells from the centre, at axial coordinates (q, r).
class _Comb {
  _Comb(this.cell);

  /// Cells out from the centre: 6 makes 127 colours.
  static const rings = 6;

  /// Largest cell radius, so the comb stays a comfortable size on tablets.
  static const _maxCell = 17.0;

  /// The largest comb that fits [width].
  factory _Comb.fit(double width) =>
      _Comb(math.min(_maxCell, width / (math.sqrt(3) * (2 * rings + 1))));

  /// Distance from a cell's centre to its corners.
  final double cell;

  double get _w => math.sqrt(3) * cell;

  Size get size => Size(_w * (2 * rings + 1), cell * (3 * rings + 2));

  Offset get _centre => size.center(Offset.zero);

  late final cells = [
    for (var q = -rings; q <= rings; q++)
      for (
        var r = math.max(-rings, -q - rings);
        r <= math.min(rings, -q + rings);
        r++
      )
        (q, r),
  ];

  Offset centreOf((int, int) c) =>
      _centre + Offset(_w * (c.$1 + c.$2 / 2), cell * 1.5 * c.$2);

  static int ringOf((int, int) c) =>
      (c.$1.abs() + c.$2.abs() + (c.$1 + c.$2).abs()) ~/ 2;

  /// A cell's colour at brightness [value]: hue from its direction,
  /// vividness from its distance from the centre.
  HSVColor colourOf((int, int) c, double value) {
    final o = centreOf(c) - _centre;
    final ring = ringOf(c);
    final hue = ring == 0
        ? 0.0
        : (math.atan2(o.dy, o.dx) * 180 / math.pi + 360 + 90) % 360;
    return HSVColor.fromAHSV(1, hue, ring / rings, value);
  }

  /// The cell under [p], or null outside the comb.
  (int, int)? cellAt(Offset p) {
    final o = p - _centre;
    final r = o.dy / (cell * 1.5);
    final q = o.dx / _w - r / 2;
    // Round in cube coordinates (q, r, s) to the nearest whole cell.
    final s = -q - r;
    var rq = q.round(), rr = r.round();
    final rs = s.round();
    final dq = (rq - q).abs(), dr = (rr - r).abs(), ds = (rs - s).abs();
    if (dq > dr && dq > ds) {
      rq = -rr - rs;
    } else if (dr > ds) {
      rr = -rq - rs;
    }
    final c = (rq, rr);
    return ringOf(c) <= rings ? c : null;
  }

  /// The cell closest in colour to [c] (ignoring brightness), to mark the
  /// colour in use; none for greys picked from the grey row.
  (int, int)? nearest(HSVColor c) {
    (int, int)? best;
    var bestD = double.infinity;
    for (final cell in cells) {
      final k = colourOf(cell, 1);
      final dh = ((k.hue - c.hue + 540) % 360 - 180).abs() / 180;
      final d =
          math.pow(k.saturation - c.saturation, 2) +
          math.pow(dh * math.min(k.saturation, c.saturation), 2);
      if (d < bestD) {
        bestD = d.toDouble();
        best = cell;
      }
    }
    return best;
  }
}

/// Draws the comb's cells at a brightness, ringing the selected one.
class _CombPainter extends CustomPainter {
  _CombPainter(this.comb, this.value, this.selected, {required this.ring});

  final _Comb comb;
  final double value;
  final (int, int)? selected;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in comb.cells) {
      canvas.drawPath(
        _hexagon(comb.centreOf(c), comb.cell - 0.8),
        Paint()..color = comb.colourOf(c, value).toColor(),
      );
    }
    if (selected case final s?) {
      canvas.drawPath(
        _hexagon(comb.centreOf(s), comb.cell + 1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = ring,
      );
    }
  }

  @override
  bool shouldRepaint(_CombPainter old) =>
      old.value != value ||
      old.selected != selected ||
      old.comb.cell != comb.cell ||
      old.ring != ring;
}

/// A pointy-topped hexagon around [c].
Path _hexagon(Offset c, double radius) {
  final path = Path();
  for (var i = 0; i < 6; i++) {
    final a = math.pi / 180 * (60 * i - 90);
    final p = c + Offset(math.cos(a), math.sin(a)) * radius;
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// A row of greys from white to black. [value] marks the grey in use, if
/// the colour is one.
class _Greys extends StatelessWidget {
  const _Greys({required this.value, required this.ring, required this.onPick});

  final double? value;
  final Color ring;
  final ValueChanged<double> onPick;

  static const _steps = 11;

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: [
        for (var i = 0; i < _steps; i++)
          () {
            final grey = 1 - i / (_steps - 1);
            final on = v != null && (v - grey).abs() < 0.05;
            return Semantics(
              button: true,
              selected: on,
              child: GestureDetector(
                onTap: () => onPick(grey),
                child: CustomPaint(
                  size: const Size(26, 28),
                  painter: _GreyCell(
                    HSVColor.fromAHSV(1, 0, 0, grey).toColor(),
                    on ? ring : null,
                  ),
                ),
              ),
            );
          }(),
      ],
    );
  }
}

class _GreyCell extends CustomPainter {
  _GreyCell(this.color, this.ring);

  final Color color;
  final Color? ring;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.height / 2 - 2;
    canvas.drawPath(_hexagon(c, r), Paint()..color = color);
    // A faint edge, so white shows on a light card.
    canvas.drawPath(
      _hexagon(c, r),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = const Color(0x33000000),
    );
    if (ring case final k?) {
      canvas.drawPath(
        _hexagon(c, r + 1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = k,
      );
    }
  }

  @override
  bool shouldRepaint(_GreyCell old) => old.color != color || old.ring != ring;
}
