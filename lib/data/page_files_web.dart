import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'image_editions.dart';

/// Saved printed pages in the browser's Cache Storage: one cache per set,
/// each page stored byte for byte as downloaded.
class PageFiles {
  static String _cacheName(ImageEdition e) => 'pages-${e.id}';

  /// Cache entries are keyed by URL; these are never fetched.
  static String _key(ImageEdition e, int page) =>
      '${web.window.location.origin}/saved-pages/${e.id}/$page';

  Future<web.Cache> _cache(ImageEdition e) =>
      web.window.caches.open(_cacheName(e)).toDart;

  Future<Set<int>> pages(ImageEdition e) async {
    final keys = (await (await _cache(e)).keys().toDart).toDart;
    return {
      for (final r in keys) ?int.tryParse(Uri.parse(r.url).pathSegments.last),
    };
  }

  Future<Uint8List?> read(ImageEdition e, int page) async {
    final res = await (await _cache(e)).match(_key(e, page).toJS).toDart;
    if (res == null) return null;
    return (await res.arrayBuffer().toDart).toDart.asUint8List();
  }

  Future<void> write(ImageEdition e, int page, Uint8List bytes) async {
    await (await _cache(
      e,
    )).put(_key(e, page).toJS, web.Response(bytes.toJS)).toDart;
  }

  Future<void> deleteAll(ImageEdition e) async {
    await web.window.caches.delete(_cacheName(e)).toDart;
  }

  /// No folders on the web; only the background downloader asks.
  Future<Never> directory(ImageEdition e) =>
      throw UnsupportedError('No page folders on the web');
}
