import 'package:web/web.dart' as web;

/// Whether the page is cross-origin isolated (needed for the renderer to draw
/// on its own thread), and how many cores the browser reports.
String pageInfo() =>
    '${web.window.crossOriginIsolated ? 'isolated' : 'NOT isolated'}, '
    '${web.window.navigator.hardwareConcurrency} cores';
