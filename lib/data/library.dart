import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import 'quran_db.dart';

/// How a session opens.
enum SessionKind {
  /// Continue where you stopped (daily reading, long surahs).
  resume,

  /// Open at the start of its surah every time (e.g. Al-Mulk at night).
  restart,
}

/// A gentle nudge to read a session: a local notification at [hour]:[minute]
/// on each of [weekdays] (1 = Monday … 7 = Sunday, as [DateTime.weekday]).
class Reminder {
  const Reminder({
    required this.hour,
    required this.minute,
    this.weekdays = const {1, 2, 3, 4, 5, 6, 7},
  });

  final int hour;
  final int minute;
  final Set<int> weekdays;

  bool get everyDay => weekdays.length == 7;

  Reminder copyWith({int? hour, int? minute, Set<int>? weekdays}) => Reminder(
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    weekdays: weekdays ?? this.weekdays,
  );

  Map<String, Object?> toJson() => {
    'hour': hour,
    'minute': minute,
    'weekdays': (weekdays.toList()..sort()),
  };

  factory Reminder.fromJson(Map<String, Object?> j) => Reminder(
    hour: j['hour'] as int,
    minute: j['minute'] as int,
    weekdays: {...(j['weekdays'] as List).cast<int>()},
  );

  @override
  bool operator ==(Object other) =>
      other is Reminder &&
      other.hour == hour &&
      other.minute == minute &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.containsAll(weekdays);

  @override
  int get hashCode =>
      Object.hash(hour, minute, Object.hashAllUnordered(weekdays));
}

/// A named reading position that moves as you read.
class Session {
  const Session({
    required this.id,
    required this.name,
    required this.surah,
    required this.ayah,
    this.kind = SessionKind.resume,
    this.anchorSurah,
    this.updatedAt = 0,
    this.reminder,
  });

  final String id;
  final String name;

  /// Where the reader is, as an ayah (edition-independent).
  final int surah;
  final int ayah;
  final SessionKind kind;

  /// For [SessionKind.restart]: the surah it always opens at.
  final int? anchorSurah;
  final int updatedAt;

  /// A reading reminder, or null for none.
  final Reminder? reminder;

  static const dailyId = 'daily';

  /// Daily reading's name until the reader renames it (shown translated).
  static const dailyDefaultName = 'Daily reading';

  bool get isDaily => id == dailyId;

  /// Where opening the session lands.
  (int, int) get openAt => kind == SessionKind.restart && anchorSurah != null
      ? (anchorSurah!, 1)
      : (surah, ayah);

  Session copyWith({
    String? name,
    int? surah,
    int? ayah,
    SessionKind? kind,
    int? anchorSurah,
    int? updatedAt,
    Reminder? reminder,
    bool noReminder = false,
  }) => Session(
    id: id,
    name: name ?? this.name,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    kind: kind ?? this.kind,
    anchorSurah: anchorSurah ?? this.anchorSurah,
    updatedAt: updatedAt ?? this.updatedAt,
    reminder: noReminder ? null : reminder ?? this.reminder,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'surah': surah,
    'ayah': ayah,
    'kind': kind.name,
    'anchorSurah': anchorSurah,
    'updatedAt': updatedAt,
    'reminder': reminder?.toJson(),
  };

  factory Session.fromJson(Map<String, Object?> j) => Session(
    id: j['id'] as String,
    name: j['name'] as String,
    surah: j['surah'] as int,
    ayah: j['ayah'] as int,
    kind: SessionKind.values.asNameMap()[j['kind']] ?? SessionKind.resume,
    anchorSurah: j['anchorSurah'] as int?,
    updatedAt: j['updatedAt'] as int? ?? 0,
    reminder: j['reminder'] == null
        ? null
        : Reminder.fromJson((j['reminder'] as Map).cast<String, Object?>()),
  );
}

/// A fixed mark on an ayah, with an optional note.
class Bookmark {
  const Bookmark({
    required this.surah,
    required this.ayah,
    this.note = '',
    required this.createdAt,
  });

