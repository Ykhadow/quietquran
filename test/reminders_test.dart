// Reading reminders: what gets scheduled for each session, when the next one
// falls, that reminders survive saving, and the editor in the session sheets.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/theme.dart';
import 'package:mushaf15/data/library.dart';
import 'package:mushaf15/data/reminders.dart';
import 'package:mushaf15/features/home/reminder_editor.dart';
import 'package:mushaf15/l10n/l10n.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Session _session(String id, Reminder? reminder) =>
    Session(id: id, name: id, surah: 1, ayah: 1, reminder: reminder);

void main() {
  tzdata.initializeTimeZones();

  group('planReminders', () {
    test('every day is one daily notification', () {
      final plan = planReminders(
        [_session('a', const Reminder(hour: 6, minute: 30))],
        title: (s) => s.name,
        body: 'body',
      );
      expect(plan, [
        const PlannedReminder(
          sessionId: 'a',
          title: 'a',
          body: 'body',
          hour: 6,
          minute: 30,
        ),
      ]);
    });

    test('chosen days are one weekly notification each, in order', () {
      final plan = planReminders(
        [
          _session('a', const Reminder(hour: 21, minute: 0, weekdays: {5, 1})),
          _session('b', null),
        ],
        title: (s) => s.name,
        body: 'body',
      );
      expect(
        [for (final p in plan) (p.sessionId, p.weekday)],
        [('a', 1), ('a', 5)],
      );
    });

    test('sessions without reminders plan nothing', () {
      expect(
        planReminders([_session('a', null)], title: (s) => '', body: ''),
        isEmpty,
      );
    });
  });

  group('nextOccurrence', () {
    final karachi = tz.getLocation('Asia/Karachi');

    test('later today, or tomorrow once the time has passed', () {
      final morning = tz.TZDateTime(karachi, 2026, 9, 29, 8);
      expect(
        nextOccurrence(morning, 20, 0),
        tz.TZDateTime(karachi, 2026, 9, 29, 20),
      );
      final night = tz.TZDateTime(karachi, 2026, 9, 29, 21);
      expect(
        nextOccurrence(night, 20, 0),
        tz.TZDateTime(karachi, 2026, 9, 30, 20),
      );
      // Exactly now counts as passed.
      final now = tz.TZDateTime(karachi, 2026, 9, 29, 20);
      expect(nextOccurrence(now, 20, 0).day, 30);
    });

    test('the next matching weekday', () {
      // 29 Sep 2026 is a Tuesday.
      final tue = tz.TZDateTime(karachi, 2026, 9, 29, 8);
      expect(tue.weekday, DateTime.tuesday);
      final fri = nextOccurrence(tue, 7, 15, weekday: DateTime.friday);
      expect(fri, tz.TZDateTime(karachi, 2026, 10, 2, 7, 15));
      // Same weekday, time passed: a week later.
      final late = tz.TZDateTime(karachi, 2026, 9, 29, 9);
      expect(
        nextOccurrence(late, 8, 0, weekday: DateTime.tuesday),
        tz.TZDateTime(karachi, 2026, 10, 6, 8),
      );
    });

    test('keeps the wall-clock time across a clock change', () {
      final london = tz.getLocation('Europe/London');
      // Clocks go back on 25 Oct 2026.
      final sat = tz.TZDateTime(london, 2026, 10, 24, 22);
      final next = nextOccurrence(sat, 20, 0, weekday: DateTime.sunday);
      expect((next.day, next.hour, next.minute), (25, 20, 0));
    });
  });

  test('a session keeps its reminder through saving', () {
    const r = Reminder(hour: 5, minute: 45, weekdays: {5, 6, 7});
    final back = Session.fromJson(_session('a', r).toJson());
    expect(back.reminder, r);
    expect(Session.fromJson(_session('b', null).toJson()).reminder, isNull);
    // Removing it.
    expect(_session('a', r).copyWith(noReminder: true).reminder, isNull);
  });

  group('editor', () {
    Future<List<Reminder?>> pump(WidgetTester tester, Reminder? start) async {
      final changes = <Reminder?>[];
      var current = start;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Palette.day),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => ReminderEditor(
                reminder: current,
                onChanged: (r) => setState(() {
                  changes.add(r);
                  current = r;
                }),
              ),
            ),
          ),
        ),
      );
      return changes;
    }

    testWidgets('turning it on sets every day at 8 pm', (tester) async {
      final changes = await pump(tester, null);
      expect(find.text('M'), findsNothing);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(changes.single, const Reminder(hour: 20, minute: 0));
      expect(find.text('8:00 PM'), findsOneWidget);
      expect(find.text('Every day'), findsOneWidget);
      // No notifications here (tests run on desktop): says they're off.
      expect(find.textContaining('Notifications'), findsOneWidget);
    });

    testWidgets('days toggle, and the last day stays on', (tester) async {
      final changes = await pump(
        tester,
        const Reminder(hour: 7, minute: 0, weekdays: {1}),
      );
      await tester.tap(find.text('M'));
      await tester.pump();
      expect(changes, isEmpty);
      // Friday on.
      await tester.tap(find.text('F'));
      await tester.pumpAndSettle();
      expect(changes.last!.weekdays, {1, 5});
      expect(find.text('Every day'), findsNothing);
    });

    testWidgets('turning it off removes it', (tester) async {
      final changes = await pump(tester, const Reminder(hour: 7, minute: 0));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(changes.single, isNull);
    });
  });
}
