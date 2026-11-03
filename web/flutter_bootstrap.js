{{flutter_js}}
{{flutter_build_config}}

// No serviceWorkerSettings: Flutter's service worker only unregisters
// itself, and would take ours (sw.js) with it.
// `?renderer=canvaskit` (or skwasm) picks the renderer, for comparing them on
// a phone; otherwise Flutter picks the best the browser supports.
const renderer = new URLSearchParams(location.search).get('renderer');
_flutter.loader.load(renderer ? { config: { renderer } } : {});
