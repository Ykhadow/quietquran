// Recitation: what plays in what order (the Bismillah, repeats, the
// translation's voice), the controller moving through it, and the reader
// following the ayah being heard. A fake player stands in for the device's.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/core/theme.dart';
import 'package:mushaf15/data/library.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/data/recitation.dart';
import 'package:mushaf15/features/audio/recitation_controller.dart';
import 'package:mushaf15/features/audio/recitation_widgets.dart';
import 'package:mushaf15/features/reader/page_snapshot.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/l10n/app_localizations.dart';
import 'package:mushaf15/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePlayer implements RecitationBackend {
  final _index = StreamController<int?>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _loading = StreamController<bool>.broadcast();
  final _completed = StreamController<void>.broadcast();
  final _progress = StreamController<double>.broadcast();
  final _round = StreamController<int>.broadcast();
  final _errors = StreamController<Object>.broadcast();

  List<AudioItem> loaded = const [];
  List<NowPlaying> labels = const [];
  int loads = 0;
  int? seekedTo;
  bool isPlaying = false;

  @override
  Stream<int?> get index => _index.stream;
  @override
  Stream<bool> get playing => _playing.stream;
  @override
  Stream<bool> get loading => _loading.stream;
  @override
  Stream<void> get completed => _completed.stream;
  @override
  Stream<double> get progress => _progress.stream;
  @override
  Stream<int> get round => _round.stream;

  void advance(double v) => _progress.add(v);
  void repeatRound(int n) => _round.add(n);
  void buffer(bool v) => _loading.add(v);
  @override
  Stream<Object> get errors => _errors.stream;

  @override
  Future<void> load(List<AudioItem> items, List<NowPlaying> labels) async {
    loads++;
    loaded = items;
    this.labels = labels;
    _loading.add(false); // ready at once
  }

  @override
  void play() => isPlaying = true;
  @override
  Future<void> pause() async => isPlaying = false;
  @override
  Future<void> stop() async => isPlaying = false;
  @override
  Future<void> seek(int index) async => seekedTo = index;
  @override
  Future<void> dispose() async {}

  /// The player reaching item [i].
  void reach(int i) => _index.add(i);
  void finish() => _completed.add(null);
  void fail() => _errors.add(Exception('offline'));
}

