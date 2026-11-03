import 'dart:ui';

import 'package:web/web.dart' as web;

String? _current;

/// Sets the page's one theme-color to [colour], replacing web/index.html's
/// pair (which follow the phone's dark mode, not the app's theme).
void setBrowserBarColour(Color colour) {
  final hex =
      '#${(colour.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  if (hex == _current) return;
  _current = hex;
  final head = web.document.head!;
  final tags = web.document.querySelectorAll('meta[name="theme-color"]');
  for (var i = 0; i < tags.length; i++) {
    head.removeChild(tags.item(i)!);
  }
  head.appendChild(
    (web.document.createElement('meta') as web.HTMLMetaElement)
      ..name = 'theme-color'
      ..content = hex,
  );
}
