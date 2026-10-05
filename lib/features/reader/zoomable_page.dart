import 'package:flutter/material.dart';

/// A reader page that can be pinched to zoom (up to 4x) and, once zoomed,
/// dragged around. [builder] learns whether the page is zoomed, so a text page
/// can switch from its prepared picture to live text, which stays sharp.
///
/// The reader stops page turns while a page is zoomed ([onZoomChanged]), so a
/// drag moves around the page instead of turning it, and resets every page's
/// zoom through [reset] when the reader moves to another page.
class ZoomablePage extends StatefulWidget {
  const ZoomablePage({
    super.key,
    required this.builder,
    required this.reset,
    this.onZoomChanged,
  });

  final Widget Function(BuildContext context, bool zoomed) builder;
  final Listenable reset;
  final ValueChanged<bool>? onZoomChanged;

  @override
  State<ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<ZoomablePage> {
  final _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
    widget.reset.addListener(_reset);
  }

  @override
  void didUpdateWidget(ZoomablePage old) {
    super.didUpdateWidget(old);
    if (old.reset != widget.reset) {
      old.reset.removeListener(_reset);
      widget.reset.addListener(_reset);
    }
  }

  @override
  void dispose() {
    widget.reset.removeListener(_reset);
    _transform.dispose();
    super.dispose();
  }

  void _reset() => _transform.value = Matrix4.identity();

  void _onTransform() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    setState(() => _zoomed = zoomed);
    widget.onZoomChanged?.call(zoomed);
  }

  @override
  Widget build(BuildContext context) => InteractiveViewer(
    transformationController: _transform,
    maxScale: 4,
    // Unzoomed, a one-finger drag belongs to the page turn.
    panEnabled: _zoomed,
    child: widget.builder(context, _zoomed),
  );
}
