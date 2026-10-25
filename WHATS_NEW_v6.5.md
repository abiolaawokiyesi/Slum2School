# S2S People Portal — What's new in v6.5 (accurate attendance)

## Exact office coordinates (100 m fence)
The two offices now use the exact GPS coordinates from your Google Maps links, and are marked as
pinned (no longer "approximate"):

| Office | Latitude | Longitude | Fence |
|--------|----------|-----------|-------|
| S2S HQ — Innovation Hub (Lekki) | `6.4359` | `3.4682` | 100 m |
| S2S Early Childhood Development Center | `6.4312` | `3.4116` | 100 m |

A one-time migration also updates these coordinates on devices that had already stored the old
estimates, and the Supabase seed upserts them — so everyone gets the accurate fence.

## Live geofence map on the Attendance page
There's now a live map (OpenStreetMap via Leaflet — **no API key needed**) showing both office
geofence circles and the staff member's live position (green dot when inside the fence, red when
outside, with a GPS-accuracy ring). It matches the intent of the React map you shared, without
requiring a paid Google Maps key. If there's no internet, the map hides gracefully and clock-in
still works from GPS.

## Reporting
Added `public.v_attendance_last7_by_office` (in `supabase/03_views.sql`) — the per-office,
last-7-days attendance report, adapting the SQL you provided to the app's schema.

## Your code, included as reference (`/reference-integrations`)
Your React map, Express geofence route, and SQL report — cleaned up and set to the exact
coordinates — are included for a separate React/Node stack. The shipped portal already implements
the same 100 m Haversine geofence, so these are optional. See `reference-integrations/README.md`.

**Version badge:** bottom-left now reads **v6.5**.
