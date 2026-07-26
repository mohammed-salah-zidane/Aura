# Aura

**Weather in a new light.**

A weather app for iOS and Android, built against WeatherAPI.com. The background
*is* the weather: every condition swaps the whole-screen sky, so the app tells
you what it is doing outside before you have read a word of it.

Flutter **3.44.8** · Dart **3.12.2** · iOS 15+ · Android 26+

---

## What it does

| Screen | What it shows |
|---|---|
| **Weather** | The hero reading, a day of hourly cells, six metric cards, a three-day preview, air quality, sun and moon, and an alert banner when one is active |
| **Forecast** | Every forecast day, each day's range placed on one shared track |
| **Air quality** | The US EPA category, where it sits on the scale, and every pollutant behind it |
| **Weather alert** | The active notice, in the issuing service's own words |
| **Sun & moon** | The arc the sun travels, and the moon at tonight's phase |
| **Search** | City autocomplete, with a live reading beside every match |
| **Saved cities** | The device's own position and every place kept, each on its own sky |
| **Settings** | Units that drive every screen at once, and real notifications |
| **Splash, permission, offline** | The three full-screen states, each with a way forward |

Both locales ship: English and Arabic, right to left, transcreated rather than
translated.

---

## Running it

```bash
dart pub global activate melos 7.8.1     # 7.8.x is pinned; see below
export PATH="$PATH:$HOME/.pub-cache/bin"

melos bootstrap                          # install and link every package
melos run gen && melos run gen:l10n      # generated sources are gitignored
cp env/example.json env/dev.json         # then put a WeatherAPI.com key in it

cd apps/aura
flutter run --dart-define-from-file=../../env/dev.json
```

The credential is read at compile time through `String.fromEnvironment`, never
from an asset: a runtime `.env` file would ship the key inside the app package
where anyone who unzips it can read it. `env/` is gitignored and CI injects the
key from a repository secret.

```bash
melos run ci        # gen, l10n, format, analyze, test. Green before any commit.
melos run gold      # golden tests only
melos run coverage  # tests with coverage; ./tool/coverage_gate.sh checks the bar
```

---

## How it is put together

A Melos-orchestrated pub workspace. **Layer boundaries are enforced by
`pubspec.yaml` rather than by convention** — a package physically cannot import
upward, because the dependency is not declared.

```
apps/aura                composition root ONLY — DI wiring, router, platform adapters
   └── features/*        home · search · saved_cities · settings · details · onboarding
          ├── aura_providers   the injection seams and the state features share
          ├── aura_ui          the seam between a domain value and the design system
          ├── aura_l10n        every user-visible string, in both locales
          ├── aura_design      Flutter only. zero app logic.
          └── aura_domain      pure Dart · entities · ports · derived values
                 ▲
            aura_data          repository implementations + DTO→entity mappers
              ├── aura_weather_api   endpoints and DTOs, returns DTOs only
              │      └── aura_network    Dio, interceptors, failure mapping
              └── aura_storage       Drift cache and preferences
            aura_core          Result, AppFailure, value objects, Clock
```

Three of those packages exist because a feature cannot import the composition
root and two packages below it cannot import each other:

- **`aura_providers`** declares one provider per domain port and leaves each
  unimplemented. `apps/aura` answers them all in the root `ProviderScope`. That
  is dependency inversion expressed in the container: a feature only ever sees
  the domain interface.
- **`aura_ui`** holds the two things that sit exactly on the seam between the
  domain and the design system: turning a reading into the copy a screen shows,
  and turning a condition into the sky, glyph and tint that stand for it.
  `aura_design` may not import the domain, and `aura_domain` may not import
  Flutter, so the table joining them lives above both.
- **`aura_test_kit`** is the widget-test harness every feature shares: five font
  families plus the icon font, the design canvas, and the fakes.

### State management

**Riverpod 3, without code generation.** `AsyncNotifier` *is* the ViewModel from
Flutter's official architecture guide, and Riverpod doubles as the DI container,
so there is no second registry. One ViewModel per screen, one to one with its
view; widgets hold no business logic.

The task brief names "Provider, Bloc or GetX". Riverpod is Provider's official
successor by the same author and satisfies the brief's intent: a single testable
source of UI state, injected rather than reached for.

Code generation is deliberately absent. `riverpod_generator` needs
`analyzer ^12`, while Flutter 3.44.8 caps the workspace below that and
`drift_dev` needs the ceiling. Those constraints are mutually exclusive, so the
providers are written by hand.

### Failure handling

