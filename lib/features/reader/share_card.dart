import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/quran_db.dart';
import '../../l10n/l10n.dart';
import '../../widgets/night.dart';
import 'reflow_page.dart';
import 'translation_text.dart';

/// The app's name as it appears on shared ayahs. A name, so it stays the
/// same in every language.
const appName = 'Quiet Quran';

/// The shape of a shared image: a square post, or a tall story.
enum CardFormat { post, story }

/// One ayah as an image in the app's own design: the surah and reference
/// above, the ayah as the reader sees it (lines justified, the last to the
/// right, as in a Mushaf), its translation (credited), and a small mark of
/// the app below.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.words,
    required this.typeface,
    required this.quranSize,
    required this.surah,
    required this.reference,
    required this.brand,
    this.translation,
    this.translated,
    this.logo,
    this.fill = false,
  });

  final List<Word> words;
  final QuranTypeface typeface;
  final double quranSize;
  final Surah surah;
  final String reference;
  final String brand;
  final Translation? translation;
  final String? translated;
  final ui.Picture? logo;

  /// Fill the height given (centring the ayah), rather than taking only the
  /// height the content needs.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final quran = TextStyle(
      fontFamily: typeface.fontFamily,
      fontSize: quranSize,
      height: typeface.script == QuranScript.indopak ? 2.1 : 1.9,
      color: t.ink,
    );
    final tr = translation;
    final text = translated;
    TextStyle sans(double size, Color c) => TextStyle(
      fontFamily: AppType.sans,
      fontFamilyFallback: AppType.fallback,
      fontSize: size,
      color: c,
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'سُورَةُ ${surah.nameArabic}',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: AppType.arabicSmall,
            fontSize: 26,
            color: t.acc,
          ),
        ),
        const SizedBox(height: 2),
        Text(reference, textAlign: TextAlign.center, style: sans(15, t.mut)),
        const SizedBox(height: 20),
        QuranParagraph(
          units: QuranParagraph.unitsOf(words),
          typeface: typeface,
          style: quran,
          markerStyle: quran.copyWith(color: t.acc),
        ),
        if (tr != null && text != null) ...[
          const SizedBox(height: 18),
          TranslationText(
            translation: tr,
            text: text,
            fontSize: (quranSize * 0.52).clamp(14.0, 19.0),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${tr.translator}',
            textDirection: tr.rtl ? TextDirection.rtl : TextDirection.ltr,
            style: sans(13, t.mut),
          ),
        ],
      ],
    );
    final mark = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (logo != null) ...[
          SizedBox.square(
            dimension: 30,
            child: CustomPaint(painter: _Logo(logo!)),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          brand,
          style: TextStyle(
            fontFamily: AppType.serif,
            fontSize: 16,
            color: t.mut,
          ),
        ),
      ],
    );
    return ColoredBox(
      color: t.bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(44, 44, 44, 28),
        child: fill
            ? Column(
                children: [
                  Expanded(child: Center(child: content)),
                  const SizedBox(height: 20),
                  mark,
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [content, const SizedBox(height: 28), mark],
              ),
      ),
    );
  }
}

/// The app's logo, drawn from its SVG (loaded ahead, since cards are drawn
/// in one go and can't wait for it).
class _Logo extends CustomPainter {
  _Logo(this.picture);

  final ui.Picture picture;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1024);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Logo old) => old.picture != picture;
}

/// Draws share cards offscreen.
abstract final class ShareCards {
  /// Logical width; images are drawn at twice this (1080 pixels across).
  static const width = 540.0;
  static const ratio = 2.0;

  static double heightOf(CardFormat f) => switch (f) {
    CardFormat.post => 540,
    CardFormat.story => 960,
  };

  static const _sizes = <double>[
    52,
    46,
    40,
    36,
    32,
    29,
    26,
    24,
    22,
    20,
    18,
    16,
  ];

  /// The card for [card] (built at a given Quran text size) in [format]:
  /// the largest text that fits the format's height, or, for the longest
  /// ayahs, a taller image at the smallest size: an ayah is never cut.
  static ui.Image draw({
    required ShareCard Function(double quranSize, {bool fill}) card,
    required CardFormat format,
    required ThemeData theme,
  }) {
    final target = heightOf(format);
    var size = _sizes.last;
    var height = target;
    for (final s in _sizes) {
      final h = _layout(card(s), theme, null).$1;
      if (h <= target) {
        size = s;
        break;
      }
      if (s == _sizes.last) height = h;
    }
    return _layout(card(size, fill: true), theme, height).$2!;
  }

  /// Lays [widget] out [width] wide: at [height], painted, or at the height
  /// it needs, only measured.
  static (double, ui.Image?) _layout(
    Widget widget,
    ThemeData theme,
    double? height,
  ) {
    final boundary = RenderRepaintBoundary();
    final view = ui.PlatformDispatcher.instance.implicitView!;
    final constraints = height == null
        ? const BoxConstraints(
            minWidth: width,
            maxWidth: width,
            maxHeight: 8000,
          )
        : BoxConstraints.tight(Size(width, height));
    final renderView = RenderView(
      view: view,
      child: boundary,
      configuration: ViewConfiguration(
        logicalConstraints: constraints,
        physicalConstraints: constraints * ratio,
        devicePixelRatio: ratio,
      ),
    );
    final pipeline = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();
    final owner = BuildOwner(focusManager: FocusManager());
    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(width, 8000),
          devicePixelRatio: ratio,
        ),
        child: Theme(
          data: theme,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: widget,
          ),
        ),
      ),
    ).attachToRenderTree(owner);
    owner
      ..buildScope(root)
      ..finalizeTree();
    pipeline
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
    final h = boundary.size.height;
    if (height == null) return (h, null);
    return (h, boundary.toImageSync(pixelRatio: ratio));
  }
}

