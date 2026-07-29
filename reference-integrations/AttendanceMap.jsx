// S2S Attendance — live geofence map (React + Google Maps)
// Reference component for a separate React frontend. The shipped S2S People Portal
// (index.html) already implements the same 100m geofence with a built-in Leaflet map
// (no API key needed); use this only if you're building a separate React app and have
// a Google Maps API key.
//
// npm i @react-google-maps/api
import React, { useState, useEffect } from 'react';
import { GoogleMap, useJsApiLoader, Marker, Circle } from '@react-google-maps/api';

const mapContainerStyle = { width: '100%', height: '300px', borderRadius: '12px' };
const defaultCenter = { lat: 6.443385, lng: 3.476079 }; // Slum2School HQ, Lekki Phase 1

// Office geofences (200m). HQ coordinate is a best estimate — calibrate on-site.
const offices = [
  { id: 'hq',  name: 'Slum2School Headquarters',                      lat: 6.443385, lng: 3.476079, radius: 200 },
  { id: 'ecd', name: 'Slum2School Early Childhood Development Center', lat: 6.4312, lng: 3.4116, radius: 200 }
];

export default function AttendanceMap({ staffId }) {
  const { isLoaded } = useJsApiLoader({ id: 'google-map-script', googleMapsApiKey: 'YOUR_GOOGLE_MAPS_API_KEY' });
  const [userLocation, setUserLocation] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (navigator.geolocation) {
      const id = navigator.geolocation.watchPosition(
        (position) => { setUserLocation({ lat: position.coords.latitude, lng: position.coords.longitude }); setLoading(false); },
        (error) => { console.error('Error fetching location', error); setLoading(false); },
        { enableHighAccuracy: true, maximumAge: 0 }
      );
      return () => navigator.geolocation.clearWatch(id);
    }
  }, []);

  const handleAttendance = async (type) => {
    if (!userLocation) return alert('Location data not ready.');
    const response = await fetch('/api/attendance/clock', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ staffId, type, ...userLocation })
    });
    const data = await response.json();
    alert(data.message);
  };

  if (!isLoaded || loading) return <div>Loading Live Attendance Map…</div>;

  return (
    <div style={{ padding: '15px', background: '#f9f9f9' }}>
      <h3>Daily Attendance</h3>
      <GoogleMap mapContainerStyle={mapContainerStyle} center={userLocation || defaultCenter} zoom={16}>
        {userLocation && <Marker position={userLocation} label="You" />}
        {offices.map((office) => (
          <React.Fragment key={office.id}>
            <Marker position={{ lat: office.lat, lng: office.lng }} title={office.name} />
            <Circle center={{ lat: office.lat, lng: office.lng }} radius={office.radius}
              options={{ fillColor: '#1d4ed8', fillOpacity: 0.15, strokeColor: '#1d4ed8', strokeWeight: 1 }} />
          </React.Fragment>
        ))}
      </GoogleMap>
      <div style={{ marginTop: '15px', display: 'flex', gap: '10px' }}>
        <button onClick={() => handleAttendance('IN')}  style={{ backgroundColor: '#22c55e', color: 'white', padding: '10px 20px', border: 'none', borderRadius: '6px' }}>Clock In</button>
        <button onClick={() => handleAttendance('OUT')} style={{ backgroundColor: '#ef4444', color: 'white', padding: '10px 20px', border: 'none', borderRadius: '6px' }}>Clock Out</button>
      </div>
    </div>
  );
}
