import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/settings.dart';

/// A newer version, as listed in quietquran.com/version.json:
///
///     {"version": "1.0.1", "build": 2,
///      "page": "https://github.com/…/releases/tag/v1.0.1",
///      "android": {"arm64": "https://…/QuietQuran-android-arm64.apk",
///                  "arm32": "https://…/QuietQuran-android-arm32.apk"}}
class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.build,
    required this.page,
    required this.android,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> j) => AppUpdate(
    version: j['version'] as String,
    build: j['build'] as int,
    page: j['page'] as String,
    android: {
      for (final e in ((j['android'] as Map?) ?? const {}).entries)
        '${e.key}': '${e.value}',
    },
  );

  final String version;
  final int build;

  /// The release's web page, for desktop downloads.
  final String page;

  /// APK by processor ("arm64", "arm32").
  final Map<String, String> android;
}

enum UpdateStage { none, available, downloading, ready, failed }

class UpdateState {
  const UpdateState({
    this.stage = UpdateStage.none,
    this.update,
    this.progress,
  });

  final UpdateStage stage;
  final AppUpdate? update;

  /// 0-1 while downloading.
  final double? progress;
}

/// Keeps the website/GitHub builds up to date (the Play build is updated by
/// Play, and has none of this). Once a day at most it reads a small public
/// file listing the latest version; the comparison happens on the device,
/// and the request carries nothing about the reader or even which version
/// they have. Android downloads the new APK in the background and opens the
/// system installer (which checks it's signed with the same key); Windows
/// and Linux open the release page.
class UpdateChecker extends Notifier<UpdateState> {
  static const _url = 'https://quietquran.com/version.json';
  static const _checkedAtKey = 'updateCheckedAt';
  static const _latestKey = 'updateLatest';
  static const _laterKey = 'updateLater';

  /// Off in tests.
  static var enabled = true;

  /// Builds that update themselves: Android's "direct" flavour, Windows and
  /// Linux.
  static bool get supported =>
      !kIsWeb &&
      ((Platform.isAndroid && appFlavor == 'direct') ||
          Platform.isWindows ||
          Platform.isLinux);

  @override
  UpdateState build() => const UpdateState();

  /// On launch: shows a newer version already known, and asks again if the
  /// last answer is more than a day old.
  Future<void> checkDaily() async {
    if (!enabled || !supported || !ref.read(settingsProvider).checkUpdates) {
      return;
    }
    final prefs = ref.read(prefsProvider);
    await _offer(prefs.getString(_latestKey));
    final checked = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(_checkedAtKey) ?? 0,
    );
    if (DateTime.now().difference(checked) < const Duration(hours: 20)) {
      return;
    }
    // Offline, or the site is down: try again next launch.
    await _offer(await _fetch());
  }

  /// "Check now" in Settings: asks straight away, and shows a newer version
  /// even if it was put off. True if there is one, false if this is the
  /// latest, null if the check couldn't be made.
  Future<bool?> checkNow() async {
    if (!enabled || !supported) return null;
    final json = await _fetch();
    if (json == null) return null;
    if (state.stage == UpdateStage.none) await _offer(json, putOff: false);
    return state.stage != UpdateStage.none;
  }

  /// The latest version file, saved with the time it was read; null if it
  /// couldn't be read.
  Future<String?> _fetch() async {
    final prefs = ref.read(prefsProvider);
    try {
      final res = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      await prefs.setString(_latestKey, res.body);
      await prefs.setInt(_checkedAtKey, DateTime.now().millisecondsSinceEpoch);
      return res.body;
    } on Object {
      return null;
    }
  }

  /// Shows [json]'s version if it's newer than this one (and, with
  /// [putOff], wasn't put off with "Later").
  Future<void> _offer(String? json, {bool putOff = true}) async {
    if (json == null || state.stage != UpdateStage.none) return;
    final AppUpdate update;
    try {
      update = AppUpdate.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on Object {
      return;
    }
    final installed = int.tryParse(
      (await PackageInfo.fromPlatform()).buildNumber,
    );
    final later = ref.read(prefsProvider).getInt(_laterKey) ?? 0;
    if (installed == null ||
        update.build <= installed ||
        (putOff && update.build <= later)) {
      return;
    }
    state = UpdateState(stage: UpdateStage.available, update: update);
  }

  /// Hides this version until a newer one comes out.
  void later() {
    final u = state.update;
    if (u != null) ref.read(prefsProvider).setInt(_laterKey, u.build);
    state = const UpdateState();
  }

  /// Android: downloads the update in the background (with a notification;
  /// tapping it installs if the app has closed meanwhile), then opens the
  /// installer. Desktop: opens the release page.
  Future<void> update({
    required String downloading,
    required String downloaded,
  }) async {
    final u = state.update;
    if (u == null) return;
    if (!Platform.isAndroid) {
      await launchUrl(Uri.parse(u.page), mode: LaunchMode.externalApplication);
      return;
    }
    // Dart names the processor in its version string: "android_arm64", or
    // "android_arm" on older 32-bit phones.
    final arm32 = Platform.version.contains('"android_arm"');
    final url = u.android[arm32 ? 'arm32' : 'arm64'];
    if (url == null) {
      await launchUrl(Uri.parse(u.page), mode: LaunchMode.externalApplication);
      return;
    }
    final task = DownloadTask(
      taskId: 'update-${u.build}',
      url: url,
      baseDirectory: BaseDirectory.applicationSupport,
      directory: 'updates',
      filename: 'QuietQuran-${u.version}.apk',
      updates: Updates.statusAndProgress,
      retries: 3,
    );
    FileDownloader().configureNotificationForTask(
      task,
      running: TaskNotification(downloading, ''),
      complete: TaskNotification(downloaded, ''),
      progressBar: true,
      tapOpensFile: true,
    );
    state = UpdateState(stage: UpdateStage.downloading, update: u, progress: 0);
    final result = await FileDownloader().download(
      task,
      onProgress: (p) {
        if (p >= 0) {
          state = UpdateState(
            stage: UpdateStage.downloading,
            update: u,
            progress: p,
          );
        }
      },
    );
    if (result.status != TaskStatus.complete) {
      state = UpdateState(stage: UpdateStage.failed, update: u);
      return;
    }
    state = UpdateState(stage: UpdateStage.ready, update: u);
    await install();
  }

  /// Opens the system installer for the downloaded update.
  Future<void> install() async {
    final u = state.update;
    if (u == null) return;
    await FileDownloader().openFile(
      task: DownloadTask(
        taskId: 'update-${u.build}',
        url: u.page,
        baseDirectory: BaseDirectory.applicationSupport,
        directory: 'updates',
        filename: 'QuietQuran-${u.version}.apk',
      ),
      mimeType: 'application/vnd.android.package-archive',
    );
  }
}

final updateProvider = NotifierProvider<UpdateChecker, UpdateState>(
  UpdateChecker.new,
);
