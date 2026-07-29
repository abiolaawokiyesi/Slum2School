/* ══════════════════════════════════════════════════════════════════════════
   S2S People Portal — service worker
   v6.9: full offline operation. The app shell is served cache-first, and the
   third-party libraries the app depends on (icons, fonts, Chart.js, Supabase
   client, Leaflet) are pre-cached on install, so requisitions, memos, printing
   and clock-in all work with no internet at all.
   ═════════════════════════════════════════════════════════════════════════ */
const CACHE = 's2s-portal-v6_9_2';   // bump on every deploy to force fresh content

/* Same-origin app shell — must be cached for the app to open offline */
const SHELL = ['./', './index.html', './icon-192.png', './icon-512.png'];

/* Third-party assets. Fetched no-cors where needed; a failure here must never
   abort the install, so each is added individually and swallowed. */
const VENDOR = [
  'https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap',
  'https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.19.0/dist/tabler-icons.min.css',
  'https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.js',
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2',
  'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css',
  'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'
];

/* Requests that must NEVER be served from cache — live data and auth */
function isLive(url) {
  return /supabase\.co|\/rest\/v1\/|\/auth\/v1\/|\/realtime\//.test(url);
}
/* Runtime-cacheable third-party origins (fonts, icons, tiles, libs) */
function isVendorOrigin(url) {
  return /fonts\.googleapis\.com|fonts\.gstatic\.com|cdn\.jsdelivr\.net|cdnjs\.cloudflare\.com|unpkg\.com/.test(url);
}

self.addEventListener('install', e => {
  self.skipWaiting();
  e.waitUntil(
    caches.open(CACHE).then(c =>
      Promise.all([
        c.addAll(SHELL).catch(() => {}),
        Promise.all(VENDOR.map(u =>
          fetch(new Request(u, { mode: 'no-cors', credentials: 'omit' }))
            .then(r => c.put(u, r))
            .catch(() => {})
        ))
      ])
    )
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('message', e => {
  if (e.data === 'skipWaiting' || (e.data && e.data.type === 'skipWaiting')) self.skipWaiting();
});

self.addEventListener('fetch', e => {
  const r = e.request;
  if (r.method !== 'GET') return;                 // writes always go to network
  if (isLive(r.url)) return;                      // Supabase / auth / realtime
  const sameOrigin = new URL(r.url).origin === self.location.origin;

  /* Navigations: cache-first on index.html so the app opens with no network,
     with a background refresh so the next open is current. */
  if (r.mode === 'navigate') {
    e.respondWith(
      caches.match('./index.html').then(hit => {
        const net = fetch(r).then(res => {
          const cp = res.clone();
          caches.open(CACHE).then(c => c.put('./index.html', cp).catch(() => {}));
          return res;
        }).catch(() => hit);
        return hit || net;
      })
    );
    return;
  }

  /* Everything else: cache-first, revalidate in the background. */
  if (sameOrigin || isVendorOrigin(r.url)) {
    e.respondWith(
      caches.match(r).then(hit => {
        const net = fetch(r).then(res => {
          if (res && (res.ok || res.type === 'opaque')) {
            const cp = res.clone();
            caches.open(CACHE).then(c => c.put(r, cp).catch(() => {}));
          }
          return res;
        }).catch(() => hit);
        return hit || net;
      })
    );
    return;
  }

  /* Unknown third parties: network, falling back to anything cached. */
  e.respondWith(fetch(r).catch(() => caches.match(r)));
});
