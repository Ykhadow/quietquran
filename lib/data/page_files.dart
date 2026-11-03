/// Where saved printed pages are kept: files on a device, Cache Storage in a
/// browser.
library;

export 'page_files_io.dart' if (dart.library.js_interop) 'page_files_web.dart';
