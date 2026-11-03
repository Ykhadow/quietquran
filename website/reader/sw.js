// Keeps Quiet Quran working offline. tool/build_web.py fills in FILES (each
// file of the build, by path, with a hash of its contents), so a new release
// only downloads the files that changed.
//
// - The app's files are cached as they're first used, and served from the
//   cache from then on.
// - Opening the app asks the network first, so a new release shows up, and
//   falls back to the cached page offline.
// - Anything else (printed pages from pages.quietquran.com, recitation from
//   the reciter's host) passes straight through: the app keeps saved pages
//   in caches of its own, which this never touches.
'use strict';

const FILES = {
 "assets/AssetManifest.bin": "b9c3c51cb0a5f194",
 "assets/AssetManifest.bin.json": "39851051f2dfe423",
 "assets/FontManifest.json": "b5f3cfe4001991e6",
 "assets/NOTICES": "2819d9cdd6feaab3",
 "assets/assets/brand/mark_day.svg": "b13802b3e428897a",
 "assets/assets/brand/mark_night.svg": "6cad89b8ecd939dc",
 "assets/assets/brand/now_playing.png": "7a66d44d6bda182a",
 "assets/assets/db/quran.db": "e54f7d69e4222921",
 "assets/assets/fonts/IndoPakNastaleeq.ttf": "a6463e24e3665140",
 "assets/assets/fonts/KFGQPCNastaleeq.ttf": "de174e33ae14cb58",
 "assets/assets/fonts/SurahNameV2.ttf": "2d4678ef53ef76c3",
 "assets/assets/fonts/UthmanicHafs.ttf": "aa68bffce289b4c0",
 "assets/assets/fonts/ui/Amiri-400.ttf": "7f19c4a5dc77b0ef",
 "assets/assets/fonts/ui/Newsreader-400-italic.ttf": "a7a0a9114e29fbf6",
 "assets/assets/fonts/ui/Newsreader-400.ttf": "b8f5e0a8bdd6a12c",
 "assets/assets/fonts/ui/NotoNaskhArabic-400.ttf": "e62e84cf72fe9e89",
 "assets/assets/fonts/ui/NotoNaskhArabic-600.ttf": "ac4fb133d2283ddf",
 "assets/assets/fonts/ui/NotoNastaliqUrdu.ttf": "98a4787f34eb6fde",
 "assets/assets/fonts/ui/SourceSans3-400.ttf": "b6f2cc8d9905e97b",
 "assets/assets/fonts/ui/SourceSans3-600.ttf": "26efb7fbad9540df",
 "assets/assets/samples/printed_indopak.webp": "68978400a0a74cc2",
 "assets/assets/samples/printed_madani.webp": "0bd7ef9dc75d4f38",
 "assets/fonts/MaterialIcons-Regular.otf": "e2d632c40171cd9e",
 "assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "3d90c370aa4cf00d",
 "assets/packages/flutter_local_notifications_web/web/notifications_service_worker.js": "566f47dccc0f417f",
 "assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w100.ttf": "e3b9abaf98c0f47f",
 "assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w200.ttf": "ed2cd225099dd158",
 "assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w300.ttf": "91a06c99e1b28a63",
 "assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w400.ttf": "d87b7cb009af7595",
 "assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w500.ttf": "91b894e3ed330f04",
 "assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w600.ttf": "bd8f5bbad19596ff",
 "assets/packages/lucide_icons_flutter/assets/lucide.ttf": "017edc199bd4579d",
 "assets/packages/media_kit/assets/web/hls1.4.10.js": "30b278794fd3f269",
 "assets/shaders/ink_sparkle.frag": "2dca5ab93d4ec29e",
 "assets/shaders/stretch_effect.frag": "ab412f07a5b9b50b",
 "canvaskit/canvaskit.js": "7361b744487f9826",
 "canvaskit/canvaskit.wasm": "6bdfaa51c76845c0",
 "canvaskit/chromium/canvaskit.js": "d2aceb0e24ead163",
 "canvaskit/chromium/canvaskit.wasm": "c2fc286476354092",
 "canvaskit/experimental_webparagraph/canvaskit.js": "803f7bab5f280fb6",
 "canvaskit/experimental_webparagraph/canvaskit.wasm": "6b916e684369558b",
 "canvaskit/skwasm.js": "e0316a798a929008",
 "canvaskit/skwasm.wasm": "084a99454e405ad9",
 "canvaskit/skwasm_heavy.js": "fbf1c3374cd28b38",
 "canvaskit/skwasm_heavy.wasm": "8b8279650b1847d8",
 "canvaskit/wimp.js": "3f2cc5ae04078950",
 "canvaskit/wimp.wasm": "781cd10fd4a893f0",
 "favicon.png": "92342e772ed19186",
 "flutter.js": "a483fd28f51ed2fa",
 "flutter_bootstrap.js": "c4ce44ea7c41d523",
 "icons/Icon-192.png": "dc92bf6e44ca1ca6",
 "icons/Icon-512.png": "21d58b976273bde3",
 "icons/Icon-maskable-192.png": "7ea0a1a4c7eb6fce",
 "icons/Icon-maskable-512.png": "f456caa0d392e3e3",
 "index.html": "18b9cd5ac98dc01f",
 "main.dart.js": "9861fb951450a383",
 "main.dart.mjs": "2e879c714a7dde40",
 "main.dart.wasm": "28470ec12d9b7197",
 "manifest.json": "e6e624ea428b4d59",
 "sqlite3.wasm": "13d3f11d05b39ba0",
 "version.json": "88222a1a845233df"
};
const CACHE = 'reader-files';
const SHELL = ['index.html', 'flutter_bootstrap.js', 'flutter.js', 'manifest.json'];
const scope = new URL(self.registration.scope);