/// Share one ayah: a preview of its card, a choice of post or story, and
/// sharing it as an image or as text.
Future<void> showShareSheet(BuildContext context, int surah, int ayah) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ShareSheet(surah: surah, ayah: ayah),
    );

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  CardFormat _format = CardFormat.post;
  ui.Image? _image;
  ui.Picture? _logo;
  bool _drawn = false;

  /// The translation on this card ('none' for the ayah alone): starts as
  /// the reader's own and changes for this share only.
  String? _translation;

  static bool get _canShareFiles => kIsWeb || !Platform.isLinux;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_drawn) {
      _drawn = true;
      _translation =
          ref.read(settingsProvider).translationFor(context.l10n.localeName) ??
          'none';
      _loadLogo();
    }
  }

  Future<void> _loadLogo() async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    try {
      final info = await vg.loadPicture(
        SvgAssetLoader(
          dark ? 'assets/brand/mark_night.svg' : 'assets/brand/mark_day.svg',
        ),
        null,
      );
      _logo = info.picture;
    } on Object {
      // Without the logo the card still carries the app's name.
    }
    if (mounted) _draw();
  }

  @override
  void dispose() {
    _image?.dispose();
    _logo?.dispose();
    super.dispose();
  }

  /// The surah's name and the ayah's number, under the Arabic name at the
  /// top of the card (with Arabic surah names, the number alone).
  String _reference(QuranDb db) {
    final numbers = '${widget.surah}:${widget.ayah}';
    if (context.arabicNames) return numbers;
    return '${db.surah(widget.surah).nameSimple} $numbers';
  }

  void _draw() {
    final db = ref.read(quranDbProvider);
    final typeface = ref.read(settingsProvider).typeface;
    final translation = db.translation(_translation);
    final translated = translation == null
        ? null
        : db.translationText(translation.id, widget.surah, widget.ayah);
    final words = db.ayahTail(widget.surah, widget.ayah, typeface, count: 1000);
    final image = ShareCards.draw(
      card: (size, {fill = false}) => ShareCard(
        words: words,
        typeface: typeface,
        quranSize: size,
        surah: db.surah(widget.surah),
        reference: _reference(db),
        brand: appName,
        translation: translated == null ? null : translation,
        translated: translated,
        logo: _logo,
        fill: fill,
      ),
      format: _format,
      theme: Theme.of(context),
    );
    setState(() {
      _image?.dispose();
      _image = image;
    });
  }

  Rect? _origin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _shareImage() async {
    final image = _image;
    if (image == null) return;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final origin = _origin();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    final name = 'quran_${widget.surah}_${widget.ayah}.png';
    if (!_canShareFiles) {
      // Linux has no share menu for files: save it instead.
      final dir =
          await getDownloadsDirectory() ?? await getTemporaryDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes(data.buffer.asUint8List());
      messenger?.showSnackBar(SnackBar(content: Text(l.imageSaved(file.path))));
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(data.buffer.asUint8List());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<void> _shareText() async {
    final db = ref.read(quranDbProvider);
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final origin = _origin();
    final text = shareText(
      db: db,
      surah: widget.surah,
      ayah: widget.ayah,
      translationId: _translation,
      reference:
          '${context.surahName(db.surah(widget.surah))} '
          '${widget.surah}:${widget.ayah}',
      brand: appName,
    );
    if (!_canShareFiles) {
      await Clipboard.setData(ClipboardData(text: text));
      messenger?.showSnackBar(
        SnackBar(content: Text(l.copied('${widget.surah}:${widget.ayah}'))),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final image = _image;
    final screen = MediaQuery.sizeOf(context);
    final db = ref.watch(quranDbProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.share, style: AppType.titleLg(t.ink)),
            const SizedBox(height: 14),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screen.height * 0.5,
                  maxWidth: 420,
                ),
                child: image == null
                    ? const AspectRatio(
                        aspectRatio: 1,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : AspectRatio(
                        aspectRatio: image.width / image.height,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: t.line2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: RawImage(image: image, fit: BoxFit.contain),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Segmented<CardFormat>(
              value: _format,
              onChanged: (f) {
                _format = f;
                _draw();
              },
              options: [
                (CardFormat.post, l.cardPost),
                (CardFormat.story, l.cardStory),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(l.translation, style: AppType.caption(t.mut)),
                const SizedBox(width: 12),
                Expanded(
                  child: Segmented<String>(
                    value: _translation ?? 'none',
                    onChanged: (id) {
                      _translation = id;
                      _draw();
                    },
                    options: [
                      ('none', l.translationNone),
                      for (final tr in db.translations)
                        (tr.id, l.translationLanguage(tr)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: image == null ? null : _shareImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(_canShareFiles ? l.shareImage : l.saveImage),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _shareText,
              icon: const Icon(Icons.notes),
              label: Text(_canShareFiles ? l.shareText : l.copyText),
            ),
          ],
        ),
      ),
    );
  }
}

/// An ayah as plain text to share: the Quran text in standard Unicode (so
/// it shows in any app), its translation (credited) if there is one, the
/// reference, and the app's name.
String shareText({
  required QuranDb db,
  required int surah,
  required int ayah,
  required String? translationId,
  required String reference,
  required String brand,
}) {
  final arabic = db
      .ayahTail(surah, ayah, QuranTypeface.qpcHafs, count: 1000)
      .where((w) => !w.isAyahEnd)
      .map((w) => w.text)
      .join(' ');
  final translation = db.translation(translationId);
  final translated = translation == null
      ? null
      : db.translationText(translation.id, surah, ayah);
  return [
    arabic,
    if (translation != null && translated != null)
      '$translated\n— ${translation.translator}',
    '$reference · $brand',
  ].join('\n\n');
}
