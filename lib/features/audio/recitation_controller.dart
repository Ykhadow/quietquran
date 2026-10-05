import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/settings.dart';
import '../../data/quran_db.dart';
import '../../data/recitation.dart';

/// What the recitation is doing, for the reader and its controls.
class RecitationState {
  const RecitationState({
    this.active = false,
    this.playing = false,
    this.loading = false,
    this.failed = false,
    this.surah = 0,
    this.ayah = 0,
    this.part = AudioPart.recitation,
    this.progress = 0,
    this.round = 1,
    this.rounds = 1,
  });

  /// A recitation is under way (playing or paused).
  final bool active;
  final bool playing;

  /// Waiting for audio to arrive.
  final bool loading;

  /// The audio couldn't be fetched (most often, no connection).
  final bool failed;

  /// The ayah being heard; ayah 0 is the Bismillah before a surah.
  final int surah;
  final int ayah;
  final AudioPart part;

  /// How far through the current file, from 0 to 1.
  final double progress;

  /// Which time round an ayah set to repeat is on, of [rounds].
  final int round;
  final int rounds;

  /// The ayah to highlight and follow, or null.
  (int, int)? get current => active && ayah > 0 ? (surah, ayah) : null;

  RecitationState copyWith({
    bool? active,
    bool? playing,
    bool? loading,
    bool? failed,
    int? surah,
    int? ayah,
    AudioPart? part,
    double? progress,
    int? round,
    int? rounds,
  }) => RecitationState(
    active: active ?? this.active,
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    part: part ?? this.part,
    progress: progress ?? this.progress,
    round: round ?? this.round,
    rounds: rounds ?? this.rounds,
  );
}

/// Labels for the system's media controls (notification, lock screen).
typedef NowPlaying = ({String title, String subtitle});

/// Plays a queue of ayah files. [JustAudioBackend] on devices; tests use
/// their own.
abstract class RecitationBackend {
  /// The index in the loaded queue now playing.
  Stream<int?> get index;
  Stream<bool> get playing;
  Stream<bool> get loading;

  /// How far through the current item, from 0 to 1.
  Stream<double> get progress;

  /// Which time round the current item is on (see AudioItem.times).
  Stream<int> get round;

  /// The whole queue has played.
  Stream<void> get completed;
  Stream<Object> get errors;

  Future<void> load(List<AudioItem> items, List<NowPlaying> labels);
  void play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(int index);
  Future<void> dispose();
}

/// Creates the player when a recitation first starts (so merely opening the
/// reader never touches the platform's audio).
final recitationBackendProvider = Provider<RecitationBackend Function()>(
  (ref) => JustAudioBackend.new,
);

final recitationProvider =
    NotifierProvider<RecitationController, RecitationState>(
      RecitationController.new,
    );

/// Plays from an ayah to the end of its surah, then on into the next.
class RecitationController extends Notifier<RecitationState> {
  RecitationBackend? _backend;
  final _subscriptions = <StreamSubscription<Object?>>[];
  List<AudioItem> _queue = const [];
  int? _index;
  String _language = 'en';

  /// Bumped by every new queue, so a slow load that has been replaced
  /// doesn't start playing.
  int _generation = 0;

  @override
  RecitationState build() {
    ref.onDispose(() {
      for (final s in _subscriptions) {
        s.cancel();
      }
      _backend?.dispose();
    });
    // A new reciter, voice or repeat count carries on from the same ayah.
    ref.listen(
      settingsProvider.select(
        (s) => (s.reciter, s.translationShown, s.ayahRepeat, s.translation),
      ),
      (_, _) {
        if (state.active) {
          _start(
            state.surah,
            state.ayah < 1 ? 1 : state.ayah,
            play: state.playing,
          );
        }
      },
    );
    return const RecitationState();
  }

  RecitationBackend get _player {
    if (_backend != null) return _backend!;
    final b = _backend = ref.read(recitationBackendProvider)();
    _subscriptions.addAll([
      b.index.listen(_onIndex),
      b.playing.listen((v) {
        if (state.active) state = state.copyWith(playing: v);
      }),
      b.loading.listen((v) {
        if (state.active) state = state.copyWith(loading: v);
      }),
      b.progress.listen((v) {
        if (state.active) state = state.copyWith(progress: v);
      }),
      b.round.listen((v) {
        if (state.active) state = state.copyWith(round: v);
      }),
      b.completed.listen((_) => _onCompleted()),
      b.errors.listen((_) {
        if (state.active) {
          state = state.copyWith(failed: true, playing: false, loading: false);
        }
      }),
    ]);
    return b;
  }

