import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'library.dart';

/// One notification to schedule: a session's reminder on one weekday, or on
/// every day ([weekday] null).
@immutable
class PlannedReminder {
  const PlannedReminder({
    required this.sessionId,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.weekday,
  });

  final String sessionId;
  final String title;
  final String body;
  final int hour;
  final int minute;

  /// 1 = Monday … 7 = Sunday; null for every day.
  final int? weekday;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.sessionId == sessionId &&
      other.title == title &&
      other.body == body &&
      other.hour == hour &&
      other.minute == minute &&
      other.weekday == weekday;

  @override
  int get hashCode =>
      Object.hash(sessionId, title, body, hour, minute, weekday);

  @override
  String toString() =>
      'PlannedReminder($sessionId, $title, $hour:$minute, day $weekday)';
}

/// The notifications that make up every session's reminder: one repeating
/// daily notification for a reminder set on all seven days, otherwise one
/// weekly notification per chosen day.
List<PlannedReminder> planReminders(
  List<Session> sessions, {
  required String Function(Session) title,
  required String body,
}) => [
  for (final s in sessions)
    if (s.reminder case final r? when r.weekdays.isNotEmpty)
      if (r.everyDay)
        PlannedReminder(
          sessionId: s.id,
          title: title(s),
          body: body,
          hour: r.hour,
          minute: r.minute,
        )
      else
        for (final day in r.weekdays.toList()..sort())
          PlannedReminder(
            sessionId: s.id,
            title: title(s),
            body: body,
            hour: r.hour,
            minute: r.minute,
            weekday: day,
          ),
];

/// The next moment, after [now], at [hour]:[minute] (on [weekday], if
/// given) in [now]'s time zone.
tz.TZDateTime nextOccurrence(
  tz.TZDateTime now,
  int hour,
  int minute, {
  int? weekday,
}) {
  var at = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  while (!at.isAfter(now) || (weekday != null && at.weekday != weekday)) {
    at = tz.TZDateTime(
      now.location,
      at.year,
      at.month,
      at.day + 1,
      hour,
      minute,
    );
  }
  return at;
}

/// Reading reminders as local notifications: scheduled on the phone, shown
/// by the phone, nothing sent anywhere. Android and iOS only.
class ReminderService {
  ReminderService._();

  static bool get supported =>
      debugSupported ?? (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

  /// Lets tests (and the website's screenshots) show the reminder controls
  /// on a desktop.
  @visibleForTesting
  static bool? debugSupported;

  /// Whether notifications can really be scheduled (not when the controls
  /// are only shown for a test).
  static bool get _onDevice => debugSupported == null && supported;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// The session a tapped reminder was for, until the app opens it.
  static final tappedSession = ValueNotifier<String?>(null);

  /// Sets up notifications and the local time zone, and notes whether the
  /// app was opened from a reminder. Safe to call more than once.
  static Future<void> init() async {
    if (!_onDevice || _ready) return;
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object {
      // Unknown zone name: times stay in UTC rather than failing.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          // Asked only when a reminder is first turned on.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) => tappedSession.value = r.payload,
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      tappedSession.value = launch!.notificationResponse?.payload;
    }
    _ready = true;
  }

  /// Asks to show notifications (Android 13+, iOS). True if allowed.
  static Future<bool> requestPermission() async {
    if (!_onDevice) return false;
    await init();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true) ??
        false;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reading_reminders',
      'Reading reminders',
      channelDescription: 'Reminders you set for your reading sessions',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static List<PlannedReminder>? _scheduled;

  /// Makes the phone's scheduled reminders exactly [plan] (all others are
  /// removed). Does nothing if [plan] is what's already scheduled.
  static Future<void> schedule(List<PlannedReminder> plan) async {
    if (!_onDevice) return;
    if (listEquals(plan, _scheduled)) return;
    await init();
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    for (final (i, r) in plan.indexed) {
      await _plugin.zonedSchedule(
        id: i + 1,
        title: r.title,
        body: r.body,
        payload: r.sessionId,
        scheduledDate: nextOccurrence(
          now,
          r.hour,
          r.minute,
          weekday: r.weekday,
        ),
        notificationDetails: _details,
        // Around the time is enough, and needs no exact-alarm permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: r.weekday == null
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
      );
    }
    _scheduled = plan;
  }
}
