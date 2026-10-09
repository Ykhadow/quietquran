import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/image_editions.dart';
import '../../data/page_images.dart';
import '../../l10n/l10n.dart';

/// As a reader picks a printed set, asks whether to save all of it now (in
/// the background, while they read) or let pages load as they're read.
/// Nothing is asked if the set is already saved or downloading. Either way
/// the printed pages open at once; progress shows in the reader and in
/// Settings.
Future<void> askToSavePrinted(
  BuildContext context,
  WidgetRef ref,
  ImageEdition edition,
) async {
  final store = ref.read(pageImageStoreProvider.notifier);
  final total = store.pageCount(edition);
  if (ref.read(pageImageStoreProvider)[edition.id]?.running ?? false) return;
  if (await store.savedCount(edition) >= total) return;
  if (!context.mounted) return;
  final l = context.l10n;
  final all = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(l.printedDownloadTitle),
      content: Text(l.printedDownloadBody(total, edition.approxTotalMb)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.printedLoadAsRead),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.printedDownloadAll),
        ),
      ],
    ),
  );
  if ((all ?? false) && context.mounted) savePrinted(context, ref, edition);
}

/// Saves the rest of [edition] in the background, with its progress in a
/// notification.
void savePrinted(BuildContext context, WidgetRef ref, ImageEdition edition) {
  final l = context.l10n;
  ref
      .read(pageImageStoreProvider.notifier)
      .downloadAll(
        edition,
        saving: l.printedSavingNotice('{numFinished}', '{numTotal}'),
        saved: l.printedSavedNotice,
      );
}
