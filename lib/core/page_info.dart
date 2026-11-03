/// What the browser gives the web version (for FrameStats); nothing on other
/// platforms.
library;

export 'page_info_io.dart' if (dart.library.js_interop) 'page_info_web.dart';
