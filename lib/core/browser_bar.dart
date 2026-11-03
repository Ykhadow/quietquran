/// The colour a browser gives its bars around the web version (the status
/// bar of an installed app); nothing on other platforms.
library;

export 'browser_bar_io.dart'
    if (dart.library.js_interop) 'browser_bar_web.dart';
