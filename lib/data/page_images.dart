import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'image_editions.dart';
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
/// and show their progress in a notification. State maps image edition
/// id -> status.
class PageImageStore extends Notifier<Map<String, DownloadStatus>> {
  final _client = http.Client();
  final _inFlight = <String, Future<Uint8List>>{};
  Directory? _root;
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
  static var backgroundDownloads = true;

  /// The background downloader's group for a set's pages.
  static String _group(ImageEdition e) => 'pages-${e.id}';

  ImageEdition? _editionOf(Task task) =>
      ImageEdition.all.where((e) => _group(e) == task.group).firstOrNull;

  int pageCount(ImageEdition e) => _db.edition(e.layout).pages;

  Future<Directory> _dir(ImageEdition e) async {
    _root ??= Directory(
      p.join((await getApplicationSupportDirectory()).path, 'pages'),
    );
    final d = Directory(p.join(_root!.path, e.id));
    if (!d.existsSync()) await d.create(recursive: true);
    return d;
  }

  Future<File> _file(ImageEdition e, int page) async =>
      File(p.join((await _dir(e)).path, '$page.${e.fileExtension}'));

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
      (await _dir(e)).listSync().where((f) => !f.path.endsWith('.tmp')).length;

  /// A saved page's bytes (SVG text or image), or null if it isn't saved.
  /// Printed pages are read only once the whole set is downloaded, so the
  /// reader never depends on a connection.
  Future<Uint8List?> saved(ImageEdition e, int page) async {
    final file = await _file(e, page);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    // Unpacking a vector page takes a moment: off the UI thread, so it
    // can't stutter a swipe.
    return e.format == ImageFormat.svg
        ? Isolate.run(() => Uint8List.fromList(gzip.decode(bytes)))
        : bytes;
  }

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
    final file = await _file(e, page);
    final gz = e.format == ImageFormat.svg;
    if (file.existsSync()) {
      final bytes = await file.readAsBytes();
      // Unpacking a vector page takes a moment: off the UI thread, so it
      // can't stutter a swipe.
      return gz
          ? Isolate.run(() => Uint8List.fromList(gzip.decode(bytes)))
          : bytes;
    }
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
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(
      gz ? await Isolate.run(() => gzip.encode(res.bodyBytes)) : res.bodyBytes,
      flush: true,
    );
    await tmp.rename(file.path);
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
    if (!backgroundDownloads ||
        e.format != ImageFormat.raster ||
        (state[e.id]?.running ?? false)) {
      return;
    }
    final missing = <int>[];
    for (var n = 1; n <= pageCount(e); n++) {
      if (!(await _file(e, n)).existsSync()) missing.add(n);
    }
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
    final dir = await _dir(e);
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

  /// Stops saving [e] (Pause in Settings); pages already saved are kept.
  Future<void> cancel(ImageEdition e) async {
    if (backgroundDownloads) {
      await FileDownloader().cancelAll(group: _group(e));
    }
    _update(e.id, (st) => DownloadStatus(cached: st.cached));
  }

  Future<void> deleteAll(ImageEdition e) async {
    await cancel(e);
    final d = await _dir(e);
    if (d.existsSync()) await d.delete(recursive: true);
    _update(e.id, (_) => const DownloadStatus());
  }
}

final pageImageStoreProvider =
    NotifierProvider<PageImageStore, Map<String, DownloadStatus>>(
      PageImageStore.new,
    );
