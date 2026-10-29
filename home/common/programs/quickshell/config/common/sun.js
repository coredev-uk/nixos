.pragma library

// Sunrise and sunset for the local day containing `day`, at lat/lon in degrees (east positive),
// from the sunrise equation. Null where the sun doesn't rise or set that day.
function events(day, lat, lon) {
    const rad = Math.PI / 180;
    const noon = new Date(day.getFullYear(), day.getMonth(), day.getDate(), 12);
    const n = Math.round(noon.getTime() / 86400000 + 2440587.5 - 2451545.0 + 0.0008);
    const meanNoon = n - lon / 360;
    const anomaly = (357.5291 + 0.98560028 * meanNoon) % 360;
    const centre = 1.9148 * Math.sin(anomaly * rad) + 0.02 * Math.sin(2 * anomaly * rad) + 0.0003 * Math.sin(3 * anomaly * rad);
    const longitude = (anomaly + centre + 180 + 102.9372) % 360;
    const transit = 2451545.0 + meanNoon + 0.0053 * Math.sin(anomaly * rad) - 0.0069 * Math.sin(2 * longitude * rad);
    const sinDecl = Math.sin(longitude * rad) * Math.sin(23.4397 * rad);
    const cosDecl = Math.cos(Math.asin(sinDecl));
    const cosHour = (Math.sin(-0.833 * rad) - Math.sin(lat * rad) * sinDecl) / (Math.cos(lat * rad) * cosDecl);
    if (cosHour < -1 || cosHour > 1)
        return null;
    const hour = Math.acos(cosHour) / rad;
    const toDate = julian => new Date((julian - 2440587.5) * 86400000);
    return {
        rise: toDate(transit - hour / 360),
        set: toDate(transit + hour / 360)
    };
}

// The next sunrise or sunset after `now`: { label, time }, or null.
function next(now, lat, lon) {
    const today = events(now, lat, lon);
    if (today && now < today.rise)
        return { label: "Sunrise", time: today.rise };
    if (today && now < today.set)
        return { label: "Sunset", time: today.set };
    const tomorrow = events(new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1), lat, lon);
    return tomorrow ? { label: "Sunrise", time: tomorrow.rise } : null;
}
