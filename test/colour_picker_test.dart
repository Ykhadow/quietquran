import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/theme.dart';
import 'package:mushaf15/l10n/l10n.dart';
import 'package:mushaf15/widgets/colour_picker.dart';

void main() {
  Future<List<Color>> pump(WidgetTester tester, Color start) async {
    final picked = <Color>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Palette.day),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: ColourPicker(color: start, onChanged: picked.add),
          ),
        ),
      ),
    );
    return picked;
  }

  testWidgets('a hex code sets that exact colour', (tester) async {
    final picked = await pump(tester, const Color(0xFF151614));
    expect(find.text('151614'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'efe3cb');
    expect(picked.last.toARGB32(), 0xFFEFE3CB);
  });

  testWidgets('the rainbow picks by position, the same way each time', (
    tester,
  ) async {
    final picked = await pump(tester, const Color(0xFF151614));
    final rainbow = find.byWidgetPredicate(
      (w) => w is CustomPaint && '${w.painter.runtimeType}' == '_Rainbow',
    );
    final box = tester.getRect(rainbow);
    // Top edge: white; bottom edge: black; a spot twice: the same colour.
    await tester.tapAt(box.topLeft + const Offset(40, 0.5));
    expect(HSLColor.fromColor(picked.last).lightness, closeTo(1, 0.01));
    await tester.tapAt(box.bottomLeft + const Offset(40, -0.5));
    expect(HSLColor.fromColor(picked.last).lightness, closeTo(0, 0.01));
    final spot = box.center + const Offset(-30, 20);
    await tester.tapAt(spot);
    final first = picked.last;
    await tester.tapAt(box.topLeft + const Offset(5, 5));
    await tester.tapAt(spot);
    expect(picked.last, first);
  });
}
