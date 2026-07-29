# S2S Portal — Deploying & "nothing changed" fix

## First: confirm which version is live
Open your deployed site. The updated build shows a small badge at the **bottom-left**:

> **S2S Portal v6.2 · 23 Jul 2026**

- **If you SEE the badge** → the new version is deployed. The new things appear **after you log in**
  (see the checklist below), not on the login screen.
- **If you do NOT see the badge** → your browser or host is serving an **old cached copy**. Fix it
  with the steps under "Clear the cache" below.

You can also confirm the file itself: open the page, **View Page Source**, and search (Ctrl+F) for
`BUILD v6.2`. If it's not there, the file on your server is the old one — re-upload `index.html`.

## What you should see AFTER logging in (v6.2)
- Sidebar has **Notice Board** and **Requisitions**.
- **Payroll** is visible only to HR, the Executive Director and the Finance Manager (hidden for others).
- On **Attendance**, a **"Where are you working today?"** location dropdown + a 100 m geofence with
  live GPS accuracy, and (for admins) a **Manage locations** button.
- Payroll page has a **Print payroll** button (grouped by staff category).
- A **cloud button** (bottom-right) to connect Supabase, and an **Install** prompt on phones.

(The login screen looks almost the same as before — the changes are inside the app, so please sign
in to see them.)

## Clear the cache (most common cause of "nothing changed")
Do these on the deployed URL:
1. **Hard refresh:** Windows/Linux `Ctrl + Shift + R`, Mac `Cmd + Shift + R`.
2. If still old, open the browser **DevTools → Application** tab:
   - **Service Workers** → click **Unregister**.
   - **Storage** → **Clear site data**.
   - Reload the page.
3. On a phone: close the tab, or in the browser settings clear the site's data, then reopen.

## If you use a static host / CDN
- Make sure you actually **replaced `index.html`** on the server with the new file
  (`index.html`, 480 KB, build v6.2).
- Keep these files **in the same folder** as index.html so install + icons work:
  `sw.js`, `icon-192.png`, `icon-512.png`.
- **Purge the CDN/host cache** after uploading:
  - **Netlify/Vercel:** trigger a fresh deploy (they cache aggressively).
  - **GitHub Pages:** can take 1–5 minutes to update; hard-refresh after.
  - **cPanel/shared hosting:** overwrite the file and clear any host-side cache.
- The service worker cache name is bumped each release (`s2s-portal-v6_2`), so once the new
  `index.html` + `sw.js` are served, clients update automatically on the next load.

## Still stuck?
Send me the exact URL you deployed to (or a screenshot showing the bottom-left corner). If the badge
says an older version — or is missing — the old file is still being served and it's a
cache/upload issue, not the app itself. The delivered file (md5 changes each build) definitely
contains every feature.
