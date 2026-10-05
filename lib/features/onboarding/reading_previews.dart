import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/image_editions.dart';
import '../../data/quran_db.dart';
import '../../l10n/l10n.dart';
import '../reader/image_page.dart';
import '../reader/reflow_page.dart';

/// Text or printed pages, each shown as its whole page, side by side (as on
/// the website): used by setup and by Settings.
class ReadingModeChoice extends StatelessWidget {
  const ReadingModeChoice({
    super.key,
    required this.script,
    required this.selected,
    required this.onSelect,
    this.maxWidth = 680,
  });

  final QuranScript script;
  final ReadingMode? selected;
  final ValueChanged<ReadingMode> onSelect;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PageChoice(
              selected: selected == ReadingMode.text,
              onTap: () => onSelect(ReadingMode.text),
              title: l.modeText,
              tagline: l.modeTextTagline,
              page: TextPagePreview(script),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: PageChoice(
              selected: selected == ReadingMode.pages,
              onTap: () => onSelect(ReadingMode.pages),
              title: l.modePages,
              tagline: l.modePagesTagline,
              page: PrintedPagePreview(script),
            ),
          ),
        ],
      ),
    );
  }
}

/// The page both previews show: Surah Al-Mulk opens page 562 in the default
/// edition of both scripts, as text and as print.
const _previewPage = 562;

/// A page on its own, like a sheet of paper, as on the website: in the
/// proportions of the site's page cards.
const readingPageAspect = 440 / 630;

/// One way to read, shown as its whole page, with its name below.
class PageChoice extends StatelessWidget {
  const PageChoice({
    super.key,
    required this.selected,
    required this.onTap,
    required this.title,
    required this.tagline,
    required this.page,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String tagline;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: tk.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? scheme.primary : tk.line,
                  width: selected ? 2.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: tk.dark ? 0.4 : 0.1),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: readingPageAspect,
                  child: IgnorePointer(child: page),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? scheme.primary : scheme.outline,
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: t.titleMedium)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              tagline,
              style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page 562 in Easy read, exactly as the reader draws it, scaled to fit.
class TextPagePreview extends ConsumerWidget {
  const TextPagePreview(this.script, {super.key});
  final QuranScript script;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(quranDbProvider);
    final page = db.page(
      script.defaultTextEdition,
      _previewPage,
      QuranTypeface.forScript(script).first,
    );
    // Laid out at a phone's page size, then scaled down to the card.
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 440,
        height: 440 / readingPageAspect,
        child: ReflowPage(
          page: page,
          db: db,
          fontSize: 30,
          juzLabel: context.l10n.runningHeadJuz(page.juz),
        ),
      ),
    );
  }
}

/// The same page from the script's default printed set (bundled, so it
/// shows offline), adapted to the theme as in the reader.
class PrintedPagePreview extends StatefulWidget {
  const PrintedPagePreview(this.script, {super.key});
  final QuranScript script;

  @override
  State<PrintedPagePreview> createState() => _PrintedPagePreviewState();
}

class _PrintedPagePreviewState extends State<PrintedPagePreview> {
  late Future<ByteData> _bytes = _load();

  Future<ByteData> _load() =>
      rootBundle.load('assets/samples/printed_${widget.script.name}.webp');

  @override
  void didUpdateWidget(PrintedPagePreview old) {
    super.didUpdateWidget(old);
    if (old.script != widget.script) _bytes = _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FutureBuilder<ByteData>(
      future: _bytes,
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.all(6),
          child: PageImageView(
            bytes: data.buffer.asUint8List(
              data.offsetInBytes,
              data.lengthInBytes,
            ),
            edition: ImageEdition.byId(widget.script.defaultImageEdition),
            colors: t,
            dark: t.dark,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}
