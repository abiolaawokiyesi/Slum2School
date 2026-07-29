# S2S People Portal — v6.9.2 (29 July 2026)

Version badge in the app now reads **S2S Portal v6.9.2 · 29 Jul 2026**. If you still see 6.8
after deploying, do one hard refresh (Ctrl+Shift+R / Cmd+Shift+R) — the service-worker cache
name was bumped to `s2s-portal-v6_9_2`, so one refresh is all it takes.

This release answers the six points you raised, in order.

---

## 1. 1.2 inch of clear space above every signature

Every printed memo and every requisition — standard and scholar — now leaves a full **1.2 inch**
of clear space between the last line of content and the signature block. That is real writing
room for a wet signature, not a decorative gap.

Because you asked for *up to* 1.2 inch, the space is intelligent rather than fixed. When the
document runs long and the full 1.2 inch would push the signature block onto a sheet of its own,
the portal trims the gap just enough to keep the signatures on the same page as the content they
approve — and never trims below 0.45 inch. Nothing is ever signed on a blank page. On a short
requisition the gap comes out around an inch; on anything with room, it is the full 1.2 inch.

## 2. The grey captions above the signature lines are gone

The small grey "1ST SIGNATORY / 2ND SIGNATORY / 3RD SIGNATORY" captions that sat above each
signature line have been removed everywhere — memo, standard requisition, scholar requisition
and payroll.

What remains under each line is what matters: the person's name in bold, and their role in the
chain (Requested by · Line Manager · Approved by · Finance Manager · Approved by · Executive
Director · Approved by). Leave the line-manager field blank and the block still collapses
cleanly to three columns.

## 3. Attendance: clock in and out as many times as you need

**Unlimited punches per day.** A staff member can now clock out for a field visit, a bank run or
lunch and clock back in on return, as many times as the day requires. The portal keeps the full
ordered punch list, pairs them into sessions and adds up the worked minutes.

The clock-in button relabels itself to **"Clock IN again"** once you have already been in that
day, and the portal refuses to accept two INs in a row or an OUT when you are not clocked in, so
the record cannot get tangled. Your own status line reads, for example,
*07:45→12:10 · 13:05→17:30 · 4 punches · 8h 40m*.

**The HR and ED dashboards now show all of it.** A new attendance analytics block appears on the
dashboard for HR, the ED, the Finance Manager and admins — and a fuller version under
Attendance → **📈 Charts & Table**. It carries:

- Four KPI chips: staff on site now, present today, total sessions today, average hours
- A daily attendance chart across the selected month
- A hours-worked chart per staff member
- A department breakdown
- A searchable, month-filtered table of every day, with first in, last out, session count and
  total hours — exportable to CSV and printable

Ordinary staff see only their own record; the analytics block is hidden from them entirely.

**Geofence tightened to 20 metres.** Both offices — the Innovation Hub (6.443385, 3.476079) and
the Early Childhood Development Centre (6.4312, 3.4116) — now use a **20 m** fence instead of
200 m. Clock-in still samples GPS for up to 8 seconds and keeps the most accurate reading, and
the accuracy figure is shown to the user, because a 20 m fence only works if the fix is good.

Run **`supabase/05_attendance_punches.sql`** in the Supabase SQL editor to store the punch list
in the cloud. Until you do, the app still works — it detects the older table shape and falls back
to writing first-in / last-out, so nothing is lost.

## 4. "Unit" removed from the account breakdown

The **Unit** column is gone from the standard requisition's account breakdown, on screen and in
print — it said the same thing as Qty. The remaining columns are S/N, Payee / Vendor,
Description, Qty, Rate, Amount and Account details.

**The automation is untouched.** Qty × Rate still fills Amount by itself, amounts still roll up
per vendor, the grand total still sums, and the amount in words still rewrites as you type. Type
an amount directly and it is used as-is, exactly as before. Saved requisitions raised on v6.8
still open and reprint correctly.

## 5. Printing is now near-instant

Printing a memo or requisition used to open a whole new browser window, write the document into
it and then wait half a second before offering the print dialog. It now renders into a hidden
frame inside the page you are already on and opens the dialog the moment the document is actually
ready — measured at **under 80 milliseconds**, against roughly 500–1500 ms before.

The background artwork, the header and footer margins and the full-bleed print quality are
unchanged; verified page by page across the memo, the standard requisition, a 28-scholar
requisition and the three-page payroll.

