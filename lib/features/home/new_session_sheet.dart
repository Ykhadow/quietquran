import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/library.dart';
import '../../data/quran_db.dart';
import '../../data/reminders.dart';
import '../../widgets/night.dart';
import '../../l10n/l10n.dart';
import 'reminder_editor.dart';

/// Creates a session. [surah]/[ayah] preset the starting point (e.g. when
/// saving a free read); otherwise the reader picks a surah. Returns the new
/// session's id, or null if cancelled.
Future<String?> showNewSessionSheet(
  BuildContext context, {
  int? surah,
  int? ayah,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  builder: (context) => _NewSessionSheet(surah: surah, ayah: ayah),
);

class _NewSessionSheet extends ConsumerStatefulWidget {
  const _NewSessionSheet({this.surah, this.ayah});

  final int? surah;
  final int? ayah;

  @override
  ConsumerState<_NewSessionSheet> createState() => _NewSessionSheetState();
}

class _NewSessionSheetState extends ConsumerState<_NewSessionSheet> {
  late int _surah = widget.surah ?? 67;
  final _name = TextEditingController();
  bool _nameEdited = false;
  SessionKind _kind = SessionKind.resume;
  Reminder? _reminder;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The suggestion is in the app's language, so it needs the context.
    if (!_nameEdited) _name.text = _suggestedName();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _suggestedName() =>
      context.surahName(ref.read(quranDbProvider).surah(_surah));

  void _setSurah(int s) {
    setState(() => _surah = s);
    if (!_nameEdited) _name.text = _suggestedName();
  }

  void _create() {
    final name = _name.text.trim().isEmpty
        ? _suggestedName()
        : _name.text.trim();
    // A preset starting ayah is kept unless the surah was changed.
    final ayah = _surah == widget.surah ? (widget.ayah ?? 1) : 1;
    final id = ref
        .read(libraryProvider.notifier)
        .add(
          name: name,
          surah: _surah,
          ayah: ayah,
          kind: _kind,
          reminder: _reminder,
        );
    Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final db = ref.watch(quranDbProvider);
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
              Text(l.newSession, style: AppType.titleLg(t.ink)),
              const SizedBox(height: 4),
              Text(l.newSessionHint, style: AppType.caption(t.mut)),
              Eyebrow(
                l.name,
                padding: const EdgeInsets.only(top: 18, bottom: 8),
              ),
              TextField(
                controller: _name,
                onChanged: (_) => _nameEdited = true,
                textCapitalization: TextCapitalization.sentences,
                style: AppType.body(t.ink),
                decoration: InputDecoration(hintText: l.nameExample),
              ),
              Eyebrow(
                l.startsAt,
                padding: const EdgeInsets.only(top: 18, bottom: 8),
              ),
              DropdownButtonFormField<int>(
                initialValue: _surah,
                isExpanded: true,
                menuMaxHeight: 420,
                items: [
                  for (final s in db.surahs)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        '${s.id}. ${context.surahName(s)}',
                        style: AppType.body(t.ink),
                      ),
                    ),
                ],
                onChanged: (v) => _setSurah(v!),
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
              FilledButton(onPressed: _create, child: Text(l.createSession)),
            ],
          ),
        ),
      ),
    );
  }
}
