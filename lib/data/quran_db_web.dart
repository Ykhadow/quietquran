import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:sqlite3/wasm.dart';

/// Opens the bundled Quran database in the browser: SQLite as WebAssembly
/// (web/sqlite3.wasm, from the sqlite3 package's release), reading the
/// database's bytes from memory. The browser caches the asset itself, so
/// nothing is copied into site storage.
Future<CommonDatabase> openBundledDb(int schemaVersion) async {
  final (sqlite, data) = await (
    WasmSqlite3.loadFromUrlString('sqlite3.wasm'),
    rootBundle.load('assets/db/quran.db'),
  ).wait;
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  sqlite.registerVirtualFileSystem(
    _BundledDbFileSystem(_path, bytes.toJS),
    makeDefault: true,
  );
  return sqlite.open(_path, mode: OpenMode.readOnly);
}

CommonDatabase openDbFile(String path) =>
    throw UnsupportedError('No database files on the web');

const _path = '/quran.db';

/// Serves the database's bytes to SQLite. Each page SQLite reads is copied
/// with one typed-array copy in the browser: going through Dart lists, as
/// the package's in-memory file system does, copies byte by byte and makes
/// every query take seconds. Any other file SQLite asks for (none, for a
/// read-only database) is kept in memory.
final class _BundledDbFileSystem extends BaseVirtualFileSystem {
  _BundledDbFileSystem(this._dbPath, this._bytes) : super(name: 'bundled-db');

  final String _dbPath;
  final JSUint8Array _bytes;
  final _others = InMemoryFileSystem(name: 'bundled-db-others');

  @override
  XOpenResult xOpen(Sqlite3Filename path, int flags) {
    if (path.path != _dbPath) return _others.xOpen(path, flags);
    return (outFlags: SqlFlag.SQLITE_OPEN_READONLY, file: _BundledFile(_bytes));
  }

  @override
  int xAccess(String path, int flags) =>
      path == _dbPath ? 1 : _others.xAccess(path, flags);

  @override
  void xDelete(String path, int syncDir) {
    if (path != _dbPath) _others.xDelete(path, syncDir);
  }

  @override
  String xFullPathName(String path) => path.startsWith('/') ? path : '/$path';

  @override
  void xSleep(Duration duration) {}
}

class _BundledFile extends BaseVfsFile {
  _BundledFile(this._bytes);

  final JSUint8Array _bytes;

  @override
  int readInto(Uint8List buffer, int offset) {
    final length = _bytes.length;
    if (offset >= length) return 0;
    final end = offset + buffer.length < length
        ? offset + buffer.length
        : length;
    // [buffer] is a view of SQLite's memory, so this writes straight in.
    buffer.toJS.set(_bytes.subarray(offset, end), 0);
    return end - offset;
  }

  @override
  int xFileSize() => _bytes.length;

  @override
  void xWrite(Uint8List buffer, int fileOffset) =>
      throw const VfsException(SqlError.SQLITE_READONLY);

  @override
  void xTruncate(int size) =>
      throw const VfsException(SqlError.SQLITE_READONLY);

  @override
  int xCheckReservedLock() => 0;

  @override
  void xClose() {}

  @override
  void xLock(int mode) {}

  @override
  void xUnlock(int mode) {}

  @override
  void xSync(int flags) {}
}

extension on JSUint8Array {
  external int get length;
  external void set(JSUint8Array source, int offset);
  external JSUint8Array subarray(int start, int end);
}
