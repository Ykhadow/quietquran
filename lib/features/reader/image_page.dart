import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/image_editions.dart';
import '../../data/page_images.dart';
import '../../l10n/l10n.dart';

/// A printed Mushaf page (Madani SVG or IndoPak scan), fetched on first view
/// and cached on disk afterwards.
class ImagePage extends ConsumerStatefulWidget {
  const ImagePage({
    super.key,
    required this.edition,
    required this.page,
    this.zoomed = false,
  });

  final ImageEdition edition;
  final int page;

  /// Zoomed in: decode the scan at full size for detail. Otherwise it is
  /// decoded at the size it's shown, which takes a fraction of the memory.
  final bool zoomed;

  @override
  ConsumerState<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends ConsumerState<ImagePage> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ImagePage old) {
    super.didUpdateWidget(old);
    if (old.page != widget.page || old.edition.id != widget.edition.id) _load();
  }

  void _load() {
    _bytes = ref
        .read(pageImageStoreProvider.notifier)
        .load(widget.edition, widget.page);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens;
    final dark = colors.dark;
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snap) {
        if (snap.hasError) {
          final offline =
              snap.error is SocketException ||
              '${snap.error}'.contains('SocketException') ||
              '${snap.error}'.contains('Failed host lookup');
          final l = context.l10n;
          return _PageState(
            icon: offline ? LucideIcons.wifiOff : LucideIcons.triangleAlert,
            title: offline ? l.offline : l.pageFailed,
            detail: offline
                ? l.offlineDetail(widget.page)
                : l.failedDetail(widget.page),
            action: FilledButton(
              onPressed: () => setState(_load),
              child: Text(l.tryAgain),
            ),
          );
        }
        if (!snap.hasData) {
          return _PageState(
            icon: null,
            title: context.l10n.pageN(widget.page),
            detail: context.l10n.loadingPage,
            action: SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        final ratio = MediaQuery.devicePixelRatioOf(context);
        final followTheme = ref.watch(
          settingsProvider.select((s) => s.printedFollowTheme),
        );
        final image = LayoutBuilder(
          builder: (context, box) => PageImageView(
            bytes: snap.data!,
            edition: widget.edition,
            colors: colors,
            dark: dark,
            decodeWidth: widget.zoomed || !box.hasBoundedWidth
                ? null
                : (box.maxWidth * ratio).round(),
            followTheme: followTheme,
          ),
        );
        // Fill the page's space and scale to fit (centred, keeping its
        // shape). Loose constraints would leave a vector page at its small
        // natural size (345 x 550) on tablets and desktop. Zoomed by the
        // reader (see ZoomablePage).
        return SizedBox.expand(child: image);
      },
    );
  }
}

/// Draws a page image's bytes, adapted to the theme.
///
/// In dark mode a plain (black-and-white) print is remapped by brightness:
/// ink becomes the theme's ink and paper becomes the theme's paper, so the page
/// reads light-on-dark. This matters most for sets drawn on a transparent
/// background, whose black text would otherwise vanish into the dark page.
/// Colour-coded tajweed prints are only dimmed, so their colours keep their
/// meaning.
class PageImageView extends StatelessWidget {
  const PageImageView({
    super.key,
    required this.bytes,
    required this.edition,
    required this.colors,
    required this.dark,
    this.fit = BoxFit.contain,
    this.decodeWidth,
    this.followTheme = true,
  });

  /// Take the palette's paper and ink colours; otherwise show the page exactly
  /// as scanned, black on a white page.
  final bool followTheme;

  final BoxFit fit;

  /// Decode a scan at most this many pixels wide (never larger than it is),
  /// or at full size if null. A 1280 x 2048 scan takes about 10 MB decoded.
  final int? decodeWidth;

  final Uint8List bytes;
  final ImageEdition edition;
  final Tokens colors;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final svg = edition.format == ImageFormat.svg;
    if (!followTheme) {
      // As scanned. Many scans have transparent paper, so they get a white
      // page of exactly their own size (the FittedBox scales page and scan
      // together), not a white screen.
      return FittedBox(
        fit: fit,
        child: ColoredBox(
          color: Colors.white,
          child: svg
              ? SvgPicture.memory(
                  bytes,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                )
              : Image(
                  image: ResizeImage.resizeIfNeeded(
                    decodeWidth,
                    null,
                    MemoryImage(bytes),
                  ),
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                ),
        ),
      );
    }
    if (svg) {
      // From the bytes directly: no text decoding on every build.
      return SvgPicture.memory(
        bytes,
        colorFilter: ColorFilter.mode(colors.ink, BlendMode.srcIn),
        fit: fit,
      );
    }
    final image = Image(
      image: ResizeImage.resizeIfNeeded(decodeWidth, null, MemoryImage(bytes)),
      fit: fit,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
    if (edition.colourCoded) {
      // Tajweed colours carry meaning: only dimmed at night.
      if (!dark) return image;
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0xFFB8B8B8),
          BlendMode.modulate,
        ),
        child: image,
      );
    }
    // Plain prints take the palette's ink and paper, in every theme.
    return ColorFiltered(
      colorFilter: brightnessMap(ink: colors.ink, paper: colors.bg),
      child: image,
    );
  }

  /// Maps each pixel's luminance onto the gradient from [ink] (black) to
  /// [paper] (white), keeping alpha: out = ink + (paper - ink) * luminance.
  static ColorFilter brightnessMap({required Color ink, required Color paper}) {
    const w = [0.2126, 0.7152, 0.0722]; // Rec. 709 luminance weights
    List<double> row(double i, double p) => [
      for (final k in w) (p - i) * k,
      0,
      i * 255,
    ];
    return ColorFilter.matrix([
      ...row(ink.r, paper.r),
      ...row(ink.g, paper.g),
      ...row(ink.b, paper.b),
      0,
      0,
      0,
      1,
      0,
    ]);
  }
}

/// A calm placeholder for a page that is loading or could not be loaded.
class _PageState extends StatelessWidget {
  const _PageState({
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
  });

  final IconData? icon;
  final String title;
  final String detail;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 28, color: t.mut),
              const SizedBox(height: 14),
            ],
            Text(
              title,
              style: AppType.title(t.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: AppType.caption(t.mut).copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            action,
          ],
        ),
      ),
    );
  }
}
