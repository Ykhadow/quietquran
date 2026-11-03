{{flutter_js}}
{{flutter_build_config}}

// No serviceWorkerSettings: Flutter's service worker only unregisters
// itself, and would take ours (sw.js) with it.
_flutter.loader.load();