  /// Starts reciting at [surah]:[ayah]. [language] is the app's language
  /// code, which picks the translation (and so its voice).
  Future<void> playFrom(int surah, int ayah, {required String language}) {
    _language = language;
    return _start(surah, ayah, play: true);
  }

  Future<void> _start(int surah, int ayah, {required bool play}) async {
    final settings = ref.read(settingsProvider);
    final db = ref.read(quranDbProvider);
    final reciter = Reciter.byId(settings.reciter);
    // The translation is read when it is shown (see translationShown).
    final voice = settings.translationShown
        ? TranslationVoice.forTranslation(settings.translationFor(_language))
        : null;
    final queue = surahQueue(
      reciter: reciter,
      surah: surah,
      fromAyah: ayah,
      ayahCount: db.surah(surah).versesCount,
      voice: voice,
      repeat: settings.ayahRepeat,
    );
    final generation = ++_generation;
    _queue = queue;
    _index = 0;
    final first = queue.first;
    state = RecitationState(
      active: true,
      playing: play,
      loading: true,
      surah: first.surah,
      ayah: first.ayah,
      part: first.part,
      rounds: first.times,
    );
    final name = db.surah(surah).nameSimple;
    final labels = [
      for (final item in queue)
        (
          title: item.ayah == 0 ? name : '$name ${item.surah}:${item.ayah}',
          subtitle: item.part == AudioPart.translation
              ? voice!.name
              : reciter.name,
        ),
    ];
    try {
      await _player.load(queue, labels);
      if (generation != _generation) return;
      if (play) _player.play();
    } on Object {
      if (generation != _generation) return;
      state = state.copyWith(failed: true, playing: false, loading: false);
    }
  }

  void _onIndex(int? i) {
    if (i == null || i >= _queue.length || !state.active) return;
    _index = i;
    final item = _queue[i];
    state = state.copyWith(
      surah: item.surah,
      ayah: item.ayah,
      part: item.part,
      failed: false,
      progress: 0,
      round: 1,
      rounds: item.times,
    );
  }

  void _onCompleted() {
    if (!state.active) return;
    final surah = _queue.isEmpty ? state.surah : _queue.last.surah;
    if (surah < 114) {
      _start(surah + 1, 1, play: true);
    } else {
      stop();
    }
  }

  void toggle() => state.playing ? pause() : resume();

  Future<void> pause() async {
    state = state.copyWith(playing: false);
    await _backend?.pause();
  }

  void resume() {
    if (!state.active) return;
    if (state.failed) {
      // Try again from the ayah that failed.
      _start(state.surah, state.ayah < 1 ? 1 : state.ayah, play: true);
      return;
    }
    state = state.copyWith(playing: true);
    _backend?.play();
  }

  /// To the next ayah (its first recitation), or the next surah.
  Future<void> next() async {
    if (!state.active) return;
    final from = _index ?? 0;
    for (var j = from + 1; j < _queue.length; j++) {
      if (_queue[j].ayah != _queue[from].ayah) {
        return _seek(j);
      }
    }
    if (state.surah < 114) await _start(state.surah + 1, 1, play: true);
  }

  /// To the previous ayah; from the Bismillah or a surah's first ayah, to
  /// the last ayah of the surah before.
  Future<void> previous() async {
    if (!state.active) return;
    final ayah = state.ayah;
    if (ayah > 1) {
      final target = ayah - 1;
      final j = _queue.indexWhere((i) => i.ayah == target);
      if (j >= 0) return _seek(j);
      return _start(state.surah, target, play: true);
    }
    if (state.surah > 1) {
      final before = state.surah - 1;
      final count = ref.read(quranDbProvider).surah(before).versesCount;
      return _start(before, count, play: true);
    }
  }

  Future<void> _seek(int j) async {
    _onIndex(j);
    await _backend?.seek(j);
    if (!state.playing) resume();
  }

  Future<void> stop() async {
    _generation++;
    _queue = const [];
    _index = null;
    state = const RecitationState();
    await _backend?.stop();
  }
}

