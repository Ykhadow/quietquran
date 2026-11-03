import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Opens the bundled Quran database, copied out of the app's assets the first
/// time each [schemaVersion] runs (sqlite3 reads files, not assets).
Future<Database> openBundledDb(int schemaVersion) async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'quran_v$schemaVersion.db'));
  if (!file.existsSync()) {
    final data = await rootBundle.load('assets/db/quran.db');
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(data.buffer.asUint8List(), flush: true);
    await tmp.rename(file.path);
    // Copies left by earlier versions of the app (16 MB each).
    for (final old in dir.listSync()) {
      final name = p.basename(old.path);
      if (old is File &&
          name.startsWith('quran_v') &&
          name != p.basename(file.path)) {
        try {
          old.deleteSync();
        } on FileSystemException {
          // In use or already gone; tried again after the next update.
        }
      }
    }
  }
  return openDbFile(file.path);
}

Database openDbFile(String path) => sqlite3.open(path, mode: OpenMode.readOnly);
