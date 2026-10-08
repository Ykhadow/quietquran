import 'dart:async';
import 'dart:io';
import 'dart:isolate';

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

/// Fetches page images on demand and caches them on disk; can also download
/// a whole set for offline use. State maps image edition id -> status.
class PageImageStore extends Notifier<Map<String, DownloadStatus>> {
  final _client = http.Client();
  final _inFlight = <String, Future<Uint8List>>{};
  final _cancelled = <String>{};
  Directory? _root;

  QuranDb get _db => ref.read(quranDbProvider);

  @override
  Map<String, DownloadStatus> build() {
    ref.onDispose(_client.close);
    _refreshCounts();
    return {for (final e in ImageEdition.all) e.id: const DownloadStatus()};
  }

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

  Future<void> downloadAll(ImageEdition e) async {
    if (state[e.id]?.running ?? false) return;
    _cancelled.remove(e.id);
    _update(e.id, (st) => DownloadStatus(cached: st.cached, running: true));
    try {
      final missing = <int>[];
      for (var n = 1; n <= pageCount(e); n++) {
        if (!(await _file(e, n)).existsSync()) missing.add(n);
      }
      // A few parallel workers: fast, but polite to the host.
      var next = 0;
      Future<void> worker() async {
        while (next < missing.length && !_cancelled.contains(e.id)) {
          await load(e, missing[next++]);
        }
      }

      await Future.wait(List.generate(6, (_) => worker()));
      _update(e.id, (st) => DownloadStatus(cached: st.cached));
    } catch (err) {
      _update(e.id, (st) => DownloadStatus(cached: st.cached, error: '$err'));
    }
  }

  void cancel(ImageEdition e) {
    _cancelled.add(e.id);
    _update(e.id, (st) => DownloadStatus(cached: st.cached));
  }

  Future<void> deleteAll(ImageEdition e) async {
    cancel(e);
    final d = await _dir(e);
    if (d.existsSync()) await d.delete(recursive: true);
    _update(e.id, (_) => const DownloadStatus());
  }
}

final pageImageStoreProvider =
    NotifierProvider<PageImageStore, Map<String, DownloadStatus>>(
      PageImageStore.new,
    );
