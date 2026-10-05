// Recitation on a real device, with the real player and EveryAyah's audio
// (needs a connection): hold an ayah, Listen, and it is heard and moves on.
//
//   flutter test integration_test/recitation_live_test.dart -d windows
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/data/quran_db.dart';
import 'package:mushaf15/features/audio/recitation_controller.dart';
import 'package:mushaf15/features/reader/quran_line.dart';
import 'package:mushaf15/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final repeat in [1, 2]) {
    testWidgets('hold an ayah, Listen: it plays and moves on (×$repeat)', (
      tester,
    ) async {
      JustAudioMediaKit.ensureInitialized();
      // The reader's own settings on this computer are left alone.
      SharedPreferences.setMockInitialValues({
        'onboarded': true,
        'language': 'en',
        'textLayout': 'reflow',
        'reflowTranslation': true,
        'ayahRepeat': repeat,
      });
      final prefs = await SharedPreferences.getInstance();
      final db = await QuranDb.open();
      final c = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          quranDbProvider.overrideWithValue(db),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const MushafApp()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      // Hold a word of Al-Fatihah 1:2 on the screen.
      Offset? at;
      final size = tester.view.physicalSize / tester.view.devicePixelRatio;
      for (final r in tester.allRenderObjects.whereType<RenderCustomPaint>()) {
        final painter = r.painter;
        if (painter is! QuranLinePainter || !r.attached) continue;
        final origin = r.localToGlobal(Offset.zero);
        for (final (w, rect) in painter.place(r.size).$1) {
          final centre = rect.shift(origin).center;
          if (w.surah == 1 &&
              w.ayah == 2 &&
              !w.isAyahEnd &&
              centre.dx > 0 &&
              centre.dx < size.width) {
            at ??= centre;
          }
        }
      }
      await tester.longPressAt(at!);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Listen'));

      // Heard, and on to the next ayah within half a minute.
      RecitationState s() => c.read(recitationProvider);
      var heard = false;
      for (var i = 0; i < 300 && s().ayah < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (s().playing && !s().loading) heard = true;
        expect(s().failed, isFalse, reason: 'the audio failed to load');
      }
      debugPrint(
        'state: active=${s().active} playing=${s().playing} '
        'loading=${s().loading} ${s().surah}:${s().ayah} ${s().part}',
      );
      expect(heard, isTrue);
      expect(s().ayah, greaterThanOrEqualTo(3));

      await c.read(recitationProvider.notifier).stop();
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
