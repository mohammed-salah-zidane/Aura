<div align="center">

# Aura

**Weather in a new light.**

A weather app for iOS and Android in which the sky is the interface.
Every condition repaints the whole screen, so the app has told you what it is
doing outside before you have read a single number.

[![CI](https://github.com/mohammed-salah-zidane/Aura/actions/workflows/ci.yml/badge.svg)](https://github.com/mohammed-salah-zidane/Aura/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44.8-45D1FD?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart&logoColor=white)
![Tests](https://img.shields.io/badge/tests-946%20passing-2EA44F)
![Platforms](https://img.shields.io/badge/platforms-iOS%2015%2B%20%C2%B7%20Android%208%2B-555555)

<br>

<img src="docs/media/preview.gif" width="300" alt="Aura running on an iPhone, played at double speed">

<sub>One take on a real device against the live service, at double speed: a pre-dawn
sandstorm, city search, a National Weather Service flash-flood warning over New York,
fog in Brazil, and a clear night over Cairo. Each saved city wears its own sky at its
own local time.</sub>

</div>

---

## What ships

| Surface | What it shows |
|---|---|
| **Weather** | The hero reading, a day of hourly cells, six metric cards, a three-day preview, air quality, sun and moon, and an alert banner when one is active. Swipe between places; the sky crossfades with the condition. |
| **Forecast** | Every forecast day, each day's temperature range placed on one shared track so the days compare at a glance. |
| **Air quality** | The US EPA category, where today sits on the scale, and every pollutant behind it with its own band. |
| **Weather alert** | The active notice in the issuing service's own words: severity, window, areas, and what to expect. |
| **Sun & moon** | The arc the sun travels between rise and set, and the moon at tonight's phase and illumination. |
| **Search** | City autocomplete with a live reading beside every match, and a current-location shortcut. |
| **Saved cities** | The device's own position as the first row, then every place kept, each card on its own condition sky at its own local time. |
| **Settings** | Units that reshape every screen at once, notification switches that ask permission only at the moment of turning on, the data attribution, and the build number. |
| **Splash, permission, offline, loading** | Full-screen states, each with a way forward. Offline offers the stored reading and says how old it is. |

Both locales ship together: English and Arabic, right to left, transcreated rather
than translated. All nineteen screen frames in the design file are built, and the
skies cover eight live conditions from clear day to thunderstorm to fog.

---

## The one-minute tour of the internals

One request to WeatherAPI.com feeds the entire app. The response crosses four
explicit seams on its way to the screen: a DTO decoded in `aura_weather_api`, an
entity mapped in `aura_data`, a derived value computed in `aura_domain`, and a
design token resolved in `aura_design`. Any number on screen can be traced back
to the API field it came from in under a minute, and that traceability is the
project's own review bar.

Everything else in this README is detail on the layers that make that walk short.

---

## Architecture

The repository is a Melos-orchestrated pub workspace: one app, seventeen
packages, one shared dependency resolution. **Layer boundaries are enforced by
`pubspec.yaml` rather than by convention.** A package cannot import upward,
because the dependency edge does not exist. Adding one is an architecture
decision, and each unusual edge below carries its reason.

```
apps/aura                       composition root: DI wiring, router, platform adapters
   └── packages/features/*      home · search · saved_cities · settings · details · onboarding
          │
          ▼
      aura_domain               pure Dart. entities, ports, derived values
          ▲
          │
      aura_data                 repository implementations, DTO to entity mappers
        ├── aura_weather_api    endpoints and DTOs. returns DTOs, never entities
        │      └── aura_network Dio, interceptors, failure mapping. knows nothing about weather
        └── aura_storage        Drift cache and preferences, behind domain ports

      aura_core                 shared kernel: Result, AppFailure, Stale, units, Clock
      aura_design               every visual token and component. Flutter only, zero app logic
      aura_l10n · aura_ui · aura_providers · aura_test_kit      the shared seams, described below
```

| Package | Role | Tests |
|---|---|---:|
| `aura_core` | `Result`, the sealed `AppFailure`, `Stale<T>`, unit value objects, `Clock` | 186 |
| `aura_domain` | Entities, ports, and every derived value as a pure function | 183 |
| `aura_design` | Tokens, foundations, controls and composite components | 106 |
| `aura_data` | `WeatherRepositoryImpl` and the DTO-to-entity mappers | 68 |
| `aura_network` | Dio client, retry and redaction interceptors, failure mapping | 68 |
| `aura_weather_api` | The typed WeatherAPI.com SDK. Endpoints and DTOs only | 54 |
| `aura_storage` | Drift snapshot cache, saved cities, preference store | 52 |
| `aura_ui` | The seam between domain values and the design system | 23 |
| `aura_l10n` | All 165 user-visible strings, in both locales | 15 |
| `aura_providers` | The injection seams and the state features share | 11 |
| `aura_test_kit` | The widget-test harness every feature borrows | – |
| `features/home` | The pager, the hero, and the whole weather stack | 52 |
| `features/onboarding` | Splash and the location permission screen | 33 |
| `features/details` | Forecast, air quality, alert, sun and moon | 28 |
| `features/search` | Autocomplete with live readings | 18 |
| `features/settings` | Units, notifications, attribution, about | 17 |
| `features/saved_cities` | The city list with edit and forget | 16 |
| `apps/aura` | Composition root: DI, router, platform adapters, `AuraEnv` | 16 |
| **Total** | | **946** |

Three packages exist because of where the boundaries sit, and they are the part
of the layout worth reading twice:

- **`aura_providers`** declares one Riverpod provider per domain port and leaves
  each unimplemented; the composition root overrides them all in the root
  `ProviderScope`. That is dependency inversion expressed in the container: a
  feature only ever sees the domain interface, and a test overrides the same
  seam the app wires.
- **`aura_ui`** holds what sits exactly between the domain and the design
  system: turning a condition into its sky, glyph and tint, turning a failure
  into localized copy with a recovery action, and formatting readings.
  `aura_design` may not import the domain and `aura_domain` may not import
  Flutter, so the table joining them lives above both.
- **`aura_l10n`** is copy as a package. Features cannot import the composition
  root, so strings living in the app would be unreachable from the screens that
  show them.

Features never import each other; navigation goes through the router in
`apps/aura`, and screens take callbacks so they stay testable without one.
Platform adapters (`DeviceLocation` over geolocator, `DeviceNotifications` over
flutter_local_notifications) live in the composition root and answer ports the
domain declares.

---

## State management

**Riverpod 3, hand-written providers, no code generation.** `AsyncNotifier` is
the ViewModel from Flutter's official architecture guidance, and Riverpod
doubles as the DI container, so there is no second registry. One ViewModel per
screen. Widgets hold no business logic: a `build` method never contains
`if (temp > 30)`.

The generator is absent for a verifiable reason rather than taste:
`riverpod_generator` requires `analyzer ^12`, and Flutter 3.44.8's own
`flutter_test` pins the workspace below that while `drift_dev` needs the
ceiling. The constraints cannot coexist, so the providers are written by hand.

Two pieces of shared state carry most of the app:

- **`placeFeedProvider`**, a family keyed by place. A place that has answered
  keeps its reading, so swiping back to it is instant, and the home pager warms
  the neighbouring pages so a swipe usually lands on data instead of a spinner.
  The `weatherFeedProvider` facade mirrors the active place's instance; home
  and all four detail screens read one provider, so five screens cost one
  request. Refresh invalidates the family instance itself, because
  invalidating the mirror would hand back the held reading.
- **Current location is one symbolic identity.** The pager's first page, the
  saved list's first row and the active place all point at the same reference;
  a GPS fix only changes what that reference resolves to. `LocationRef`
  equality keys on the query alone, the device fix lives in its own provider,
  and a refiner sharpens the resolution in the background. The screen never
  jumps to a different page because the fix arrived; the page it is on gets
  more precise.

The feed also records whether it reached the network by comparing the reading's
timestamp with the moment the request started. That flag, `isLive`, is what
separates the ready state from the "you are reading stored data" state, with no
staleness threshold guessed anywhere.

---

## Failure handling

`Result<T, AppFailure>`, end to end. **No exception crosses a layer boundary.**

`AppFailure` is sealed with eight cases: `NoConnection`, `Timeout`,
`InvalidCity`, `Unauthorized`, `RateLimited`, `ServerError`, `CacheMiss`,
`Unknown`. Mapping happens once, at the `aura_network` boundary, from
`DioException` and from WeatherAPI's own error body. The service's quirks are
absorbed there and nowhere else: code `1006` ("no matching location") arrives
as HTTP 400, so the body's code is parsed before the status is trusted; `2006`
maps to `Unauthorized`, `2007` to `RateLimited`.

Three behaviours follow from the type and are worth calling out:

- **`NoConnection` is derived from the request failing**, not from a
  connectivity API. A connectivity check reports "online" behind a captive
  portal; the request itself cannot be lied to.
- **The repository is network-first and falls back to cache only on
  `NoConnection`.** An invalid city, a spent quota and a rejected key are
  definite answers, and papering over them with yesterday's weather would hide
  a problem the user can act on. A cache miss during fallback is reported as
  the network failure that caused the lookup, since that is the thing the user
  can fix. A failed cache write never fails a successful fetch.
- **Every failure a user sees carries localized copy and a recovery action.**
  The offline screen's pair, "Try Again" and "Use Saved Data", is the reference
  implementation; stored readings carry `fetchedAt`, so the screen admits how
  old the data is instead of presenting it as current.

---

## One request, honestly rendered

```
GET /forecast.json?q={place}&days=3&aqi=yes&alerts=yes&lang={locale}
```

That single call returns current conditions, three forecast days with their
hours and astronomy, air quality, and any active alerts. `astronomy.json` is
never called, because the same `astro` object is already in the response.
`days=14` returns 3 on the free tier with HTTP 200 and no warning, so 3 is what
is asked for. `search.json` powers autocomplete, `current.json` puts a live
temperature beside each match, and `q=auto:ip` resolves an approximate place
with no GPS permission, which is what makes "Enter City Manually" a real path
instead of a dead end. Every claim in [docs/WEATHER_API.md](docs/WEATHER_API.md)
was verified against the live service, and the response fixtures in the test
suite were captured from it, never hand-written.

The strictest rule in the codebase governs what may appear on screen: **a value
is legal only if WeatherAPI returned it, or a published scale or arithmetic was
applied to something WeatherAPI returned.** The WHO bands over `uv`, the US EPA
category the service itself returns, daylight as sunset minus sunrise, the
range-bar geometry as fractions of the week's span.

Holding that line meant removing things the design drew:

- The narrative sentence under the hero had no field behind it. It is gone.
- Descriptor slots with a real field behind them render the field: the wind
  card's sub-line is `wind_dir` and `gust_kph`, humidity's is `dewpoint_c`,
  pressure shows dual units instead of a trend the API does not provide.
- Per-pollutant bands follow the **European Air Quality Index**, which is
  published in the µg/m³ the service returns. The EPA's pollutant breakpoints
  are in ppm and ppb and would need an assumed temperature and pressure to
  convert; the design's own labels match the European bands anyway. The overall
  category stays EPA because the service returns that index directly.
- **Carbon monoxide keeps its row and loses its chip.** No published index
  covers CO in µg/m³, so it renders as a value with a unit and no descriptor.

Condition text is `current.condition.text` with the active locale passed as
`lang`, so it arrives in Arabic from the service rather than from a local
lookup table. All of the derivation lives in `aura_domain` as pure,
deterministic functions (`uv_band`, `air_quality_scales`, `sun_geometry`,
`moon_phase`, `range_bar_geometry`, `hourly_window`, `aura_condition`), which
makes it the cheapest surface in the repository to test exhaustively, and it is.

---

## Caching and notifications

`aura_storage` persists three things behind domain ports: the last snapshot per
place (Drift, stored as entities rather than the wire response, so a cached
read never depends on DTO shape), the saved-city list, and preferences. An
unreadable cache row reports a miss rather than a failure, so a corrupt row
costs one refetch instead of an error screen.

The daily forecast is a real schedule, placed through the platform's zone
database (`flutter_timezone` plus `timezone`), because a UTC offset is wrong
for half the year anywhere with daylight saving. Switching it off cancels it;
switching it on again replaces it rather than stacking a second. The alert
channel is registered beside it, and the severe-alert and precipitation
switches persist their preference behind the same flow. Notification
permission is requested when the user switches something on, never at first
launch, so a cold start never opens with a prompt the user has no context for.

---

## Design system

`aura.pen` is the design source of truth, and `aura_design` owns every visual
value read out of it: colours, thirteen sky gradients, a full type scale,
46 Lucide glyphs, spacing, radii, shadows, and motion durations. No literal
colour, size or duration appears anywhere else in the repository; a standing
set of audit greps holds that count at zero. The palette is one
condition-driven theme. The sky is the theme, so there is no light-mode fork
to maintain.

Some choices that are easy to miss from the outside:

- **Controls are built on `GestureDetector` and `EditableText`, not Material
  widgets.** Material ships track geometry, ripples and platform variance that
  would all have to be overridden back out to match the design.
- **No `BackdropFilter`.** The glass is flat translucency by design, and a blur
  behind every card would cost a full-screen read-back per frame on scrolling
  lists.
- **Every screen has two background fills.** The linear gradient and a radial
  bloom above it. The bloom is invisible in the design file's JSON unless you
  read past the first fill layer, and shipping without it loses the light
  source the whole look is built around.
- Loading is always the `AuraSkeleton` shimmer; a spinner appears only for an
  action already in flight.

### Fonts

Five families ship as bundled variable TTFs: Fraunces for display, Outfit for
values, Inter for labels, with Noto Kufi Arabic and Noto Sans Arabic behind
them. `google_fonts` is absent on purpose, since it fetches over HTTP on first
use, which breaks offline rendering and makes goldens non-deterministic.

Weight is driven through `fontVariations`, never `fontWeight`. The axis
defaults are wrong for this design (Fraunces wakes up at `wght 900`, Outfit at
`wght 100`), and setting both stacks a synthetic bold on the real axis. None of
the three Latin families contains one Arabic glyph, verified by parsing their
cmap tables, so the Noto faces back them as `fontFamilyFallback`, which
resolves per glyph and keeps Latin digits in the primary face mid-sentence.
The bundled licenses are registered with Flutter's `LicenseRegistry`, and the
app icon for both platforms is rendered from the same painter that draws the
splash mark (`flutter test --tags icons` writes every required slot).

---

## Arabic is a first-class build

- All 165 strings exist in both ARB files, and the Arabic reads as though it
  was written in Arabic. Placeholders survive and sit naturally in the
  sentence.
- Thirteen styles in the type scale carry letter-spacing. Arabic is cursive and
  tracking prises the joins apart, so every tracked style passes through
  `forScript(context)`, which zeroes it under RTL.
- Arabic ships as `ar`, so digits stay Western in both locales. This was the
  decision with the widest blast radius: `ar_EG` would format the 98-point hero
  temperature in Arabic-Indic digits that no bundled Latin face carries,
  handing the largest type on screen to a fallback font. A device set to
  `ar-EG` still resolves to `ar`, which was confirmed on device, and a test
  pins the resolution order.
- RTL was verified by eye on both platforms, with screenshots read back:
  layouts mirror, letters stay joined, and mixed-direction lines resolve their
  bidi correctly.

---

## The details that took the longest

The home screen is where the polish budget went, and each of these is visible
in the preview above:

- The sun rides an arc anchored to the screen's shortest side and sweeps into
  place on the first reading; pull-to-refresh shows the Aura mark breathing
  beside the pager dots, because the sun now owns the top of the screen.
- The hero condenses into a floating bar as you scroll, and the page dissolves
  into the sky at both ends through a `ShaderMask`.
- Card titles pin while their section scrolls under them, via
  `SliverPersistentHeader`.
- Rain falls as drop heads with depth parallax and an eased, believable fall.
  Clear nights get a starfield.
- Swiping to a neighbouring city is usually instant, because the pager warms
  the pages either side and search warms a city's feed the moment it is saved.
- The saved list shows named rows immediately and fills each temperature as it
  lands through the shared feed family.

---

## Testing

946 tests across seventeen suites, green before every commit, with a coverage
gate in CI that excludes generated sources so the number measures this
repository rather than its generators.

| Layer | Tool | Bar |
|---|---|---|
| Domain, mappers, derived values | `test` | Exhaustive and table-driven. The bulk of the suite. |
| Repositories | `mocktail` | Success, every failure case, cache hit, cache miss, stale |
| ViewModels | `ProviderContainer` with overrides | No `BuildContext`, no widget pumping |
| Widgets | `flutter_test` | Every state: loading, error, empty, ready, both locales |
| Design system | Goldens | 393 by 852 design canvas, pinned fonts and pixel ratio |

The parts that make the suite trustworthy rather than merely large:

- **Fixtures are captured from the live service**, committed, and never edited
  by hand. The alert fixture carries four real simultaneous alerts.
- **Every dependency is an interface with a fake**, shared through
  `aura_test_kit` along with a pump harness that loads all five font families
  and the icon font. An unregistered icon font renders goldens with empty
  boxes that look like design decisions; the harness exists because that
  happened.
- **Goldens are generated on macOS and compared on macOS**, since a Linux
  runner's antialiasing fails every file. CI uploads failing goldens as
  artifacts so a diff is a download away.
- No test touches the network, and the suite runs with a placeholder
  credential.

CI runs three jobs: analysis, formatting and the full suite with the coverage
gate on Ubuntu; goldens on macOS; and debug builds of both the Android APK and
the iOS simulator app, so "it analyzes" is never mistaken for "it builds".

---

## Running it

```bash
dart pub global activate melos 7.8.1     # 7.8.x exactly; see the pins below
export PATH="$PATH:$HOME/.pub-cache/bin"

melos bootstrap                          # install and link every package
melos run gen && melos run gen:l10n      # generated sources are gitignored
cp env/example.json env/dev.json         # put a WeatherAPI.com key in it

cd apps/aura
flutter run --dart-define-from-file=../../env/dev.json
```

The credential is read at compile time through `String.fromEnvironment`. A
runtime `.env` asset would ship the key inside the app package where anyone who
unzips it can read it, so there is none. `env/` is gitignored and CI injects
the key from a repository secret.

```bash
melos run ci        # gen, l10n, format, analyze, test. Green before any commit.
melos run gold      # golden tests only
melos run coverage  # tests with coverage; ./tool/coverage_gate.sh checks the bar
```

While iterating, scope the loop instead of running the world:

```bash
melos exec --scope=aura_domain -- dart test
flutter test test/foo_test.dart --plain-name 'maps 1006'
```

Never run `flutter pub get` inside a single package; `melos bootstrap` owns
linking.

---

## Version pins that look wrong and are not

Flutter 3.44.8's `flutter_test` pins `meta 1.18.0`, which caps the whole
workspace at `analyzer <13.0.0`. Everything below follows from that, and each
pin carries the same explanation in its `pubspec.yaml`.

| Pin | Reason |
|---|---|
| `melos >=7.8.0 <7.8.2` | 7.8.2+ needs `cli_util ^0.5.0`; `drift_dev` at the ceiling needs `^0.4.0` |
| `drift_dev >=2.34.0 <2.34.1` | 2.34.1+ requires `analyzer ^13`, above the SDK ceiling |
| no `riverpod_generator` | Requires `analyzer ^12`, mutually exclusive with `drift_dev` |
| `meta ^1.18.0`, `intl ^0.20.2` | Match the SDK's own pins exactly |

Revisit them together when Flutter's bundled `meta` moves.

---

## Documentation

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) covers the layer graph, state
  management and failure handling in full.
- [docs/WEATHER_API.md](docs/WEATHER_API.md) is the verified API contract,
  including the places where the live service contradicts its documentation.
- [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) records the token values, type scale and
  component specs extracted from the design file.
