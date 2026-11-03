import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'image_editions.dart';

/// Saved printed pages, one file per page under
/// `<app support>/pages/<set>/<page>.<ext>`. Vector pages are kept gzipped.
class PageFiles {
  Directory? _root;

  Future<Directory> directory(ImageEdition e) async {
    _root ??= Directory(
      p.join((await getApplicationSupportDirectory()).path, 'pages'),
    );
    final d = Directory(p.join(_root!.path, e.id));
    if (!d.existsSync()) await d.create(recursive: true);
    return d;
  }

  Future<File> _file(ImageEdition e, int page) async =>
      File(p.join((await directory(e)).path, '$page.${e.fileExtension}'));

  /// The pages of [e] saved on this device.
  Future<Set<int>> pages(ImageEdition e) async => {
    for (final f in (await directory(e)).listSync())
      if (!f.path.endsWith('.tmp'))
        ?int.tryParse(p.basename(f.path).split('.').first),
  };

  /// A saved page's bytes (SVG text or image), or null if it isn't saved.
  Future<Uint8List?> read(ImageEdition e, int page) async {
    final file = await _file(e, page);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    // Unpacking a vector page takes a moment: off the UI thread, so it
    // can't stutter a swipe.
    return e.format == ImageFormat.svg
        ? Isolate.run(() => Uint8List.fromList(gzip.decode(bytes)))
        : bytes;
  }

  /// Saves a page's bytes as downloaded.
  Future<void> write(ImageEdition e, int page, Uint8List bytes) async {
    final file = await _file(e, page);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(
      e.format == ImageFormat.svg
          ? await Isolate.run(() => gzip.encode(bytes))
          : bytes,
      flush: true,
    );
    await tmp.rename(file.path);
  }

  Future<void> deleteAll(ImageEdition e) async {
    final d = await directory(e);
    if (d.existsSync()) await d.delete(recursive: true);
  }
}
