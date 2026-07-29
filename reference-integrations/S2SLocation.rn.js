/* ══════════════════════════════════════════════════════════════════════════
   S2S — React Native attendance location module
   Based on the code you shared, tightened for production use.

   npm i react-native-geolocation-service react-native-device-info

   iOS   — Info.plist needs NSLocationWhenInUseUsageDescription
   Android — AndroidManifest.xml needs ACCESS_FINE_LOCATION
             (and ACCESS_COARSE_LOCATION, which Android 12+ requires
             alongside it or the fine-location prompt is refused)
   ═════════════════════════════════════════════════════════════════════════ */

import Geolocation from 'react-native-geolocation-service';
import DeviceInfo from 'react-native-device-info';
import { Platform, PermissionsAndroid, Alert } from 'react-native';

/* ── Offices ───────────────────────────────────────────────────────────────
   Keep these in sync with the portal's office list (Attendance → Offices).
   Best practice: fetch them from the API at app start rather than hard-coding,
   so a corrected pin doesn't require an app-store release.                   */
export const OFFICES = [
  {
    id: 'hq',
    name: 'Slum2School Headquarters',
    address: '13 Babatope Bejide Crescent, off Fola Osibo Rd, Lekki Phase 1, Lagos 105102',
    lat: 6.443385,
    lng: 3.476079,
    radius: 20,            // metres
  },
  {
    id: 'ecd',
    name: 'Slum2School Early Childhood Development Center',
    address: 'Makoko, Yaba, Lagos',
    lat: 6.4312,
    lng: 3.4116,
    radius: 20,
  },
];

/* ── Permissions ────────────────────────────────────────────────────────── */
export async function requestLocationPermission() {
  if (Platform.OS === 'ios') {
    const status = await Geolocation.requestAuthorization('whenInUse');
    return status === 'granted';
  }
  // Android 12+ will silently refuse FINE unless COARSE is requested with it
  const res = await PermissionsAndroid.requestMultiple([
    PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
    PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION,
  ]);
  return res['android.permission.ACCESS_FINE_LOCATION'] === 'granted';
}

/* ── Haversine distance in metres ───────────────────────────────────────── */
export function distanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371000;
  const toRad = d => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

/* ── Best-of-N fix ─────────────────────────────────────────────────────────
   getCurrentPosition returns the FIRST fix the OS offers, which is often the
   cell-tower/wifi estimate with 500–2000 m of error — this is the single
   biggest cause of "the GPS is not accurate". watchPosition instead lets the
   GPS converge: we keep the most accurate reading seen inside the budget and
   stop early once the phone reports better than `goodEnough` metres.        */
export function getBestFix({ budgetMs = 10000, goodEnough = 15 } = {}) {
  return new Promise((resolve, reject) => {
    let best = null;
    let done = false;
    let watchId = null;

    const finish = () => {
      if (done) return;
      done = true;
      if (watchId !== null) Geolocation.clearWatch(watchId);
      best ? resolve(best) : reject(new Error('No GPS fix within budget'));
    };

    watchId = Geolocation.watchPosition(
      pos => {
        if (!best || pos.coords.accuracy < best.coords.accuracy) best = pos;
        if (best.coords.accuracy <= goodEnough) finish();
      },
      err => { if (!best) { done = true; reject(err); } },
      {
        enableHighAccuracy: true,
        distanceFilter: 0,
        interval: 1000,
        fastestInterval: 500,
        forceRequestLocation: true,
        showLocationDialog: true,
      },
    );

    setTimeout(finish, budgetMs);
  });
}

/* ── The clock-in check ────────────────────────────────────────────────── */
export async function checkInLocation({ officeId, maxAccuracy = 60 } = {}) {
  const ok = await requestLocationPermission();
  if (!ok) throw new Error('Location permission denied');

  /* Anti-cheat: refuse a mock/fake-GPS position outright. This is the one
     capability the mobile app has that the browser does not — keep it.      */
  if (await DeviceInfo.isMockLocation?.()) {
    throw new Error('Mock location detected — clock-in blocked');
  }

  const pos = await getBestFix();
  const { latitude, longitude, accuracy } = pos.coords;

  /* A fix with 800 m of error can "pass" a 20 m fence by luck. Reject the
     reading itself rather than trusting it.                                 */
  if (accuracy > maxAccuracy) {
    throw new Error(
      `GPS accuracy is only ±${Math.round(accuracy)} m. Step outside or near a ` +
      `window and try again.`,
    );
  }

  const candidates = (officeId ? OFFICES.filter(o => o.id === officeId) : OFFICES)
    .map(o => ({ office: o, distance: distanceMeters(latitude, longitude, o.lat, o.lng) }))
    .sort((a, b) => a.distance - b.distance);

  const nearest = candidates[0];
  const withinFence = nearest && nearest.distance <= nearest.office.radius;

  return {
    latitude,
    longitude,
    accuracy,
    office: nearest?.office ?? null,
    distance: nearest ? Math.round(nearest.distance) : null,
    withinFence,
    deviceId: await DeviceInfo.getUniqueId(),
    timestamp: new Date().toISOString(),
  };
}

/* ── Sync to the backend ───────────────────────────────────────────────────
   Always send latitude, longitude, accuracy, deviceId and the office the app
   believes it matched — and re-run the fence check server-side. A client that
   only posts "withinFence: true" can be edited by anyone with a proxy.      */
export async function syncAttendance(apiBase, token, payload) {
  const r = await fetch(`${apiBase}/api/attendance/clock`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify(payload),
  });
  if (!r.ok) throw new Error(`Clock-in failed (${r.status})`);
  return r.json();
}

/* ── Usage ─────────────────────────────────────────────────────────────────
   try {
     const fix = await checkInLocation({ officeId: 'hq' });
     if (!fix.withinFence) {
       Alert.alert('Too far', `You are ${fix.distance} m from ${fix.office.name}.`);
       return;
     }
     await syncAttendance(API, token, fix);
   } catch (e) {
     Alert.alert('Clock-in', e.message);
   }
   ═════════════════════════════════════════════════════════════════════════ */
