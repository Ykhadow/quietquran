import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme.dart';
import '../../data/image_editions.dart';
import '../../data/page_images.dart';
import '../../l10n/l10n.dart';

/// Printed pages are downloaded in full before they're shown, so reading
/// never stops for a missing page or a lost connection. Returns true once
/// every page of [edition] is saved: at once if it already is, otherwise
/// after the reader agrees and waits through the download (false if they
/// decline or cancel).
Future<bool> ensurePagesDownloaded(
  BuildContext context,
  WidgetRef ref,
  ImageEdition edition,
) async {
  final store = ref.read(pageImageStoreProvider.notifier);
  final total = store.pageCount(edition);
  if (await store.savedCount(edition) >= total) return true;
  if (!context.mounted) return false;
  final l = context.l10n;
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.printedDownloadTitle),
      content: Text(l.printedDownloadBody(total, edition.approxTotalMb)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.printedDownloadStart),
        ),
      ],
    ),
  );
  if (!(go ?? false) || !context.mounted) return false;
  final done = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _DownloadScreen(edition: edition),
    ),
  );
  return done ?? false;
}

/// The whole screen while a set downloads: how far along, what to do if
/// the connection drops, and a way out. Closes itself when every page is
/// saved.
class _DownloadScreen extends ConsumerStatefulWidget {
  const _DownloadScreen({required this.edition});

  final ImageEdition edition;

  @override
  ConsumerState<_DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends ConsumerState<_DownloadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() =>
      ref.read(pageImageStoreProvider.notifier).downloadAll(widget.edition);

  void _cancel() {
    ref.read(pageImageStoreProvider.notifier).cancel(widget.edition);
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final store = ref.read(pageImageStoreProvider.notifier);
    final total = store.pageCount(widget.edition);
    final status = ref.watch(
      pageImageStoreProvider.select((m) => m[widget.edition.id]!),
    );
    final done = status.cached >= total;
    if (done) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    }
    final stopped = status.error != null && !status.running;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !done) _cancel();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      stopped ? LucideIcons.wifiOff : LucideIcons.download,
                      size: 36,
                      color: t.acc,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      stopped ? l.printedDownloadStopped : l.printedDownloading,
                      textAlign: TextAlign.center,
                      style: AppType.titleLg(t.ink),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.imageTitle(widget.edition),
                      textAlign: TextAlign.center,
                      style: AppType.body(t.mut),
                    ),
                    const SizedBox(height: 28),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: status.cached / total,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.printedDownloadProgress(status.cached, total),
                      textAlign: TextAlign.center,
                      style: AppType.caption(t.mut),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      stopped
                          ? l.printedDownloadStoppedHint
                          : l.printedDownloadKeepOpen,
                      textAlign: TextAlign.center,
                      style: AppType.caption(t.mut),
                    ),
                    const SizedBox(height: 28),
                    if (stopped) ...[
                      FilledButton(onPressed: _start, child: Text(l.tryAgain)),
                      const SizedBox(height: 8),
                    ],
                    TextButton(
                      onPressed: _cancel,
                      child: Text(
                        MaterialLocalizations.of(context).cancelButtonLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