  final int surah;
  final int ayah;
  final String note;
  final int createdAt;

  Map<String, Object?> toJson() => {
    'surah': surah,
    'ayah': ayah,
    'note': note,
    'createdAt': createdAt,
  };

  factory Bookmark.fromJson(Map<String, Object?> j) => Bookmark(
    surah: j['surah'] as int,
    ayah: j['ayah'] as int,
    note: j['note'] as String? ?? '',
    createdAt: j['createdAt'] as int? ?? 0,
  );
}

class Library {
  const Library({
    required this.sessions,
    required this.currentId,
    required this.bookmarks,
  });

  final List<Session> sessions;
  final String currentId;
  final List<Bookmark> bookmarks;

  Session session(String id) =>
      sessions.firstWhere((s) => s.id == id, orElse: () => sessions.first);

  Session get current => session(currentId);

  bool isBookmarked(int surah, int ayah) =>
      bookmarks.any((b) => b.surah == surah && b.ayah == ayah);
}

final libraryProvider = NotifierProvider<LibraryNotifier, Library>(
  LibraryNotifier.new,
);

/// Sessions and bookmarks, persisted as JSON in SharedPreferences.
class LibraryNotifier extends Notifier<Library> {
  static const _sessionsKey = 'sessions';
  static const _currentKey = 'currentSession';
  static const _bookmarksKey = 'bookmarks';

  int get _now => DateTime.now().millisecondsSinceEpoch;

  @override
  Library build() {
    final p = ref.read(prefsProvider);
    List<Map<String, Object?>> read(String key) {
      final raw = p.getString(key);
      if (raw == null) return [];
      return (jsonDecode(raw) as List).cast<Map<String, Object?>>();
    }

    var sessions = read(_sessionsKey).map(Session.fromJson).toList();
    if (!sessions.any((s) => s.isDaily)) {
      // First run, or an install from before sessions: the old single reading
      // position becomes Daily reading.
      sessions = [
        Session(
          id: Session.dailyId,
          name: Session.dailyDefaultName,
          surah: p.getInt('lastSurah') ?? 1,
          ayah: p.getInt('lastAyah') ?? 1,
        ),
        ...sessions,
      ];
    }
    return Library(
      sessions: sessions,
      currentId: p.getString(_currentKey) ?? Session.dailyId,
      bookmarks: read(_bookmarksKey).map(Bookmark.fromJson).toList(),
    );
  }

  void _save(Library next) {
    state = next;
    ref.read(prefsProvider)
      ..setString(
        _sessionsKey,
        jsonEncode([for (final s in next.sessions) s.toJson()]),
      )
      ..setString(_currentKey, next.currentId)
      ..setString(
        _bookmarksKey,
        jsonEncode([for (final b in next.bookmarks) b.toJson()]),
      );
  }

  void _replace(Session updated) => _save(
    Library(
      sessions: [
        for (final s in state.sessions) s.id == updated.id ? updated : s,
      ],
      currentId: state.currentId,
      bookmarks: state.bookmarks,
    ),
  );

  /// Records the reading position of a session.
  void setPosition(String sessionId, int surah, int ayah) {
    // A save deferred from a closing reader can arrive after the app itself
    // has shut down.
    if (!ref.mounted) return;
    final s = state.session(sessionId);
    if (s.surah == surah && s.ayah == ayah) return;
    _replace(s.copyWith(surah: surah, ayah: ayah, updatedAt: _now));
  }

  void setCurrent(String id) => _save(
    Library(
      sessions: state.sessions,
      currentId: id,
      bookmarks: state.bookmarks,
    ),
  );

  /// Adds a session and makes it current; returns its id.
  String add({
    required String name,
    required int surah,
    required int ayah,
    SessionKind kind = SessionKind.resume,
    Reminder? reminder,
  }) {
    final id = 's$_now';
    _save(
      Library(
        sessions: [
          ...state.sessions,
          Session(
            id: id,
            name: name,
            surah: surah,
            ayah: ayah,
            kind: kind,
            anchorSurah: kind == SessionKind.restart ? surah : null,
            updatedAt: _now,
            reminder: reminder,
          ),
        ],
        currentId: id,
        bookmarks: state.bookmarks,
      ),
    );
    return id;
  }

