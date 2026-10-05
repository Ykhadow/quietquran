import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/library.dart';
import '../../data/reminders.dart';
import '../../l10n/l10n.dart';

/// "Remind me" for a session: off, or a time and the days to be reminded.
/// Turning it on asks for permission to show notifications (once), and says
/// so if the phone has them turned off. Only shown where reminders work.
class ReminderEditor extends StatefulWidget {
  const ReminderEditor({
    super.key,
    required this.reminder,
    required this.onChanged,
  });

  final Reminder? reminder;
  final ValueChanged<Reminder?> onChanged;

  @override
  State<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<ReminderEditor> {
  bool _blocked = false;

  Future<void> _turnOn() async {
    widget.onChanged(const Reminder(hour: 20, minute: 0));
    final allowed = await ReminderService.requestPermission();
    if (mounted) setState(() => _blocked = !allowed);
  }

  Future<void> _pickTime(Reminder r) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: r.hour, minute: r.minute),
    );
    if (picked != null) {
      widget.onChanged(r.copyWith(hour: picked.hour, minute: picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final m = MaterialLocalizations.of(context);
    final r = widget.reminder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                l.remindMe.toUpperCase(),
                style: AppType.eyebrow(t.mut),
              ),
            ),
            Switch(
              value: r != null,
              activeThumbColor: t.acc,
              onChanged: (on) => on ? _turnOn() : widget.onChanged(null),
            ),
          ],
        ),
        if (r != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () => _pickTime(r),
              icon: const Icon(Icons.schedule, size: 18),
              label: Text(
                m.formatTimeOfDay(TimeOfDay(hour: r.hour, minute: r.minute)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Weekdays(
            days: r.weekdays,
            onChanged: (days) => widget.onChanged(r.copyWith(weekdays: days)),
          ),
          if (r.everyDay)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l.everyDay, style: AppType.caption(t.mut)),
            ),
          if (_blocked)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l.reminderPermissionOff,
                style: AppType.caption(t.acc),
              ),
            ),
        ],
      ],
    );
  }
}

/// Seven round toggles, one per weekday, in the order the phone's language
/// starts its week. At least one day always stays on.
class _Weekdays extends StatelessWidget {
  const _Weekdays({required this.days, required this.onChanged});

  final Set<int> days;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final m = MaterialLocalizations.of(context);
    // MaterialLocalizations counts from Sunday (0); DateTime.weekday from
    // Monday (1) to Sunday (7).
    final order = [for (var i = 0; i < 7; i++) (m.firstDayOfWeekIndex + i) % 7];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final i in order)
          Builder(
            builder: (context) {
              final weekday = i == 0 ? 7 : i;
              final on = days.contains(weekday);
              return Semantics(
                button: true,
                selected: on,
                label: m.narrowWeekdays[i],
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    final next = {...days};
                    on ? next.remove(weekday) : next.add(weekday);
                    if (next.isNotEmpty) onChanged(next);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? t.acc : t.surf,
                      border: Border.all(color: on ? t.acc : t.line2),
                    ),
                    child: Text(
                      m.narrowWeekdays[i],
                      style: AppType.label(on ? t.onAcc : t.mut),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
