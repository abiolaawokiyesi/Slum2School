# S2S People Portal — What's new (v6.6 + v6.7)

## Accurate attendance location (v6.6)
- **Headquarters set from your address:** *13 Babatope Bejide Crescent, off Fola Osibo Rd,
  Lekki Phase 1, Lagos 105102*.
- **Geofence widened to 200 m (0.1 → 0.2 km)** for both offices, so a small GPS drift no longer
  blocks a legitimate clock-in.
- **One-tap on-site pinning (the accuracy fix):** on the Attendance page an admin can tap
  **"Pin this office to where I am"** while standing at the office — it captures the exact GPS and
  sets the office coordinate precisely. This is the reliable way to get a perfect fence; the seeded
  HQ coordinate is only a best estimate until it's pinned on-site.
- Live map, per-office 7-day report view, and your React/Express/SQL reference files are included.

> Why on-site pinning matters: a 200 m fence still needs the office point to be roughly right. Address
> geocoding for that street isn't reliable enough for metres — standing at the office and tapping
> "Pin this office to where I am" makes it exact.

## Navigation cleanup (v6.7)
- **Communication and Organisation sections are now hidden for everyone** — including the Executive
  Director and Finance Manager. That removes: Notice Board, Email Hub, Staff Directory, Teachers,
  Volunteer Hub, Recruitment, Departments and Forms from the menus. Dashboard, Attendance, Payroll
  (HR/ED/Finance), Leave, Requisitions and the admin tools remain.
- **The "new version available" banner is gone.** It was overlapping the top menu. Updates now apply
  silently — when a new build is deployed, the app refreshes itself to the latest on next login, with
  no banner in the way.

**Version badge:** bottom-left now reads **v6.7**.

*Note: hiding the Communication section also hides the Notice Board (it lived under that section). If
you'd like to keep the Notice Board reachable, tell me and I'll move it under a visible section.*
