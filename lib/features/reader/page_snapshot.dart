import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../data/models.dart';
import 'quran_line.dart';

/// Finished pictures of Mushaf pages.
///
/// A page is about 150 shaped words. Drawing them on every frame of a
/// page-turn animation is what makes swipes stutter on slower phones. Instead,
/// pages near the reader are drawn once, offscreen, in idle moments; a swipe
/// then only slides pictures.
class PageSnapshots {
  PageSnapshots._();

  /// Room for the current page (or spread) plus two either side, with slack:
  /// as many as fit [_budgetBytes], but never fewer than [_minCapacity],
  /// which must exceed what the reader prepares, or pictures would evict each
  /// other in a loop.
  static const _maxCapacity = 8;
  static const _minCapacity = 6;
  static const _budgetBytes = 48 << 20;
  static int _capacity = _maxCapacity;

  /// Stale requests (pages flicked past) are dropped beyond this many.
  static const _maxQueued = 6;
  // Insertion-ordered, so the first key is the least recently used.
  static final _images = <Object, ui.Image>{};

  /// Where each Quran word sits on a page, by the same keys as the pictures.
  static final _placements = <Object, List<(Word, Rect)>>{};

  static List<(Word, Rect)>? placements(Object key) => _placements[key];

  static void setPlacements(Object key, List<(Word, Rect)> value) {
    _placements[key] = value;
    if (_placements.length > 3 * _capacity) {
      _placements.remove(_placements.keys.first);
    }
  }

  static final _queue =
      Queue<
        (Object, Widget Function(), Size, double, ThemeData, TextDirection)
      >();
  static final _queued = <Object>{};
  static bool _scheduled = false;

  /// Bumped when a new picture is ready, so live pages can swap to it.
  static final ready = ValueNotifier<int>(0);

  /// Tests switch this off: queued idle tasks would outlive a test.
  @visibleForTesting
  static bool enabled = true;

  /// Whether a picture is ready for [key] (without counting as a use).
  static bool has(Object key) => _images.containsKey(key);

  static ui.Image? get(Object key) {
    final image = _images.remove(key);
    if (image != null) _images[key] = image; // most recently used
    return image;
  }

  /// Draws [build]'s page offscreen at [size] when the app is next idle.
  static void prepare({
    required Object key,
    required Widget Function() build,
    required Size size,
    required double pixelRatio,
    required ThemeData theme,
    TextDirection direction = TextDirection.ltr,
  }) {
    if (!enabled || _images.containsKey(key) || !_queued.add(key)) return;
    _queue.add((key, build, size, pixelRatio, theme, direction));
    // Quick flicks queue pages that are already behind the reader; keep only
    // the newest requests.
    while (_queue.length > _maxQueued) {
      _queued.remove(_queue.removeFirst().$1);
    }
    final bytes = size.width * size.height * pixelRatio * pixelRatio * 4;
    _capacity = (_budgetBytes / bytes).floor().clamp(
      _minCapacity,
      _maxCapacity,
    );
    _schedule();
  }

  /// Frees every picture (they are drawn again when next needed). For low
  /// memory.
  static void clear() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
    _placements.clear();
    _queue.clear();
    _queued.clear();
  }

  static void _schedule() {
    if (_scheduled || _queue.isEmpty) return;
    _scheduled = true;
    SchedulerBinding.instance.scheduleTask(() {
      _scheduled = false;
      // Emptied meanwhile (clear(), on low memory): nothing to draw.
      if (_queue.isEmpty) return;
      final (key, build, size, ratio, theme, direction) = _queue.removeFirst();
      _queued.remove(key);
      if (!_images.containsKey(key)) {
        final (image, placed) = _render(
          Theme(
            data: theme,
            child: Directionality(textDirection: direction, child: build()),
          ),
          size,
          ratio,
        );
        _images[key] = image;
        setPlacements(key, placed);
        while (_images.length > _capacity) {
          _images.remove(_images.keys.first)!.dispose();
        }
        ready.value++;
      }
      _schedule();
    }, Priority.idle);
  }

  static final _focus = FocusManager();

  /// Builds, lays out and paints [widget] in a private render tree.
  static (ui.Image, List<(Word, Rect)>) _render(
    Widget widget,
    Size size,
    double ratio,
  ) {
    final boundary = RenderRepaintBoundary();
    final view = ui.PlatformDispatcher.instance.implicitView!;
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(child: boundary),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        physicalConstraints: BoxConstraints.tight(size * ratio),
        devicePixelRatio: ratio,
      ),
    );
    final pipeline = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();
    final owner = BuildOwner(focusManager: _focus);
    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: ratio),
        child: widget,
      ),
    ).attachToRenderTree(owner);
    owner
      ..buildScope(root)
      ..finalizeTree();
    pipeline
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
    final image = boundary.toImageSync(pixelRatio: ratio);
    final placed = collectPlacements(boundary);
    // The private tree is unreachable once this returns and is collected;
    // tearing it down explicitly can stall inside a running frame.
    return (image, placed);
  }
}

