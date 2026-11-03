import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'page_info.dart';

/// A readout of how long frames take, for finding slowness on a phone.
///
/// Only on the web version, and only when its address has `?fps`
/// (quietquran.com/reader/?fps). Each second it shows, and prints to the
/// console, the frames drawn and the middle, slow (90th percentile) and
/// slowest times to build and to draw them.
class FrameStats extends StatefulWidget {
  const FrameStats({super.key, required this.child});

  final Widget child;

  static final bool enabled =
      kIsWeb && Uri.base.queryParameters.containsKey('fps');

  @override
  State<FrameStats> createState() => _FrameStatsState();
}

class _FrameStatsState extends State<FrameStats> {
  final _build = <double>[];
  final _raster = <double>[];
  Timer? _timer;
  String _text = '';

  @override
  void initState() {
    super.initState();
    if (!FrameStats.enabled) return;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _report());
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (FrameStats.enabled) {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    }
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _build.add(t.buildDuration.inMicroseconds / 1000);
      _raster.add(t.rasterDuration.inMicroseconds / 1000);
    }
  }

  static String _summary(List<double> ms) {
    if (ms.isEmpty) return '-';
    final s = [...ms]..sort();
    String f(double v) => v.toStringAsFixed(1);
    return '${f(s[s.length ~/ 2])} / ${f(s[(s.length * 0.9).floor()])} '
        '/ ${f(s.last)}';
  }

  void _report() {
    if (_build.isEmpty) return;
    int over(double ms) => [
      for (var i = 0; i < _build.length; i++)
        if (_build[i] + _raster[i] > ms) i,
    ].length;
    final text =
        '${kIsWasm ? 'skwasm' : 'canvaskit'}, ${pageInfo()}\n'
        '${_build.length} frames; over 8.3ms ${over(8.3)}, '
        'over 16.7ms ${over(16.7)}\n'
        'build  ${_summary(_build)}\n'
        'draw   ${_summary(_raster)}';
    debugPrint('[fps] ${text.replaceAll('\n', ' | ')}');
    _build.clear();
    _raster.clear();
    setState(() => _text = text);
  }

  @override
  Widget build(BuildContext context) {
    if (!FrameStats.enabled) return widget.child;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        Positioned(
          left: 8,
          top: 40,
          child: IgnorePointer(
            child: ColoredBox(
              color: const Color(0xCC000000),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  _text,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 12,
                    fontFamily: 'monospace',
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
