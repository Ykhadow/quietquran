import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/settings.dart';
import '../../data/models.dart';
import '../../data/quran_db.dart';
import 'quran_word.dart';

/// Word widths for Easy read, measured ahead of time on the web version.
///
/// Easy read fills its lines from each word's width (QuranWord.widthOf). A
/// browser on a phone takes about a millisecond to measure a word, so a page
/// of new words held up the first frame for a fifth of a second. Here the
/// words are measured a few at a time while the app is idle, nearest the
/// reader's place first, and the results are kept in the browser's storage.
///
/// Every width kept is one this browser measured with QuranWord.widthOf, so
/// a page is laid out exactly as if it were measured fresh. They are kept
/// only for the build that measured them ([_build], set by
/// tool/build_web.py): a new release measures again.
///
/// Only on the web: the apps measure fast enough as they go.
class WordWidths {
  WordWidths._();

  static const _key = 'word_widths';
  static const _build = String.fromEnvironment('WEB_BUILD');
  static const _chunk = 200; // words read from the database at a time
  static const _slice = Duration(milliseconds: 3); // work per idle moment

  static SharedPreferences? _prefs;
  static int _saved = 0;
  static Object? _run;

  static bool get _keeps => kIsWeb && _build.isNotEmpty;

  /// Loads the widths kept from earlier visits.
  static void restore(SharedPreferences prefs) {
    if (!_keeps) return;
    _prefs = prefs;
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['build'] != _build) {
        prefs.remove(_key);
        return;
      }
      final families = data['widths'] as Map<String, dynamic>;
      for (final MapEntry(key: family, value: words) in families.entries) {
        for (final MapEntry(key: text, value: width)
            in (words as Map<String, dynamic>).entries) {
          QuranWord.measured.putIfAbsent((
            family,
            text,
          ), () => (width as num).toDouble());
        }
      }
      _saved = QuranWord.measured.length;
    } catch (_) {
      prefs.remove(_key);
    }
  }

  /// Keeps what has been measured since the last save.
  static void save() {
    final prefs = _prefs;
    if (prefs == null || QuranWord.measured.length == _saved) return;
    final families = <String, Map<String, double>>{};
    for (final MapEntry(key: (family, text), value: width)
        in QuranWord.measured.entries) {
      if (family != null) (families[family] ??= {})[text] = width;
    }
    prefs.setString(_key, jsonEncode({'build': _build, 'widths': families}));
    _saved = QuranWord.measured.length;
  }

  /// Measures every word in [typeface] that hasn't been, starting at word
  /// [from] and working outwards, in idle moments. Replaces any earlier run.
  static void warm(QuranDb db, QuranTypeface typeface, int from) {
    if (!kIsWeb) return;
    final run = _run = Object();
    // Only the family and size matter to widthOf.
    final style = TextStyle(fontFamily: typeface.fontFamily, fontSize: 100);
    final last = db.wordCount;
    var below = from; // next words to read end before this id
    var above = from; // and start at this one
    var up = true;
    final pending = <Word>[];

    void step() {
      if (_run != run) return;
      final clock = Stopwatch()..start();
      while (clock.elapsed < _slice) {
        if (pending.isEmpty) {
          final canUp = above <= last, canDown = below > 1;
          if (!canUp && !canDown) {
            _run = null;
            save();
            return;
          }
          if (canUp && (up || !canDown)) {
            final to = (above + _chunk - 1).clamp(1, last);
            pending.addAll(db.wordsBetween(above, to, typeface).reversed);
            above = to + 1;
          } else {
            final to = below - 1, start = (below - _chunk).clamp(1, to);
            pending.addAll(db.wordsBetween(start, to, typeface));
            below = start;
          }
          up = !up;
          continue;
        }
        QuranWord.widthOf(pending.removeLast(), typeface, style);
      }
      SchedulerBinding.instance.scheduleTask(step, Priority.idle);
    }

    SchedulerBinding.instance.scheduleTask(step, Priority.idle);
  }

  /// Stops measuring (Easy read no longer in use).
  static void stop() => _run = null;
}