void main() {
  late QuranDb db;

  setUpAll(() {
    ShapePrefetcher.enabled = false;
    PageSnapshots.enabled = false;
    db = QuranDb.openFile('assets/db/quran.db');
  });

  final alafasy = Reciter.byId('alafasy');
  final urdu = TranslationVoice.forTranslation('ur-jalandhari')!;

  group('the queue', () {
    test('a surah opens with its Bismillah, from Al-Fatihah 1:1', () {
      final q = surahQueue(
        reciter: alafasy,
        surah: 67,
        fromAyah: 1,
        ayahCount: 30,
      );
      expect(q.first.bismillah, isTrue);
      expect(
        q.first.url.toString(),
        'https://everyayah.com/data/Alafasy_128kbps/001001.mp3',
      );
      expect((q.first.surah, q.first.ayah), (67, 0));
      expect(
        q[1].url.toString(),
        'https://everyayah.com/data/Alafasy_128kbps/067001.mp3',
      );
      expect(q.length, 31);
    });

    test('but not Al-Fatihah (its first ayah) or At-Tawbah (none)', () {
      for (final (surah, count) in [(1, 7), (9, 129)]) {
        final q = surahQueue(
          reciter: alafasy,
          surah: surah,
          fromAyah: 1,
          ayahCount: count,
        );
        expect(q.any((i) => i.bismillah), isFalse);
        expect((q.first.surah, q.first.ayah), (surah, 1));
        expect(q.length, count);
      }
    });

    test('starting mid-surah, no Bismillah', () {
      final q = surahQueue(
        reciter: alafasy,
        surah: 2,
        fromAyah: 255,
        ayahCount: 286,
      );
      expect((q.first.surah, q.first.ayah), (2, 255));
      expect(q.length, 32);
    });

    test('repeats loop the ayah; its translation follows once', () {
      final q = surahQueue(
        reciter: alafasy,
        surah: 114,
        fromAyah: 5,
        ayahCount: 6,
        voice: urdu,
        repeat: 2,
      );
      expect(q.map((i) => '${i.part.name} ${i.ayah} ×${i.times}').toList(), [
        'recitation 5 ×2',
        'translation 5 ×1',
        'recitation 6 ×2',
        'translation 6 ×1',
      ]);
      expect(
        q[1].url.toString(),
        'https://everyayah.com/data/translations/'
        'urdu_shamshad_ali_khan_46kbps/114005.mp3',
      );
    });

    test('the Bismillah is heard once, then its translation', () {
      final q = surahQueue(
        reciter: alafasy,
        surah: 112,
        fromAyah: 1,
        ayahCount: 4,
        voice: urdu,
        repeat: 3,
      );
      expect(
        q.take(3).map((i) => (i.part, i.bismillah, i.file, i.times)).toList(),
        [
          (AudioPart.recitation, true, (1, 1), 1),
          (AudioPart.translation, true, (1, 1), 1),
          (AudioPart.recitation, false, (112, 1), 3),
        ],
      );
    });

    test('however many repeats, one item per ayah', () {
      final q = surahQueue(
        reciter: alafasy,
        surah: 2,
        fromAyah: 1,
        ayahCount: 286,
        repeat: 40,
      );
      expect(q.length, 287);
    });
  });

  group('the controller', () {
    late FakePlayer player;
    late ProviderContainer c;

    Future<void> setUpContainer([Map<String, Object> prefs = const {}]) async {
      SharedPreferences.setMockInitialValues(prefs);
      final p = await SharedPreferences.getInstance();
      player = FakePlayer();
      c = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(p),
          quranDbProvider.overrideWithValue(db),
          recitationBackendProvider.overrideWithValue(() => player),
        ],
      );
      addTearDown(c.dispose);
      c.listen(recitationProvider, (_, _) {});
    }

    RecitationState state() => c.read(recitationProvider);
    RecitationController ctl() => c.read(recitationProvider.notifier);

    test('plays from an ayah, and follows the player', () async {
      await setUpContainer();
      await ctl().playFrom(67, 1, language: 'en');
      expect(player.isPlaying, isTrue);
      expect(state().active, isTrue);
      expect(state().current, isNull); // the Bismillah
      player.reach(1);
      await pumpEventQueue();
      expect(state().current, (67, 1));
      expect(player.labels[1].title, 'Al-Mulk 67:1');
      expect(player.labels[1].subtitle, 'Mishary Rashid Alafasy');
    });

    test('next and previous move by ayah', () async {
      await setUpContainer({'ayahRepeat': 2});
      await ctl().playFrom(2, 255, language: 'en');
      await ctl().next();
      expect(player.seekedTo, 1); // 255 (looped twice), then 256
      expect(state().current, (2, 256));
      await ctl().previous();
      expect(player.seekedTo, 0);
      expect(state().current, (2, 255));
      // Before the first ayah queued: a new queue from the one before.
      await ctl().previous();
      expect(player.loaded.first.ayah, 254);
    });

    test('at the end of a surah, on into the next', () async {
      await setUpContainer();
      await ctl().playFrom(1, 7, language: 'en');
      player.finish();
      await pumpEventQueue();
      expect(player.loads, 2);
      expect(player.loaded.first.bismillah, isTrue);
      expect(player.loaded[1].surah, 2);
    });

    test('the translation follows when asked, in the app language', () async {
      await setUpContainer({'reflowTranslation': true});
      await ctl().playFrom(1, 1, language: 'ur');
      expect(player.loaded.take(2).map((i) => i.folder), [
        'Alafasy_128kbps',
        'translations/urdu_shamshad_ali_khan_46kbps',
      ]);
      // Arabic shows no translation, so none is read.
      await ctl().playFrom(1, 1, language: 'ar');
      expect(
        player.loaded.every((i) => i.part == AudioPart.recitation),
        isTrue,
      );
    });

    test('the translation is read only when it is shown', () async {
      await setUpContainer({'reflowTranslation': true});
      Future<List<AudioPart>> parts() async {
        await ctl().playFrom(1, 1, language: 'en');
        return [for (final i in player.loaded) i.part];
      }

      expect(await parts(), contains(AudioPart.translation));
      // Hidden: not read.
      c.read(settingsProvider.notifier).setReflowTranslation(false);
      expect(await parts(), isNot(contains(AudioPart.translation)));
      // Shown, but on the Mushaf page (no translation there): not read.
      c.read(settingsProvider.notifier)
        ..setReflowTranslation(true)
        ..setTextLayout(TextLayout.mushaf);
      expect(await parts(), isNot(contains(AudioPart.translation)));
    });

    test('changing reciter carries on from the same ayah', () async {
      await setUpContainer();
      await ctl().playFrom(36, 1, language: 'en');
      player.reach(5); // 36:5
      await pumpEventQueue();
      c.read(settingsProvider.notifier).setReciter('husary');
      await pumpEventQueue();
      expect(player.loaded.first.folder, 'Husary_128kbps');
      expect((player.loaded.first.surah, player.loaded.first.ayah), (36, 5));
    });

    test('a failure is shown, and trying again reloads', () async {
      await setUpContainer();
      await ctl().playFrom(55, 13, language: 'en');
      player.fail();
      await pumpEventQueue();
      expect(state().failed, isTrue);
      expect(state().playing, isFalse);
      ctl().resume();
      await pumpEventQueue();
      expect(player.loads, 2);
      expect(state().failed, isFalse);
      expect(player.loaded.first.ayah, 13);
    });

    test('stop ends it', () async {
      await setUpContainer();
      await ctl().playFrom(1, 1, language: 'en');
      await ctl().stop();
      expect(state().active, isFalse);
      expect(player.isPlaying, isFalse);
    });
  });

  testWidgets('a number of repeats of the reader’s own', (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'en'});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        quranDbProvider.overrideWithValue(db),
      ],
    );
    addTearDown(c.dispose);
    tester.view.physicalSize = const Size(411, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: themeFor(Palette.day),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SingleChildScrollView(child: RecitationOptions()),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '20');
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).ayahRepeat, 21);
    // The custom choice now shows its number.
    expect(find.text('21×'), findsOneWidget);
  });

  testWidgets('the reader: listen, the player shows, pages follow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'language': 'en',
      'textLayout': 'mushaf',
    });
    final prefs = await SharedPreferences.getInstance();
    final player = FakePlayer();
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        quranDbProvider.overrideWithValue(db),
        recitationBackendProvider.overrideWithValue(() => player),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MushafApp()),
    );
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Show the overlay, then listen from the page (Al-Fatihah).
    await tester.tapAt(const Offset(205, 430));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(ListenButton));
    await tester.pump();
    expect(player.loaded.first.file, (1, 1));
    expect(find.byType(RecitationBar), findsOneWidget);

    // Al-Fatihah ends; Al-Baqarah begins on the next page.
    player.finish();
    await tester.pump();
    player.reach(1); // 2:1, after its Bismillah
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // the page turns
    expect(find.text('Al-Baqarah 2:1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2)); // the save
    final s = c.read(libraryProvider).session(Session.dailyId);
    expect(db.pageOfAyah('indopak-15-qudratullah', s.surah, s.ayah), 2);

    // Stop: the player goes.
    await tester.tap(find.byTooltip('Stop'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // it slides away
    expect(find.text('Al-Baqarah 2:1'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  for (final layout in ['reflow', 'mushaf']) {
    testWidgets('$layout: hold an ayah, then Listen', (tester) async {
      tester.view.physicalSize = const Size(411, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'onboarded': true,
        'language': 'en',
        'textLayout': layout,
      });
      final prefs = await SharedPreferences.getInstance();
      final player = FakePlayer();
      final c = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          quranDbProvider.overrideWithValue(db),
          recitationBackendProvider.overrideWithValue(() => player),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const MushafApp()),
      );
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // A word of the page's last ayah.
      (int, int, Offset)? word;
      for (final r in tester.allRenderObjects.whereType<RenderCustomPaint>()) {
        final painter = r.painter;
        if (painter is! QuranLinePainter || !r.attached) continue;
        final origin = r.localToGlobal(Offset.zero);
        for (final (w, rect) in painter.place(r.size).$1) {
          final centre = rect.shift(origin).center;
          if (!w.isAyahEnd &&
              centre.dx > 20 &&
              centre.dx < 390 &&
              centre.dy > 100 &&
              centre.dy < 760) {
            word = (w.surah, w.ayah, centre);
          }
        }
      }
      final (surah, ayah, at) = word!;
      await tester.longPressAt(at);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      debugPrint(
        'TEXTS: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).where((d) => d != null).join(" | ")}',
      );
      await tester.tap(find.text('Listen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(
        (player.loaded.first.surah, player.loaded.first.ayah),
        (surah, ayah),
      );
      expect(player.isPlaying, isTrue);
      expect(find.byType(RecitationBar), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
