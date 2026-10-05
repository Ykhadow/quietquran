import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/library.dart';
import '../../data/quran_db.dart';
import '../../data/reminders.dart';
import '../../widgets/night.dart';
import '../../l10n/l10n.dart';
import 'reminder_editor.dart';

/// Rename a session, change how it opens and when it shows first, or delete
/// it. Daily reading can be renamed but not deleted.
Future<void> showEditSessionSheet(BuildContext context, Session session) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditSessionSheet(session: session),
    );

class _EditSessionSheet extends ConsumerStatefulWidget {
  const _EditSessionSheet({required this.session});

  final Session session;

  @override
  ConsumerState<_EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends ConsumerState<_EditSessionSheet> {
  late final _name = TextEditingController(
    text:
        widget.session.isDaily &&
            widget.session.name == Session.dailyDefaultName
        ? null
        : widget.session.name,
  );
  late SessionKind _kind = widget.session.kind;
  late Reminder? _reminder = widget.session.reminder;
  bool _confirmDelete = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final s = widget.session;
    ref
        .read(libraryProvider.notifier)
        .update(
          s.copyWith(
            name: _name.text.trim().isEmpty ? s.name : _name.text.trim(),
            kind: _kind,
            // A session switched to "start of surah" opens at its current surah.
            anchorSurah: _kind == SessionKind.restart
                ? (s.anchorSurah ?? s.surah)
                : null,
            reminder: _reminder,
            noReminder: _reminder == null,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = widget.session;
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.editSession, style: AppType.titleLg(t.ink)),
              Eyebrow(
                l.name,
                padding: const EdgeInsets.only(top: 18, bottom: 8),
              ),
              TextField(
                controller: _name,
                style: AppType.body(t.ink),
                decoration: InputDecoration(hintText: context.sessionName(s)),
              ),
              Eyebrow(
                l.eachTimeOpen,
                padding: const EdgeInsets.only(top: 18, bottom: 8),
              ),
              Segmented<SessionKind>(
                value: _kind,
                onChanged: (v) => setState(() => _kind = v),
                options: [
                  (SessionKind.resume, l.resume),
                  (SessionKind.restart, l.startOfSurah),
                ],
              ),
              if (ReminderService.supported)
                ReminderEditor(
                  reminder: _reminder,
                  onChanged: (r) => setState(() => _reminder = r),
                ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _save, child: Text(l.save)),
              if (!s.isDaily) ...[
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: t.acc),
                  onPressed: () {
                    if (!_confirmDelete) {
                      setState(() => _confirmDelete = true);
                      return;
                    }
                    ref.read(libraryProvider.notifier).remove(s.id);
                    Navigator.pop(context);
                  },
                  child: Text(
                    _confirmDelete
                        ? l.tapAgainDelete(context.sessionName(s))
                        : l.deleteSession,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Add a note to a bookmark, or remove it.
Future<void> showBookmarkSheet(BuildContext context, Bookmark bookmark) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BookmarkSheet(bookmark: bookmark),
    );

class _BookmarkSheet extends ConsumerStatefulWidget {
  const _BookmarkSheet({required this.bookmark});

  final Bookmark bookmark;

  @override
  ConsumerState<_BookmarkSheet> createState() => _BookmarkSheetState();
}

class _BookmarkSheetState extends ConsumerState<_BookmarkSheet> {
  late final _note = TextEditingController(text: widget.bookmark.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final b = widget.bookmark;
    final db = ref.watch(quranDbProvider);
    final notifier = ref.read(libraryProvider.notifier);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${context.surahName(db.surah(b.surah))} ${b.surah}:${b.ayah}',
                style: AppType.titleLg(t.ink),
              ),
              Eyebrow(
                context.l10n.note,
                padding: const EdgeInsets.only(top: 18, bottom: 8),
              ),
              TextField(
                controller: _note,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: AppType.body(t.ink),
                decoration: InputDecoration(hintText: context.l10n.optional),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  notifier.setBookmarkNote(b.surah, b.ayah, _note.text.trim());
                  Navigator.pop(context);
                },
                child: Text(context.l10n.save),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  notifier.toggleBookmark(b.surah, b.ayah);
                  Navigator.pop(context);
                },
                child: Text(context.l10n.removeBookmark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Just a session's reminder, opened from the bell on the home screen.
Future<void> showReminderSheet(BuildContext context, Session session) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReminderSheet(session: session),
    );

class _ReminderSheet extends ConsumerStatefulWidget {
  const _ReminderSheet({required this.session});

  final Session session;

  @override
  ConsumerState<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<_ReminderSheet> {
  late Reminder? _reminder = widget.session.reminder;

  void _save() {
    ref
        .read(libraryProvider.notifier)
        .update(
          widget.session.copyWith(
            reminder: _reminder,
            noReminder: _reminder == null,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.sessionName(widget.session),
              style: AppType.titleLg(t.ink),
            ),
            ReminderEditor(
              reminder: _reminder,
              onChanged: (r) => setState(() => _reminder = r),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: Text(l.save)),
          ],
        ),
      ),
    );
  }
}
