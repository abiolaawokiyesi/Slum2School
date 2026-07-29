# Reference integrations — attendance geofence

These are the files you shared, cleaned up and set to the **exact** office coordinates. They are
**reference implementations for a separate React frontend + Node/Express backend**. You do NOT need
them for the shipped S2S People Portal (`index.html`) — that app already implements the same
geofence and now shows a live map.

## Exact coordinates (100 m fence)
| Office | Latitude | Longitude |
|--------|----------|-----------|
| Innovation Hub (Lekki) | `6.4359` | `3.4682` |
| Early Childhood Development Center | `6.4312` | `3.4116` |

## How each file maps to the shipped app
- **AttendanceMap.jsx** → the portal already has a built-in live map (Leaflet/OpenStreetMap, no API
  key) showing both 100 m geofences and your live position on the Attendance page. Use this React
  component only if you build a separate React app *and* have a Google Maps API key.
- **attendance.route.js** → the portal verifies presence client-side with the same Haversine math,
  and Supabase Row-Level Security protects the data. If you add a Node backend, this route enforces
  the fence server-side too (recommended for tamper-resistance).
- **attendance_report.sql** → the portal ships the equivalent as the view
  `public.v_attendance_last7_by_office` (see `supabase/03_views.sql`), adapted to its
  one-row-per-day schema.

## Notes on accuracy
- A 100 m fence is only as accurate as the phone's GPS fix; the portal shows live GPS accuracy (±m)
  and warns when accuracy is wider than the fence.
- If either coordinate is slightly off for your building, an admin can re-pin it on-site via
  **Attendance → Manage locations → Use my current location**.
