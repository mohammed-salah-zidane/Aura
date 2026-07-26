# WeatherAPI.com — the contract Aura relies on

Every statement here was verified by calling the live API on 2026-07-26 with the
project key, not by reading the documentation. Several of these facts contradict
a naive reading of the docs.

Base URL: `https://api.weatherapi.com/v1`

---

## One call feeds the whole home screen

```
GET /forecast.json?key=…&q={query}&days=3&aqi=yes&alerts=yes&lang={locale}
```

Returns, in a single response:

| Block | Contents |
|---|---|
| `location` | `name, region, country, lat, lon, tz_id, localtime, localtime_epoch` |
| `current` | 35 fields, including `temp_c, feelslike_c, condition{text,icon,code}, wind_kph, wind_dir, gust_kph, humidity, dewpoint_c, pressure_mb, pressure_in, vis_km, uv, is_day, air_quality` |
| `forecast.forecastday[]` | per day: `day{maxtemp_c, mintemp_c, daily_chance_of_rain, condition, uv, …}`, `astro{…8 fields}`, `hour[]` with 24 entries |
| `alerts.alert[]` | `event, severity, category, effective, expires, areas, desc, instruction` |

**Do not call `astronomy.json`.** The identical `astro` object is already inside
`forecastday[]`; calling it is a wasted request against the quota.

---

## Free-tier behaviour that will surprise you

- **`days=14` returns 3 days with HTTP 200.** No error, no warning, no field
  indicating truncation. Treat the 3-day cap as a capability of the tier, never
  as a failure to handle. Requesting more than 3 is pointless.
- `aqi=yes` and `alerts=yes` both work on free. `air_quality` carries
  `us-epa-index` (1–6) and `gb-defra-index` (1–10) alongside the raw
  `pm2_5, pm10, o3, no2, so2, co` concentrations.
- An empty `alerts.alert[]` means *no active alert*, not *unsupported*.

---

## Other endpoints in use

| Endpoint | Purpose |
|---|---|
| `search.json?q={prefix}` | City autocomplete. Returns `id, name, region, country, lat, lon, url`. |
| `current.json?q={…}` | Per-result temperature on the search screen, and per-city readings on saved cities. |

`q` accepts a city name, `lat,lon`, a postcode, an IATA code, or:

- **`q=auto:ip`** resolves an approximate location with **no GPS permission
  required**. This is what lets the permission screen offer a real "skip" path
  rather than a dead end.

`lang` returns a translated `condition.text` — verified with `lang=ar`, which
returns `صحو`. Pass the active app locale so condition text is never translated
locally.

---

## Errors

The body shape is always:

```json
{ "error": { "code": 1006, "message": "No matching location found." } }
```

| Code | HTTP | Meaning | Maps to |
|---|---|---|---|
| 1002 | 401 | API key not provided | `Unauthorized` |
| 1003 | 400 | `q` missing | `Unknown` (a programming error, not a user one) |
| 1005 | 400 | Invalid request URL | `Unknown` |
| 1006 | 400 | No matching location | `InvalidCity` |
| 2006 | 401 | API key invalid | `Unauthorized` |
| 2007 | 403 | Monthly quota exceeded | `RateLimited` |
| 2008 | 403 | API key disabled | `Unauthorized` |
| 9999 | 400 | Internal error | `ServerError` |

Note that **1006 arrives as HTTP 400, not 404**, so status code alone cannot
distinguish "city not found" from a malformed request. The body's `code` is the
only reliable signal, and must be parsed before the status is trusted.

---

## Fields the app deliberately never shows

The free tier does not return these, so no UI element may imply them:

radar or map tiles · minute-by-minute precipitation · pressure *trend* (the app
shows dual units, `1013 hPa · 29.92 inHg`, instead) · a US-AQI 0–500 number (the
app shows the EPA index category) · historical averages · pollen · marine data.

---

## Attribution

The free tier requires a visible link back to WeatherAPI.com. The Settings screen
carries it as the "Data Source" row, and the splash screen carries the
"POWERED BY WEATHERAPI.COM" line.