## 6. The portal works without internet

The whole app — and requisitions and memos in particular — now works with no connection at all.

- **Everything is cached.** The app shell plus every external library it uses (fonts, icons,
  charts, the map, the Supabase client) is stored on the device on first load, so the portal opens
  offline instead of showing a blank page.
- **Printing works offline.** The print stylesheet uses only fonts already on the device and the
  background artwork is embedded in the file, so a requisition printed on a dead connection looks
  identical to one printed online.
- **Nothing is lost.** Clock-ins and saved requisitions made offline are written to the device
  immediately and queued. A small banner in the corner tells you how many changes are waiting.
  The moment the connection returns they sync to Supabase by themselves — no button to press, no
  re-typing.

---

## Files in this release

| File | What it is |
|---|---|
| `index.html` | The whole app — single file, v6.9.2 |
| `sw.js` | Service worker (cache `s2s-portal-v6_9_2`) — now caches the libraries too, for offline use |
| `icon-192.png`, `icon-512.png` | App icons for install-to-home-screen |
| `supabase/01_schema.sql` … `04_accounts.sql` | Database schema, seed, views, pre-created accounts |
| `supabase/05_attendance_punches.sql` | **New** — multiple clock-ins per day, plus session / daily / monthly reporting views |
| `supabase/06_verify.sql` | **New** — checks the install, and 20 ready-made queries for HR and the ED |
| `supabase/README_SUPABASE.md` | The Supabase connection guide — rewritten for this release |
| `reference-integrations/` | React Native / React / Express / SQL reference code for the mobile build (fence updated to 20 m) |
| `DEPLOY_AND_TROUBLESHOOT.md` | Deploying, and what to do if a change doesn't appear |
| `WHATS_NEW_v6.9.md` | This file |

## 7. Fixes in 6.9.1

Two problems found while testing the Supabase setup end to end on a real Postgres:

**Staff edits were not reaching the cloud.** When HR added or edited someone in the staff
directory, the portal wrote the change to the device but the copy sent to Supabase used the wrong
column names, so the database quietly rejected it. HR edits now sync correctly.

**The attendance reporting views ignored the security rules.** `attendance_daily`,
`attendance_monthly` and `attendance_sessions` were created without `security_invoker`, which in
Postgres means they run with the owner's rights — so an ordinary staff member querying them
directly could have read the whole organisation's attendance. They now run as the signed-in user,
which was the intention: staff see their own rows, HR and the ED see everyone. Re-run
`supabase/05_attendance_punches.sql` to apply this. It also now re-runs cleanly, which it did not
before.

## 8. The portal now connects itself (6.9.2)

Asking 40+ staff to each paste a Project URL and a key was never going to work. The Slum2School
Supabase details are now **built into the app**, so it connects on its own the first time each
person opens it. Send one link; there is nothing to set up on anyone's phone or laptop.

The round cloud button comes up **green** straight away and reads *"✓ Connected to the S2S project
automatically — data is saving live. Nothing to enter."* The two boxes in that panel are left empty
on purpose — they exist only for pointing one device at a different project, and a **Use the S2S
project** button puts it back.

The key that ships in the file is the **anon public** key, which is what Supabase intends to sit in
a browser: it grants nothing by itself, because Row-Level Security in `01_schema.sql` is what
decides who may read what. The `service_role` key is not in the file and must never be. This does
make `01_schema.sql` non-optional — run it before sharing the link.

Two smaller things came with it. Pasting a URL is now forgiving: `.../rest/v1/`, a trailing slash,
a missing `https://`, stray quotes or spaces all resolve to the same project — the REST URL from
the Supabase dashboard works as-is. And a login that the cloud rejects now falls back to the
account on that device instead of locking the person out, so the seeded admin still works before
the SQL has been run.

## Deploying

1. Replace `index.html` and `sw.js` on your host with the files in this zip.
2. Open the portal and hard-refresh once (Ctrl+Shift+R / Cmd+Shift+R). The badge should read
   **v6.9.2 · 29 Jul 2026** and the cloud button should be green with no setup.
3. In Supabase → SQL editor, run `supabase/05_attendance_punches.sql`. It is safe to run twice.
4. Ask staff to open the portal once while online, so the offline cache fills. After that it opens
   with or without a connection.
