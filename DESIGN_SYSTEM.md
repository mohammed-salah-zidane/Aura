# Aura — Design System

> **Weather in a new light.**
> Implementation source of truth for the Aura Flutter weather app.
> Design file: `aura.pen` (the "Aura Design System" board sits above the screens).
> Data source: [WeatherAPI.com](https://www.weatherapi.com) — free tier only.

---

## 1. Brand

| Element | Spec |
|---|---|
| Name | **Aura** |
| Tagline | *Weather in a new light* |
| Logo | Glowing orb + two concentric "aura" rings. Core: radial `#FFF7E0 → #FBC66A → #EF9E30`, rings `#FFE9C2` @ 60% / 85% opacity, outer glow `#FFD68A` fading to transparent |
| Motif | The radial glow recurs everywhere: splash, sky gradients, sun-path arc, brand bar mark |
| Voice | Calm, precise, human. Weather described in full sentences ("Hot and dry for the next three days…") |

## 2. Color Tokens

Token names map 1:1 to the `.pen` variables — use the same names in Flutter (e.g. `AuraColors.textPrimary`).

### Core

| Token | Value | Usage |
|---|---|---|
| `text-primary` | `#FFFFFF` | Headlines, values |
| `text-secondary` | `#FFFFFFD1` (82%) | Body, conditions |
| `text-tertiary` | `#FFFFFF96` (59%) | Labels, captions, icons |
| `glass` | `#FFFFFF1A` (10%) | Card / panel fill |
| `glass-2` | `#FFFFFF26` (15%) | Elevated glass (hover/active) |
| `border` | `#FFFFFF3B` (23%) | 1px inner strokes on glass |
| `grid` | `#FFFFFF14` (8%) | Hairlines, dividers, chart gridlines |
| `accent` | `#FFD68A` | Gold — live data, primary buttons, selection |
| `aura-core` | `#FBC66A` | Logo core |
| `aura-ring` | `#FFE9C2` | Logo rings |
| `alert` | `#FF8A5B` | Warnings (banner tint `#FF8A5B26`, stroke `#FF8A5B66`) |
| `ink` | `#0F141A` | Instrument-screen surface |
| `ink-2` | `#0B0E12` | Instrument deep surface / chart chips |

### Semantic scales

- **UV / AQI scale** (left→right): `#5CD97E` 0% → `#F4CE3B` 33% → `#F5883A` 50% → `#EF4B4B` 70% → `#A970C9` 100%
- **Temperature range bar** (cold→hot): `#86B7E8 → #F4C56A`
- **Rain probability text**: `#8FC0EE`
- **Condition icon tints**: sun `#FFD46A` · cloud-sun `#EAF1F8` · cloud `#E0E7EF` · rain `#8FC0EE`/`#A9D3F0` · lightning `#CDB9F5` · snow `#FFFFFF`/`#EAF2F8` · fog `#D6DEE4` · moon `#FFE9B0` · sunset `#FFB27A`

### Condition skies (vertical linear gradients, top→bottom)

The background **is** the weather — each condition swaps the screen gradient (+ a soft radial glow near the top).

| Condition | Stops |
|---|---|
| Clear Day | `#0E3C7A → #295F9F → #5589B8 → #9C9482 → #E4AE5C` |
| Partly Cloudy | `#2C6BAA → #4E86BC → #6E97B4 → #88A6B8` |
| Overcast | `#3B4956 → #4E5E6C → #65747F` |
| Rain | `#1E2A34 → #2F4456 → #486074` |
| Thunderstorm | `#141620 → #242840 → #3A3050` |
| Snow | `#3E5A72 → #557A93 → #6E8CA0` |
| Clear Night | `#090D26 → #141C40 → #22305C` (+ starfield dots) |
| Fog | `#4E585F → #616B72 → #7B858C` |
| System / Brand (states, search, settings) | `#0E3C7A → #1E568F → #2A6A9E` |
| Instrument (dark dashboard) | `#141A21 → #0E1319 → #0A0D11` |

## 3. Typography

Three families (all on Google Fonts / `google_fonts` package):

- **Fraunces** — display serif. The identity. Big temperatures, city names, screen titles, card titles.
- **Outfit** — geometric sans. Values, conditions, in-card UI.
- **Inter** — system sans. Labels, body, captions, status bar.

| Style | Font | Weight | Size / LH | Tracking | Sample |
|---|---|---|---|---|---|
| Display | Fraunces | 300 | 98 / 1.05 | — | `35°` |
| H1 City | Fraunces | 500 | 34 | — | `Cairo` |
| H2 Screen title | Fraunces | 500 | 24 | — | `3-Day Forecast` |
| H3 Card title | Fraunces | 500 | 20–22 | — | `Waxing Crescent` |
| Value | Outfit | 300 | 29 | — | `1013` |
| Condition | Outfit | 400 | 20 | — | `Mostly Sunny` |
| Body | Inter | 400 | 14 / 1.45 | — | summaries |
| Label | Inter | 600 | 12 | +1.4 | `AIR QUALITY` |
| Caption | Inter | 500 | 11 | — | `SAT 25 JUL · UPDATED 2:34 PM` |
| Kicker | Inter | 600 | 11 | +2.0 | `CAIRO, EGYPT` |

## 4. Layout, Shape & Elevation

- **Screen**: 393pt width. One content wrapper, horizontal padding **20**, vertical gap **16–20** between sections.
- **Spacing**: 4pt grid — `4, 8, 12, 16, 20, 24, 32`.
- **Radius**: `14` chips/fields · `18` list rows · `22` cards · `24–26` panels · `999` pills, buttons-capsule, toggles.
- **Glass recipe**: fill `glass` + 1px inner stroke `border` + shadow.
- **Elevation**: panel `0 10 30 -8 #08213F55` · tile `0 8 22 -6 #08213F55` (instrument screens use `#00000066`).
- **Icons**: [Lucide](https://lucide.dev) only. Conditions 22–26, UI/metrics 15–18 (`text-tertiary`), status 18.

## 5. Components (14 reusable in `aura.pen`)

| Component | Anatomy / spec |
|---|---|
| `Aura / Mark` | 64pt logo (scale to 24–132). Glow → outer ring 60% → mid ring 85% → core gradient → specular dot |
| `Aura / Button Primary` | Gold `accent` fill, r16, pad 15×24, optional 17pt icon, Outfit 600 15 on `#0E2A44` |
| `Aura / Button Secondary` | Glass recipe, r16, Outfit 500 15 `text-primary` |
| `Aura / Pill Live` | Glass capsule, 7pt gold dot + Inter 700 11 +1.2 gold label |
| `Aura / Chip` | Glass capsule, pad 7×12, Inter 500 12 `text-secondary` |
| `Aura / Toggle On·Off` | 46×28 capsule; on = gold fill, knob right; off = `#FFFFFF1F` + border, knob left; 22pt white knob |
| `Aura / Search Field` | Glass r14, pad 13×16, 18pt search icon + Outfit 400 15 `text-tertiary` placeholder |
| `Aura / Settings Row` | Glass r18; 28pt icon tile (`#FFFFFF1A`, r9) + Outfit 500 15 label ··· Inter 400 14 value + chevron |
| `Aura / Alert Banner` | `alert`-tinted glass r16; warn icon `#FFC08A`, Inter 600 14 title, 12 sub, chevron |
| `Aura / Metric Card` | 172×116 glass r22; label row (15pt icon + Label style) top, Value 29 + sub bottom. UV variant adds 4pt scale bar |
| `Aura / Hour Cell` | Vertical: Outfit 13 time · 26pt tinted icon · Outfit 500 17 temp. "Now" = weight 600 |
| `Aura / Forecast Day Row` | h54: day(46) · icon(22) · rain%(34, `#8FC0EE`) · lo(34, tertiary) · range bar (h6 track `#FFFFFF2B`, cold→hot segment positioned min→max) · hi(30, 600) |
| `Aura / City Card` | 400×116 r22, condition-sky gradient fill; city (Fraunces 22) + local time / condition left, Fraunces 300 42 temp + H/L right |

Composite patterns built from these: hourly strip (summary + divider + 6 hour cells), metric grid (2-col), AQI card (EPA category + scale + note), Sun & Moon card (sun-path arc + moon phase), instrument dials (compass, barometer).

## 6. Screens in `aura.pen` (~22)

Splash · Home flagship (Weather · Cairo: brand bar → alert banner → hero → hourly → metric grid → 3-day preview → AQI → Sun & Moon → bottom bar) · Weather · Instrument (dark variant) · 7 condition variants (Partly Cloudy, Overcast, Rain, Thunderstorm, Snow, Clear Night, Fog) · States: Loading (skeleton), Permission, Offline (cached-data note), Search, Saved Cities, Settings · Details: 3-Day Forecast, Air Quality, Weather Alert, Sun & Moon · Design System board.

## 7. WeatherAPI Mapping (hard constraint)

**Rule: no UI element may show data WeatherAPI doesn't return.** Free tier = 3 forecast days.

| UI | Endpoint / field |
|---|---|
| Hero temp, condition, H/L | `forecast.json` → `current.temp_c`, `condition.text/icon`, `forecastday[0].day.maxtemp_c/mintemp_c` |
| Feels like / wind / gusts / humidity / dew / pressure / visibility / UV | `current.feelslike_c, wind_kph, wind_dir, gust_kph, humidity, dewpoint_c, pressure_mb, pressure_in, vis_km, uv` |
| Hourly strip + rain % | `forecastday[].hour[]` → `temp_c, condition, chance_of_rain` |
| 3-Day rows | `forecastday[].day` → min/max, `daily_chance_of_rain`, condition |
| Air Quality | `&aqi=yes` → `air_quality` → **`us-epa-index` (1–6)** + `pm2_5, pm10, o3, no2, so2, co` |
| Alerts banner + detail | `&alerts=yes` → `alerts.alert[]` → `event, severity, category, effective, expires, areas, desc, instruction` |
| Sun & Moon | `forecastday[].astro` → `sunrise, sunset, moonrise, moonset, moon_phase, moon_illumination` |
| Search results | `search.json` (+ optional per-result `current.json` for temps) |
| Local times | `location.localtime`, `tz_id` |

**Deliberately excluded (API doesn't provide):** radar/map tiles, minute-by-minute precipitation, pressure *trend* (show dual units `1013 hPa · 29.92 inHg` instead), US-AQI 0–500 number (show EPA index category), historical averages. Bottom bar left action = **search**, not map.

## 8. Flutter Implementation Notes

```yaml
# pubspec.yaml
dependencies:
  google_fonts: ^6.2.1   # Fraunces, Outfit, Inter
  lucide_icons: ^0.257.0 # or lucide_icons_flutter
```

- **Tokens** → one `aura_theme.dart`: `AuraColors` (values above), `AuraText` (`GoogleFonts.fraunces/outfit/inter` styles from §3), `AuraRadii`, `AuraShadows`, `AuraGradients.forCondition(code, isDay)`.
- **Glass card** → `Container(decoration: BoxDecoration(color: Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(22), border: Border.all(color: Color(0x3BFFFFFF)), boxShadow: [...]))`. Avoid `BackdropFilter` on scrolling lists (perf) — flat translucency matches the design.
- **Sky** → map WeatherAPI `condition.code` + `is_day` to a condition enum → gradient + icon tint set; animate switches with `AnimatedContainer`/`TweenAnimationBuilder` (~600ms easeOut).
- **Range bar math** → week min/max span; segment `left = (dayMin−weekMin)/span`, `width = (dayMax−dayMin)/span` of track.
- **Skeleton** → shimmer rectangles `#FFFFFF10 → #FFFFFF1F → #FFFFFF10`, r16–26.
- Status time in mocks is `2:34`; screens are 393-wide, content height flows (single scroll view).