const keyOf = (path) => new URL(`${path}?v=${FILES[path]}`, scope).href;
const pathOf = (url) => {
  const u = new URL(url);
  if (u.origin !== scope.origin || !u.pathname.startsWith(scope.pathname)) return null;
  const path = decodeURIComponent(u.pathname.slice(scope.pathname.length));
  return path in FILES ? path : null;
};

async function fetchAndStore(cache, path) {
  const res = await fetch(new URL(path, scope), { cache: 'no-cache' });
  if (res.ok) await cache.put(keyOf(path), res.clone());
  return res;
}

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    // The new versions of files this browser had cached, so the app still
    // opens offline after an update; and the page itself.
    const had = new Set();
    for (const req of await cache.keys()) {
      const path = pathOf(req.url);
      if (path) had.add(path);
    }
    for (const path of new Set([...SHELL, ...had])) {
      if (!(await cache.match(keyOf(path)))) await fetchAndStore(cache, path);
    }
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    // Earlier versions of files that have since changed.
    for (const req of await cache.keys()) {
      const path = pathOf(req.url);
      if (!path || req.url !== keyOf(path)) await cache.delete(req);
    }
    await self.clients.claim();
  })());
});

// The page sends what it loaded before this worker was running (the first
// visit), so exactly the files this browser uses are kept.
self.addEventListener('message', (event) => {
  if (event.data?.type !== 'cache') return;
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    for (const url of event.data.urls) {
      const path = pathOf(url);
      if (path && !(await cache.match(keyOf(path)))) {
        try { await fetchAndStore(cache, path); } catch (_) { /* offline */ }
      }
    }
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  if (req.mode === 'navigate' && new URL(req.url).pathname.startsWith(scope.pathname)) {
    event.respondWith(openApp(req));
    return;
  }
  const path = pathOf(req.url);
  if (path) event.respondWith(cached(path));
});

async function openApp(req) {
  const cache = await caches.open(CACHE);
  try {
    const res = await fetch(req);
    if (res.ok) await cache.put(keyOf('index.html'), res.clone());
    return res;
  } catch (err) {
    const page = await cache.match(keyOf('index.html'));
    if (page) return page;
    throw err;
  }
}

async function cached(path) {
  const cache = await caches.open(CACHE);
  return (await cache.match(keyOf(path))) ?? fetchAndStore(cache, path);
}
