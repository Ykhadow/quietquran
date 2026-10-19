// The reader's translation button: on a Mushaf or printed page it opens
// Easy read with the translation, and tapping it again goes back there.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> start(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues({'onboarded': true, ...prefs});
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(await SharedPreferences.getInstance()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('from a Mushaf page, and back', () async {
    final c = await start({'mode': 'text', 'textLayout': 'mushaf'});
    final n = c.read(settingsProvider.notifier);
    n.showTranslationView();
    var s = c.read(settingsProvider);
    expect(
      (s.mode, s.textLayout, s.reflowTranslation),
      (ReadingMode.text, TextLayout.reflow, true),
    );
    n.hideTranslationView();
    s = c.read(settingsProvider);
    expect(
      (s.textLayout, s.reflowTranslation, s.translationReturn),
      (TextLayout.mushaf, false, ''),
    );
  });

  test('from a printed page, and back', () async {
    final c = await start({'mode': 'pages'});
    final n = c.read(settingsProvider.notifier);
    n.showTranslationView();
    expect(c.read(settingsProvider).mode, ReadingMode.text);
    n.hideTranslationView();
    expect(c.read(settingsProvider).mode, ReadingMode.pages);
  });

  test('already in Easy read: just hides the translation', () async {
    final c = await start({'mode': 'text', 'textLayout': 'reflow'});
    final n = c.read(settingsProvider.notifier);
    n.showTranslationView();
    n.hideTranslationView();
    final s = c.read(settingsProvider);
    expect(
      (s.mode, s.textLayout, s.reflowTranslation),
      (ReadingMode.text, TextLayout.reflow, false),
    );
  });

  test('changing the view by hand forgets where it came from', () async {
    final c = await start({'mode': 'text', 'textLayout': 'mushaf'});
    final n = c.read(settingsProvider.notifier);
    n.showTranslationView();
    n.setTextLayout(TextLayout.reflow);
    n.hideTranslationView();
    expect(c.read(settingsProvider).textLayout, TextLayout.reflow);
  });
}
