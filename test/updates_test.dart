// The website/GitHub builds offer a newer version only when there is one,
// not again after "Later", and never with the check turned off. (No network
// here: the latest answer is already saved, checked just now.)
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf15/core/settings.dart';
import 'package:mushaf15/data/updates.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('versions compare part by part', () {
    expect(isNewer('1.0.1', '1.0.0'), isTrue);
    expect(isNewer('1.0.10', '1.0.9'), isTrue);
    expect(isNewer('1.1', '1.0.9'), isTrue);
    expect(isNewer('1.0.0', '1.0.0'), isFalse);
    expect(isNewer('1.0.0', '1.0.1'), isFalse);
    expect(isNewer('2.0.0', '0'), isTrue);
  });

  Future<ProviderContainer> start({
    required int latest,
    int installed = 5,
    bool check = true,
    int? later,
  }) async {
    PackageInfo.setMockInitialValues(
      appName: 'Quiet Quran',
      packageName: 'com.quietquran.app',
      version: '1.0.$installed',
      // Split APKs carry the processor in the version code (2000 + build).
      buildNumber: '${2000 + installed}',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'checkUpdates': check,
      'updateCheckedAt': DateTime.now().millisecondsSinceEpoch,
      'updateLatest': jsonEncode({
        'version': '1.0.$latest',
        'build': latest,
        'page': 'https://example.com/v$latest',
        'android': {'arm64': 'https://example.com/a.apk'},
      }),
      'updateLaterVersion': ?(later == null ? null : '1.0.$later'),
    });
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(await SharedPreferences.getInstance()),
      ],
    );
    addTearDown(c.dispose);
    UpdateChecker.enabled = true;
    addTearDown(() => UpdateChecker.enabled = false);
    await c.read(updateProvider.notifier).checkDaily();
    return c;
  }

  test('a newer version is offered', () async {
    final c = await start(latest: 6);
    expect(c.read(updateProvider).stage, UpdateStage.available);
    expect(c.read(updateProvider).update!.version, '1.0.6');
  }, skip: !UpdateChecker.supported);

  test('the same or an older version is not', () async {
    expect(
      (await start(latest: 5)).read(updateProvider).stage,
      UpdateStage.none,
    );
    expect(
      (await start(latest: 4)).read(updateProvider).stage,
      UpdateStage.none,
    );
  }, skip: !UpdateChecker.supported);

  test('"Later" hides that version until a newer one', () async {
    final c = await start(latest: 6);
    c.read(updateProvider.notifier).later();
    expect(c.read(updateProvider).stage, UpdateStage.none);
    expect(
      (await start(latest: 6, later: 6)).read(updateProvider).stage,
      UpdateStage.none,
    );
    expect(
      (await start(latest: 7, later: 6)).read(updateProvider).stage,
      UpdateStage.available,
    );
  }, skip: !UpdateChecker.supported);

  test('nothing with the check turned off', () async {
    expect(
      (await start(latest: 9, check: false)).read(updateProvider).stage,
      UpdateStage.none,
    );
  }, skip: !UpdateChecker.supported);
}
