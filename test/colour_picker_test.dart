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

  testWidgets('the honeycomb: white at the centre, vivid hues at the edge, '
      'the same colour for the same cell', (tester) async {
    final picked = await pump(tester, const Color(0xFFA9532F));
    final comb = find.byWidgetPredicate(
      (w) => w is CustomPaint && '${w.painter.runtimeType}' == '_CombPainter',
    );
    final box = tester.getRect(comb);
    // The centre cell is white (brightness starts at the colour's own).
    await tester.tapAt(box.center);
    final centre = HSVColor.fromColor(picked.last);
    expect(centre.saturation, 0);
    // A cell at the edge is fully vivid.
    await tester.tapAt(box.centerLeft + const Offset(8, 0));
    expect(HSVColor.fromColor(picked.last).saturation, closeTo(1, 0.01));
    // The same cell twice gives the same colour.
    final spot = box.center + Offset(box.width / 5, -box.height / 6);
    await tester.tapAt(spot);
    final first = picked.last;
    await tester.tapAt(box.center);
    await tester.tapAt(spot);
    expect(picked.last, first);
  });

  testWidgets('brightness darkens the colour; the grey row gives greys', (
    tester,
  ) async {
    final picked = await pump(tester, const Color(0xFFA9532F));
    await tester.drag(find.byType(Slider), const Offset(-400, 0));
    await tester.pump();
    expect(HSVColor.fromColor(picked.last).value, lessThan(0.1));
    final greys = find.byWidgetPredicate(
      (w) => w is CustomPaint && '${w.painter.runtimeType}' == '_GreyCell',
    );
    expect(greys, findsNWidgets(11));
    await tester.tap(greys.first);
    expect(picked.last.toARGB32(), 0xFFFFFFFF);
    await tester.tap(greys.last);
    expect(picked.last.toARGB32(), 0xFF000000);
  });
}
