import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:mushaf15/data/page_images.dart';
import 'package:mushaf15/data/updates.dart';

/// Turns Flutter's leak tracker on for the test suite, ignoring everything by
/// default; tests that check for leaks (test/leak_test.dart) opt in with
/// `experimentalLeakTesting`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Tests have no platform downloader.
  PageImageStore.backgroundDownloads = false;
  UpdateChecker.enabled = false;
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings.withIgnoredAll();
  await testMain();
}