`Result<T, AppFailure>`. **No exception crosses a layer boundary.** `AppFailure`
is sealed and mapped once, at the `aura_network` boundary, from `DioException`
and from WeatherAPI's own error codes. Every failure a user sees carries a
localized explanation and a way forward.

Cached reads carry when they were fetched. When the service cannot be reached
and a stored reading exists, the offline screen says how old it is and offers
it, rather than presenting yesterday's weather as today's.

### One call, not five

```
GET /forecast.json?q=…&days=3&aqi=yes&alerts=yes&lang=…
```

That single request feeds the whole weather screen and all four detail screens:
current conditions, three forecast days with their hours and astro, air quality
and alerts. `astronomy.json` is never called, because `astro` is already inside
`forecastday[]`. `days=14` silently returns 3 on the free tier, so 3 is what is
asked for.

`search.json` powers autocomplete, `current.json` puts a reading beside each
match, and `q=auto:ip` resolves an approximate position with no location
permission at all — which is what makes "Enter City Manually" a real
alternative rather than a dead end.

### Every rendered value traces to an API field

Nothing on screen is invented. A value is legal only if it is a field
WeatherAPI returns, or a **published scale** applied to one: the WHO ultraviolet
bands, the US EPA air quality categories, the European Air Quality Index bands
per pollutant, or arithmetic over a returned field.

That rule removed things the design drew. The narrative sentence under each hero
has no field behind it and is gone. Two metric sub-lines were qualitative
descriptions and are now empty rather than filled with a phrase the service
never sent. Carbon monoxide keeps its reading and loses its band, because no
published index covers it in the µg/m³ WeatherAPI reports.

The derivation layer therefore holds scales, unit conversion and geometry only.
It lives in `aura_domain` as pure, deterministic, I/O-free functions, and it is
the most heavily tested surface in the repository.

---

## Design

`aura.pen` is the design source of truth, read through the Pencil MCP rather
than by hand: computed layout, resolved variables and fill layers past the first
are all invisible in the raw file, and each of them had already caused a defect.

`aura_design` owns every visual value. No colour, size, radius, shadow, font,
icon or duration literal appears anywhere else in the repository. The palette is
one condition-driven theme rather than a light and dark pair — the sky is the
theme, so there is no light mode to add.

Fonts are bundled variable TTFs, and weight is driven through `fontVariations`
rather than `fontWeight`: the axis defaults are not the weights Aura uses, and
setting both invites a synthetic bold on top of the real axis value. None of the
three Latin families contains a single Arabic glyph, so two Noto Arabic families
back them as `fontFamilyFallback`, which resolves per glyph and leaves Latin
digits in the primary face.

The app icon is rendered from the same painter the splash screen draws its mark
with — `flutter test --tags icons` inside `apps/aura` writes every slot both
platforms ask for.

---

## Testing

| Layer | Bar |
|---|---|
| Domain, mappers, derived values | Exhaustive and table-driven. The bulk of the suite. |
| Repositories | Success, every failure, cache hit, cache miss, stale |
| ViewModels | `ProviderContainer` with overrides. No `BuildContext`, no pumping. |
| Widgets | Every state: loading, error, empty, ready, in both locales |
| Design system | Goldens at the 393 by 852 canvas, pinned fonts and pixel ratio |

Every dependency is an interface with a fake, and no test reaches the network.
Goldens are generated on macOS, so CI compares them on a macOS runner: a Linux
runner renders antialiasing differently enough to fail every file.

---

## Version pins that look wrong and are not

Flutter 3.44.8's `flutter_test` pins `meta 1.18.0`, which caps the whole
workspace at `analyzer <13.0.0`. Everything below follows from that.

| Pin | Reason |
|---|---|
| `melos >=7.8.0 <7.8.2` | 7.8.2+ needs `cli_util ^0.5.0`; `drift_dev` at the ceiling needs `^0.4.0` |
| `drift_dev >=2.34.0 <2.34.1` | 2.34.1+ requires `analyzer ^13` |
| no `riverpod_generator` | Requires `analyzer ^12`, mutually exclusive with `drift_dev` |
| `meta ^1.18.0`, `intl ^0.20.2` | Match the SDK's own pins exactly |

`google_fonts` is deliberately absent: it fetches over HTTP on first use, which
breaks offline rendering and makes goldens non-deterministic.

---

## Documentation

- `docs/ARCHITECTURE.md` — the layer graph, state management and failure handling
- `docs/WEATHER_API.md` — the API contract, verified against the live service
