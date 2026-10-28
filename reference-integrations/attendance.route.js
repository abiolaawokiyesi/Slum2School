// S2S Attendance — server-side geofence verification (Express)
// Reference route for a separate Node backend. Exact 100m fences.
const express = require('express');
const router = express.Router();

const OFFICE_GEOFENCES = [
  { id: 'hq',  name: 'Slum2School Headquarters',                      lat: 6.443385, lng: 3.476079, radiusMeters: 200 },
  { id: 'ecd', name: 'Slum2School Early Childhood Development Center', lat: 6.4312, lng: 3.4116, radiusMeters: 200 }
];

// Haversine distance (metres)
function getDistanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371e3;
  const phi1 = lat1 * Math.PI / 180, phi2 = lat2 * Math.PI / 180;
  const dPhi = (lat2 - lat1) * Math.PI / 180, dLambda = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dPhi/2)**2 + Math.cos(phi1)*Math.cos(phi2)*Math.sin(dLambda/2)**2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

router.post('/api/attendance/clock', async (req, res) => {
  const { staffId, type, lat, lng } = req.body;
  let verifiedOffice = null, best = Infinity;
  for (const office of OFFICE_GEOFENCES) {
    const distance = getDistanceMeters(lat, lng, office.lat, office.lng);
    if (distance <= office.radiusMeters && distance < best) { verifiedOffice = office; best = distance; }
  }
  if (!verifiedOffice) {
    return res.status(400).json({ success: false, message: 'Clock-in failed: You must be physically present at a designated Slum2School office.' });
  }
  // TODO: insert into your DB, e.g. Supabase attendance table:
  //   { staff_id: staffId, work_date: today, clock_in/clock_out: now,
  //     location_id: verifiedOffice.id, location_name: verifiedOffice.name, lat, lng }
  return res.json({ success: true, officeId: verifiedOffice.id, distanceMeters: Math.round(best),
    message: `Successfully clocked ${String(type).toLowerCase()} at ${verifiedOffice.name}.` });
});

module.exports = router;
