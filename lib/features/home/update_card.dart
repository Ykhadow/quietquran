import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme.dart';
import '../../data/updates.dart';
import '../../l10n/l10n.dart';

/// A newer version, on home (website and GitHub builds only), in the same
/// raised card as the daily reading: what it is and what's new, then
/// Update or Later; the download's progress; then Install.
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
    final notes = u.notesFor(l.localeName);

    final (String? line, List<Widget> actions) = switch (s.stage) {
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
        notes,
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: t.surf,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.line2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 13, color: t.acc),
              const SizedBox(width: 6),
              Text(
                l.updateEyebrow.toUpperCase(),
                style: AppType.eyebrow(t.acc),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.updateTitle(u.version),
            style: AppType.titleLg(t.ink).copyWith(fontSize: 20),
          ),
          if (line != null && line.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(line, style: AppType.caption(t.mut).copyWith(height: 1.45)),
          ],
          if (s.stage == UpdateStage.downloading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: s.progress, minHeight: 5),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
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
