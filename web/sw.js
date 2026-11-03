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

const FILES = {/* FILES */};
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