/// just_audio, with each ayah saved as it streams (to the folder offline
/// downloads will use), so it never downloads twice.
class JustAudioBackend implements RecitationBackend {
  JustAudioBackend() {
    // An item asked to play more than once loops; on its last time round
    // the loop is lifted, so it then moves on. The player re-announces the
    // same index whenever its loop mode changes, so only a new index counts:
    // answering every announcement would set the mode again, and again.
    index.listen((i) {
      _setPlays(1);
      _loopFor(i);
    });
    _player.positionDiscontinuityStream.listen((d) {
      if (d.reason != PositionDiscontinuityReason.autoAdvance ||
          d.previousEvent.currentIndex != d.event.currentIndex) {
        return;
      }
      _setPlays(_plays + 1);
      _loopFor(d.event.currentIndex);
    });
  }

  final _player = AudioPlayer();
  Future<Directory>? _dir;

  /// Windows won't let a file still open for playing be renamed, which is
  /// how just_audio finishes saving an ayah, so there it simply streams.
  static final _saveAsItStreams = !Platform.isWindows;
  List<AudioItem> _items = const [];

  /// Times the current item has started playing.
  int _plays = 1;
  final _round = StreamController<int>.broadcast();

  void _setPlays(int n) {
    _plays = n;
    _round.add(n);
  }

  void _loopFor(int? i) {
    final times = i != null && i < _items.length ? _items[i].times : 1;
    final mode = _plays < times ? LoopMode.one : LoopMode.off;
    if (_player.loopMode != mode) _player.setLoopMode(mode);
  }

  @override
  Stream<int?> get index => _player.currentIndexStream.distinct();

  @override
  Stream<bool> get playing => _player.playingStream;

  @override
  Stream<bool> get loading => _player.processingStateStream
      .map(
        (s) => s == ProcessingState.loading || s == ProcessingState.buffering,
      )
      .distinct();

  @override
  Stream<double> get progress => _player.positionStream.map((p) {
    final d = _player.duration;
    if (d == null || d == Duration.zero) return 0.0;
    return (p.inMilliseconds / d.inMilliseconds).clamp(0.0, 1.0);
  });

  @override
  Stream<int> get round => _round.stream;

  @override
  Stream<void> get completed => _player.processingStateStream.where(
    (s) => s == ProcessingState.completed,
  );

  @override
  Stream<Object> get errors => _player.errorStream;

  /// Where ayah files are kept: `<app support>/audio/<folder>/<sssaaa>.mp3`.
  static Future<Directory> audioDirectory() async =>
      Directory(p.join((await getApplicationSupportDirectory()).path, 'audio'));

  /// The picture the phone's player (notification, lock screen) shows and
  /// takes its colours from: the app's terracotta. Copied from the app's
  /// assets to a file the player can open, afresh each time the app runs
  /// (it's small), so a new picture in an update replaces the old.
  static Future<Uri>? _art;

  static Future<Uri> _artwork() async {
    final file = File(
      p.join((await getApplicationSupportDirectory()).path, 'now_playing.png'),
    );
    final data = await rootBundle.load('assets/brand/now_playing.png');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return file.uri;
  }

  @override
  Future<void> load(List<AudioItem> items, List<NowPlaying> labels) async {
    final root = await (_dir ??= audioDirectory());
    final art = await (_art ??= _artwork());
    for (final folder in {for (final i in items) i.folder}) {
      await Directory(p.join(root.path, folder)).create(recursive: true);
    }
    final sources = <AudioSource>[];
    for (var n = 0; n < items.length; n++) {
      final item = items[n];
      final tag = MediaItem(
        id: '${item.folder}/${item.fileName}#$n',
        title: labels[n].title,
        artist: labels[n].subtitle,
        album: 'Quiet Quran',
        artUri: art,
      );
      final file = File(p.join(root.path, item.folder, item.fileName));
      sources.add(
        file.existsSync()
            ? AudioSource.file(file.path, tag: tag)
            : _saveAsItStreams
            // Marked experimental, but long stable; it streams and saves
            // in one download.
            // ignore: experimental_member_use
            ? LockCachingAudioSource(item.url, cacheFile: file, tag: tag)
            : AudioSource.uri(item.url, tag: tag),
      );
    }
    _items = items;
    _setPlays(1);
    await _player.setAudioSources(sources, initialIndex: 0);
    _loopFor(0);
  }

  @override
  void play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(int index) async {
    // Moving to an ayah (even the same one) starts its count afresh.
    _setPlays(1);
    await _player.seek(Duration.zero, index: index);
    _loopFor(index);
  }

  @override
  Future<void> dispose() async {
    await _round.close();
    await _player.dispose();
  }
}
