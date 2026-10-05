import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme.dart';
import '../../data/library.dart';
import '../../l10n/l10n.dart';
import '../../widgets/night.dart';

/// Settings' "Your places": the sessions and bookmarks saved to a file, and
/// brought back from one, on this device or another. No account involved.
class BackupRows extends ConsumerWidget {
  const BackupRows({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return GroupedCard(
      children: [
        _Row(
          icon: LucideIcons.download,
          title: l.exportLibrary,
          subtitle: l.exportLibraryHint,
          onTap: () => _export(context, ref),
        ),
        _Row(
          icon: LucideIcons.upload,
          title: l.importLibrary,
          subtitle: l.importLibraryHint,
          onTap: () => _import(context, ref),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final text = ref.read(libraryProvider.notifier).export();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final saved = await FilePicker.saveFile(
      fileName: 'quiet-quran-$date.json',
      bytes: Uint8List.fromList(utf8.encode(text)),
      mimeType: 'application/json',
    );
    if (saved != null) {
      messenger.showSnackBar(SnackBar(content: Text(l.exported)));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    // Any file: phones don't always know a .json file as JSON.
    final file = await FilePicker.pickFile();
    if (file == null || !context.mounted) return;
    final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
    if (!context.mounted) return;
    if (!_looksLikeOurs(text)) {
      messenger.showSnackBar(SnackBar(content: Text(l.importFailed)));
      return;
    }
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.importConfirmTitle),
        content: Text(l.importConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.replace),
          ),
        ],
      ),
    );
    if (replace != true) return;
    try {
      final n = ref.read(libraryProvider.notifier).import(text);
      messenger.showSnackBar(
        SnackBar(content: Text(l.imported(n.sessions, n.bookmarks))),
      );
    } on FormatException {
      messenger.showSnackBar(SnackBar(content: Text(l.importFailed)));
    }
  }

  /// A quick look before asking to replace anything.
  static bool _looksLikeOurs(String text) {
    try {
      final j = jsonDecode(text);
      return j is Map && j['kind'] == 'library' && j['sessions'] is List;
    } on FormatException {
      return false;
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: t.acc),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppType.title(t.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppType.caption(t.mut)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