  /// The sessions (with their reminders) and bookmarks (with their notes),
  /// as a file to keep or to move to another device.
  String export() => const JsonEncoder.withIndent('  ').convert({
    'app': 'Quiet Quran',
    'kind': 'library',
    'version': 1,
    'exported': DateTime.now().toUtc().toIso8601String(),
    'currentSession': state.currentId,
    'sessions': [for (final s in state.sessions) s.toJson()],
    'bookmarks': [for (final b in state.bookmarks) b.toJson()],
  });

  /// Replaces this device's sessions and bookmarks with those of an
  /// [export]ed file, returning how many of each. Throws a FormatException
  /// for anything that isn't one; places outside the Quran are left out.
  ({int sessions, int bookmarks}) import(String text) {
    final db = ref.read(quranDbProvider);
    bool valid(int surah, int ayah) =>
        surah >= 1 &&
        surah <= 114 &&
        ayah >= 1 &&
        ayah <= db.surah(surah).versesCount;
    try {
      final j = jsonDecode(text);
      if (j is! Map || j['kind'] != 'library' || j['sessions'] is! List) {
        throw const FormatException('Not a Quiet Quran file');
      }
      var sessions = [
        for (final s in j['sessions'] as List)
          Session.fromJson((s as Map).cast<String, Object?>()),
      ].where((s) => valid(s.surah, s.ayah)).toList();
      final bookmarks = [
        for (final b in (j['bookmarks'] as List?) ?? const [])
          Bookmark.fromJson((b as Map).cast<String, Object?>()),
      ].where((b) => valid(b.surah, b.ayah)).toList();
      if (!sessions.any((s) => s.isDaily)) {
        sessions = [
          const Session(
            id: Session.dailyId,
            name: Session.dailyDefaultName,
            surah: 1,
            ayah: 1,
          ),
          ...sessions,
        ];
      }
      final current = j['currentSession'];
      _save(
        Library(
          sessions: sessions,
          currentId: sessions.any((s) => s.id == current)
              ? current as String
              : Session.dailyId,
          bookmarks: bookmarks,
        ),
      );
      return (sessions: sessions.length, bookmarks: bookmarks.length);
    } on FormatException {
      rethrow;
    } on Object {
      // A cast that didn't hold: some other JSON.
      throw const FormatException('Not a Quiet Quran file');
    }
  }

  void update(Session s) => _replace(s);

  /// Removes a session (Daily reading cannot be removed).
  void remove(String id) {
    if (id == Session.dailyId) return;
    _save(
      Library(
        sessions: state.sessions.where((s) => s.id != id).toList(),
        currentId: state.currentId == id ? Session.dailyId : state.currentId,
        bookmarks: state.bookmarks,
      ),
    );
  }

  /// Bookmarks the ayah, or removes its bookmark.
  void toggleBookmark(int surah, int ayah) {
    final has = state.isBookmarked(surah, ayah);
    _save(
      Library(
        sessions: state.sessions,
        currentId: state.currentId,
        bookmarks: has
            ? state.bookmarks
                  .where((b) => !(b.surah == surah && b.ayah == ayah))
                  .toList()
            : [
                Bookmark(surah: surah, ayah: ayah, createdAt: _now),
                ...state.bookmarks,
              ],
      ),
    );
  }

  void setBookmarkNote(int surah, int ayah, String note) => _save(
    Library(
      sessions: state.sessions,
      currentId: state.currentId,
      bookmarks: [
        for (final b in state.bookmarks)
          b.surah == surah && b.ayah == ayah
              ? Bookmark(
                  surah: b.surah,
                  ayah: b.ayah,
                  note: note,
                  createdAt: b.createdAt,
                )
              : b,
      ],
    ),
  );
}
