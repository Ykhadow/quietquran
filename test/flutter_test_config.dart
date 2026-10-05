import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Turns Flutter's leak tracker on for the test suite, ignoring everything by
/// default; tests that check for leaks (test/leak_test.dart) opt in with
/// `experimentalLeakTesting`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings.withIgnoredAll();
  await testMain();
}
