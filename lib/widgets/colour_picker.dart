import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Pick a colour with one touch on a rainbow: hue from left to right, light
/// at the top to dark at the bottom, and a grey column for whites, greys and
/// blacks. A vividness slider reaches the soft, muted tones reading palettes
/// often want, and a hex field takes an exact colour.
class ColourPicker extends StatefulWidget {
  const ColourPicker({super.key, required this.color, required this.onChanged});

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<ColourPicker> createState() => _ColourPickerState();
}

class _ColourPickerState extends State<ColourPicker> {
  late HSLColor _hsl = HSLColor.fromColor(widget.color);

  /// Vividness of the rainbow (HSL saturation). Near-grey colours (such as
  /// dark reading backgrounds) start it colourful, so it shows a rainbow.
  late double _vivid = _startVivid(_hsl.saturation);

  static double _startVivid(double s) => s < 0.25 ? 0.7 : _clampVivid(s);

  static double _clampVivid(double v) => v.clamp(0.05, 1.0);

  final _hex = TextEditingController();
  final _hexFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _hex.text = _hexOf(widget.color);
    _hexFocus.addListener(() {
      // Leaving the field shows the colour actually in use.
      if (!_hexFocus.hasFocus) _hex.text = _hexOf(_hsl.toColor());
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
    // editing), keeping our hue for greys, where hue is undefined.
    if (widget.color.toARGB32() != _hsl.toColor().toARGB32()) {
      _adopt(widget.color);
    }
  }

  void _adopt(Color c) {
    final next = HSLColor.fromColor(c);
    _hsl = next.saturation == 0 ? next.withHue(_hsl.hue) : next;
    _vivid = _startVivid(next.saturation);
    if (!_hexFocus.hasFocus) _hex.text = _hexOf(c);
  }

  void _set(HSLColor v) {
    setState(() {
      _hsl = v;
      if (!_hexFocus.hasFocus) _hex.text = _hexOf(v.toColor());
    });
    widget.onChanged(v.toColor());
  }

  static String _hexOf(Color c) =>
      (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    const height = 200.0;
    const greyWidth = 30.0;
    const gap = 8.0;
    final grey = _hsl.saturation == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final rainbowWidth = box.maxWidth - greyWidth - gap;
            double lightness(double dy) => 1 - (dy / height).clamp(0.0, 1.0);
            void pickRainbow(Offset p) => _set(
              HSLColor.fromAHSL(
                1,
                (p.dx / rainbowWidth).clamp(0.0, 1.0) * 359.9,
                _vivid,
                lightness(p.dy),
              ),
            );
            void pickGrey(Offset p) =>
                _set(_hsl.withSaturation(0).withLightness(lightness(p.dy)));

            final knobX = grey
                ? rainbowWidth + gap + greyWidth / 2
                : _hsl.hue / 360 * rainbowWidth;
            final knobY = (1 - _hsl.lightness) * height;

            return SizedBox(
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: rainbowWidth,
                    height: height,
                    child: GestureDetector(
                      onPanDown: (d) => pickRainbow(d.localPosition),
                      onPanUpdate: (d) => pickRainbow(d.localPosition),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        // Its own layer: dragging the knob doesn't
                        // repaint the gradients.
                        child: RepaintBoundary(
                          child: CustomPaint(painter: _Rainbow(_vivid)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    width: greyWidth,
                    height: height,
                    child: GestureDetector(
                      onPanDown: (d) => pickGrey(d.localPosition),
                      onPanUpdate: (d) => pickGrey(d.localPosition),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: t.line),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.black],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: knobX - 12,
                    top: knobY - 12,
                    child: IgnorePointer(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hsl.toColor(),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Color(0x66000000), blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(l.colourVividness, style: AppType.caption(t.mut)),
            Expanded(
              child: Slider(
                value: _vivid,
                min: 0.05,
                max: 1,
                onChanged: (v) {
                  _vivid = v;
                  // Soften or brighten the colour in use, unless it's a grey.
                  _set(grey ? _hsl : _hsl.withSaturation(v));
                },
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

/// Hues across at the chosen vividness, fading to white at the top and black
/// at the bottom (HSL lightness 1 to 0), matching how picks are read.
class _Rainbow extends CustomPainter {
  _Rainbow(this.saturation);

  final double saturation;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            for (var h = 0; h <= 360; h += 30)
              HSLColor.fromAHSL(1, h % 360 * 1.0, saturation, 0.5).toColor(),
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Color(0x00FFFFFF),
            Color(0x00000000),
            Colors.black,
          ],
          stops: [0, 0.5, 0.5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_Rainbow old) => old.saturation != saturation;
}
