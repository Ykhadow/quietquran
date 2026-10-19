import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme.dart';
import '../../data/updates.dart';
import '../../l10n/l10n.dart';

/// A quiet card at the top of home when a newer version is out (website
/// and GitHub builds only): Update or Later, then the download's progress,
/// then Install.
class UpdateCard extends ConsumerWidget {
  const UpdateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final s = ref.watch(updateProvider);
    final u = s.update;
    if (s.stage == UpdateStage.none || u == null) {
      return const SizedBox.shrink();
    }
    final checker = ref.read(updateProvider.notifier);
    void update() => checker.update(
      downloading: l.updateDownloadingNotice,
      downloaded: l.updateReadyNotice,
    );

    final (String text, List<Widget> actions) = switch (s.stage) {
      UpdateStage.downloading => (
        l.updateDownloading(((s.progress ?? 0) * 100).round()),
        <Widget>[],
      ),
      UpdateStage.ready => (
        l.updateReady,
        [
          FilledButton(
            onPressed: checker.install,
            child: Text(l.updateInstall),
          ),
        ],
      ),
      UpdateStage.failed => (
        l.updateFailed,
        [TextButton(onPressed: checker.later, child: Text(l.updateLater))],
      ),
      _ => (
        l.updateAvailable(u.version),
        [
          TextButton(onPressed: checker.later, child: Text(l.updateLater)),
          FilledButton(
            onPressed: update,
            child: Text(Platform.isAndroid ? l.updateNow : l.updateDownload),
          ),
        ],
      ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: t.surf,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.line2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.download, size: 18, color: t.acc),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: AppType.body(t.ink))),
            ],
          ),
          if (s.stage == UpdateStage.downloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: s.progress, minHeight: 3),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final (i, a) in actions.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  a,
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
