import 'dart:async';
import 'dart:io' show HttpException;

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'image_editions.dart';
import 'page_files.dart';
import 'quran_db.dart';

class DownloadStatus {
  const DownloadStatus({this.cached = 0, this.running = false, this.error});
  final int cached;
  final bool running;
  final String? error;
}

/// Fetches page images on demand and caches them on disk; can also save a
/// whole set for offline use. Whole sets go through the system's background
/// downloader (Android's WorkManager, iOS's URLSession): they carry on with
/// the app in the background or closed, retry through lost connections,
/// and show their progress in a notification. A browser has no background
/// downloader, so there a set saves while the app is open. State maps image
/// edition id -> status.
class PageImageStore extends Notifier<Map<String, DownloadStatus>> {
  final _client = http.Client();
  final _inFlight = <String, Future<Uint8List>>{};
  final _files = PageFiles();

  /// Sets saving while the app is open (web), by run, so Pause can stop one.
  final _runs = <String, Object>{};
  StreamSubscription<TaskUpdate>? _updates;
  final _recounts = <String, Timer>{};

  QuranDb get _db => ref.read(quranDbProvider);

  @override
  Map<String, DownloadStatus> build() {
    ref.onDispose(() {
      _client.close();
      _updates?.cancel();
      for (final t in _recounts.values) {
        t.cancel();
      }
    });
    if (backgroundDownloads) {
      _updates = FileDownloader().updates.listen(_onUpdate);
    }
    _refreshCounts().then((_) => _refreshRunning());
    return {for (final e in ImageEdition.all) e.id: const DownloadStatus()};
  }

  /// Off in tests, which have no platform downloader.
  static var backgroundDownloads = !kIsWeb;

  /// The background downloader's group for a set's pages.
  static String _group(ImageEdition e) => 'pages-${e.id}';

  ImageEdition? _editionOf(Task task) =>
      ImageEdition.all.where((e) => _group(e) == task.group).firstOrNull;

  int pageCount(ImageEdition e) => _db.edition(e.layout).pages;

  Future<void> _refreshCounts() async {
    for (final e in ImageEdition.all) {
      final n = await savedCount(e);
      _update(
        e.id,
        (st) => DownloadStatus(cached: n, running: st.running, error: st.error),
      );
    }
  }

  /// How many of [e]'s pages are saved on this device, counted afresh.
  Future<int> savedCount(ImageEdition e) async =>
      (await _files.pages(e)).length;

  /// A saved page's bytes (SVG text or image), or null if it isn't saved.
  /// Printed pages are read only once the whole set is downloaded, so the
  /// reader never depends on a connection.
  Future<Uint8List?> saved(ImageEdition e, int page) => _files.read(e, page);

  /// Which sets are still saving (possibly from before the app last
  /// closed).
  Future<void> _refreshRunning() async {
    if (!backgroundDownloads) return;
    for (final e in ImageEdition.all) {
      final left = await FileDownloader().allTasks(group: _group(e));
      _update(
        e.id,
        (st) => DownloadStatus(cached: st.cached, running: left.isNotEmpty),
      );
    }
  }

  /// A page of a set finished (or failed): recount that set shortly after,
  /// rather than for every one of hundreds of pages.
  void _onUpdate(TaskUpdate u) {
    if (u is! TaskStatusUpdate || !u.status.isFinalState) return;
    final e = _editionOf(u.task);
    if (e == null) return;
    if (u.status == TaskStatus.failed || u.status == TaskStatus.notFound) {
      _update(
        e.id,
        (st) => DownloadStatus(
          cached: st.cached,
          running: st.running,
          error: '${u.exception?.description ?? u.status}',
        ),
      );
    }
    _recounts[e.id]?.cancel();
    _recounts[e.id] = Timer(const Duration(milliseconds: 400), () async {
      _recounts.remove(e.id);
      final n = await savedCount(e);
      final left = await FileDownloader().allTasks(group: _group(e));
      _update(
        e.id,
        (st) => DownloadStatus(
          cached: n,
          running: left.isNotEmpty,
          error: left.isEmpty && n < pageCount(e) ? st.error : null,
        ),
      );
    });
  }

  void _update(String id, DownloadStatus Function(DownloadStatus) f) {
    state = {...state, id: f(state[id] ?? const DownloadStatus())};
  }