/// Shows the prepared picture of a page when there is one, otherwise the live
/// page (and asks for a picture to be prepared for next time).
class SnapshotPage extends StatelessWidget {
  const SnapshotPage({
    super.key,
    required this.snapshotKey,
    required this.page,
    required this.label,
    this.onAyahLongPress,
    this.highlight,
    this.live = false,
  });

  /// Show the page as live text, never as its picture: while zoomed, where a
  /// picture would blur and live text stays sharp.
  final bool live;

  /// Identifies what the page shows (page, edition, typeface, colours).
  final Object snapshotKey;
  final Widget Function() page;

  /// What a screen reader says for the page while it is a picture.
  final String label;

  /// Called with the ayah under a long press.
  final void Function(int surah, int ayah)? onAyahLongPress;

  /// An ayah to highlight (while its sheet is open).
  final (int, int)? highlight;

  static Size? _lastSize;
  static double _lastRatio = 1;
  static ThemeData? _lastTheme;
  static TextDirection _lastDirection = TextDirection.ltr;

  /// Prepares a page that is not on screen yet (e.g. two pages ahead), at the
  /// size pages were last shown.
  static void prefetch(Object snapshotKey, Widget Function() build) {
    final size = _lastSize, theme = _lastTheme;
    if (size == null || theme == null) return;
    PageSnapshots.prepare(
      key: (snapshotKey, size, _lastRatio),
      build: build,
      size: size,
      pixelRatio: _lastRatio,
      theme: theme,
      direction: _lastDirection,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        _lastSize = size;
        _lastRatio = ratio;
        _lastTheme = theme;
        _lastDirection = direction;
        final key = (snapshotKey, size, ratio);
        return _WhenReady(
          snapshotKey: key,
          builder: (context) {
            final image = live ? null : PageSnapshots.get(key);
            if (image != null) {
              return _interactive(
                context,
                key,
                Semantics(
                  label: label,
                  textDirection: TextDirection.rtl,
                  child: RawImage(image: image, scale: ratio, fit: BoxFit.fill),
                ),
              );
            }
            if (live) return _interactive(context, key, page());
            PageSnapshots.prepare(
              key: key,
              build: page,
              size: size,
              pixelRatio: ratio,
              theme: theme,
              direction: direction,
            );
            return _interactive(context, key, page());
          },
        );
      },
    );
  }

  /// Adds long-press lookup and the highlight over [child].
  Widget _interactive(BuildContext context, Object key, Widget child) {
    final placed = PageSnapshots.placements(key);
    final hl = highlight;
    return Builder(
      builder: (context) => GestureDetector(
        onLongPressStart: onAyahLongPress == null
            ? null
            : (d) {
                // A live page: read its layout now.
                var words = PageSnapshots.placements(key);
                if (words == null) {
                  final box = context.findRenderObject();
                  if (box == null) return;
                  words = collectPlacements(box);
                  PageSnapshots.setPlacements(key, words);
                }
                final hit = wordAt(words, d.localPosition);
                if (hit != null) onAyahLongPress!(hit.surah, hit.ayah);
              },
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (hl != null && placed != null)
              IgnorePointer(
                child: CustomPaint(
                  painter: _Highlight([
                    for (final (w, r) in placed)
                      if (w.surah == hl.$1 && w.ayah == hl.$2) r,
                  ], Theme.of(context).colorScheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Soft accent marks behind the words of the selected ayah.
class _Highlight extends CustomPainter {
  _Highlight(this.rects, this.color);

  final List<Rect> rects;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.18);
    for (final r in rects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(6)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Highlight old) =>
      old.rects != rects || old.color != color;
}

/// Rebuilds [builder] when the picture for [snapshotKey] becomes ready (or
/// goes), not whenever any page's picture does: other pictures being prepared
/// must not rebuild pages still shown as live text.
class _WhenReady extends StatefulWidget {
  const _WhenReady({required this.snapshotKey, required this.builder});

  final Object snapshotKey;
  final WidgetBuilder builder;

  @override
  State<_WhenReady> createState() => _WhenReadyState();
}

class _WhenReadyState extends State<_WhenReady> {
  // Set in initState, not lazily: a lazy read in [_changed] would see the
  // picture already ready and miss the change.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ready = PageSnapshots.has(widget.snapshotKey);
    PageSnapshots.ready.addListener(_changed);
  }

  @override
  void didUpdateWidget(_WhenReady old) {
    super.didUpdateWidget(old);
    _ready = PageSnapshots.has(widget.snapshotKey);
  }

  @override
  void dispose() {
    PageSnapshots.ready.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final ready = PageSnapshots.has(widget.snapshotKey);
    if (ready != _ready) setState(() => _ready = ready);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