  /// Raw page bytes (SVG text or image), downloading and saving if needed.
  /// Used by [downloadAll]; the reader reads [saved] pages only.
  Future<Uint8List> load(ImageEdition e, int page) {
    final key = '${e.id}/$page';
    // Block body: returning the removed future here would make whenComplete
    // wait on itself forever.
    return _inFlight[key] ??= _load(e, page).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  Future<Uint8List> _load(ImageEdition e, int page) async {
    if (await _files.read(e, page) case final bytes?) return bytes;
    final url = e.url(
      page,
      path: e.usesPathTable ? _db.imagePath(e.id, page) : null,
    );
    // A stalled connection must not hang a download (or "download all")
    // forever.
    final res = await _client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw HttpException('Page $page: HTTP ${res.statusCode}');
    }
    await _files.write(e, page, res.bodyBytes);
    _update(
      e.id,
      (st) => DownloadStatus(cached: st.cached + 1, running: st.running),
    );
    return res.bodyBytes;
  }

  /// Saves every page of [e] not yet saved, in the background, with
  /// [saving] (where {numFinished} and {numTotal} count the pages) and
  /// [saved] as the notification's text. Raster sets only: vector pages are
  /// stored compressed, which the downloader doesn't do.
  Future<void> downloadAll(
    ImageEdition e, {
    required String saving,
    required String saved,
  }) async {
    if (e.format != ImageFormat.raster || (state[e.id]?.running ?? false)) {
      return;
    }
    if (!backgroundDownloads) {
      if (kIsWeb) await _saveWhileOpen(e);
      return;
    }
    final have = await _files.pages(e);
    final missing = [
      for (var n = 1; n <= pageCount(e); n++)
        if (!have.contains(n)) n,
    ];
    if (missing.isEmpty) return;
    // The progress notification needs permission on Android 13 and later.
    await FileDownloader().permissions.request(PermissionType.notifications);
    FileDownloader().configureNotificationForGroup(
      _group(e),
      running: TaskNotification(saving, ''),
      complete: TaskNotification(saved, ''),
      progressBar: true,
      groupNotificationId: _group(e),
    );
    _update(e.id, (st) => DownloadStatus(cached: st.cached, running: true));
    final dir = await _files.directory(e);
    final root = (await getApplicationSupportDirectory()).path;
    await FileDownloader().enqueueAll([
      for (final n in missing)
        DownloadTask(
          taskId: '${e.id}-$n',
          url: e.url(n, path: e.usesPathTable ? _db.imagePath(e.id, n) : null),
          baseDirectory: BaseDirectory.applicationSupport,
          directory: p.relative(dir.path, from: root),
          filename: '$n.${e.fileExtension}',
          group: _group(e),
          updates: Updates.status,
          retries: 5,
        ),
    ]);
  }

  /// Saves the pages of [e] not yet saved, six at a time, while the app
  /// stays open; each page is tried a few times before the set reports an
  /// error. Pause stops it, keeping the pages saved so far.
  Future<void> _saveWhileOpen(ImageEdition e) async {
    final have = await _files.pages(e);
    final missing = [
      for (var n = 1; n <= pageCount(e); n++)
        if (!have.contains(n)) n,
    ];
    if (missing.isEmpty) return;
    final run = _runs[e.id] = Object();
    _update(e.id, (st) => DownloadStatus(cached: st.cached, running: true));
    Object? failure;
    var next = 0;
    Future<void> worker() async {
      while (_runs[e.id] == run && next < missing.length) {
        final page = missing[next++];
        for (var attempt = 1; ; attempt++) {
          try {
            await load(e, page);
            break;
          } on Object catch (err) {
            if (attempt == 5) {
              failure = err;
              break;
            }
            await Future<void>.delayed(Duration(seconds: 2 * attempt));
          }
        }
      }
    }

    await Future.wait([for (var i = 0; i < 6; i++) worker()]);
    if (_runs[e.id] != run) return;
    _runs.remove(e.id);
    final n = await savedCount(e);
    _update(
      e.id,
      (_) => DownloadStatus(
        cached: n,
        error: n < pageCount(e) && failure != null ? '$failure' : null,
      ),
    );
  }

  /// Stops saving [e] (Pause in Settings); pages already saved are kept.
  Future<void> cancel(ImageEdition e) async {
    _runs.remove(e.id);
    if (backgroundDownloads) {
      await FileDownloader().cancelAll(group: _group(e));
    }
    _update(e.id, (st) => DownloadStatus(cached: st.cached));
  }

  Future<void> deleteAll(ImageEdition e) async {
    await cancel(e);
    await _files.deleteAll(e);
    _update(e.id, (_) => const DownloadStatus());
  }
}

final pageImageStoreProvider =
    NotifierProvider<PageImageStore, Map<String, DownloadStatus>>(
      PageImageStore.new,
    );
