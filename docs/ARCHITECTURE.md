# Aura — Architecture

Aura is a weather app for iOS and Android. `aura.pen` is the design source of
truth; this document is the structural one.

Flutter **3.44.8** · Dart **3.12.2** · iOS 15+ · Android API 26+ (compile/target 36)

---

## 1. Shape of the system

A Melos-orchestrated pub workspace. Every package resolves against one shared
lockfile, and **layer boundaries are enforced by `pubspec.yaml` rather than by
convention** — a package physically cannot import upward because the dependency
is not declared.

```
apps/aura                    composition root ONLY — DI wiring, router, platform config
   │
   └── packages/features/    home · search · saved_cities · settings · details · onboarding
          │
          ▼
      aura_domain            pure Dart · entities · repository + storage PORTS · use cases
          ▲
          │
      aura_data              repository IMPLS + DTO→entity mappers          (pure Dart)
        ├── aura_weather_api endpoints + DTOs, returns DTOs only            (pure Dart)
        │     └── aura_network   Dio client, interceptors, failure mapping  (pure Dart)
        └── (storage ports implemented by aura_storage, injected at the root)

      aura_storage           Drift cache + preferences, implements domain ports  (Flutter)
      aura_core              shared kernel: Result, AppFailure, value objects, Clock
      aura_design            Flutter only. zero app logic.
```

### Why the edges sit where they do

| Rule | Reason |
|---|---|
| `aura_domain` has zero Flutter and zero infrastructure dependencies | Testable in plain Dart, and it never bends to a framework's shape |
| `aura_domain` declares the ports; `aura_data` and `aura_storage` implement them | Dependency inversion. Domain never points at infrastructure |
| **Storage ports live in `aura_domain`, not `aura_storage`** | Keeps `aura_data` pure Dart, so repositories are unit-testable with no Flutter binding |
| `aura_weather_api` returns DTOs, never entities | Keeps the API SDK reusable and makes the mapping an explicit, testable step |
| `aura_network` knows nothing about weather | It is a general HTTP module, reusable in any project |
| Features never import each other | Cross-feature navigation goes through the router |
| Only `apps/aura` may import everything | It is the single composition root |

Adding a dependency edge to a `pubspec.yaml` is an architecture decision.

---

## 2. State management

**Riverpod 3, without code generation.**

`AsyncNotifier` *is* the ViewModel from Flutter's official architecture guide,
and Riverpod doubles as the DI container, so there is no second system such as
`get_it`. Code generation is deliberately absent: `riverpod_generator` pins
`analyzer ^12`, while Flutter 3.44.8 caps the workspace at `analyzer <13.0.0`
and `drift_dev` needs `^13`. Those constraints are mutually exclusive, so the
generator loses and the providers are written by hand.

```dart
class HomeViewModel extends AsyncNotifier<HomeUiState> { … }
```

- `ref.watch` in `build`, `ref.read` in callbacks, `ref.listen` for side effects.
- `autoDispose` by default; keep-alive only for genuinely global state.
- One ViewModel per screen, one-to-one with its View.
- Widgets hold no business logic. No `if (temp > 30)` inside a `build` method.

The task brief names "Provider, Bloc or Getx". Riverpod is Provider's official
successor by the same author, and satisfies the brief's intent: a single, testable
source of UI state, injected rather than reached for.

---

## 3. Failure handling

`Result<T, AppFailure>`. **No exception crosses a layer boundary.**

`AppFailure` is sealed:

```
NoConnection · Timeout · InvalidCity · Unauthorized · RateLimited ·
ServerError · CacheMiss · Unknown
```

Mapped once, at the `aura_network` boundary, from `DioException` and from
WeatherAPI's own error codes. Every failure shown to a user carries a localized
message **and a recovery action** — the Offline screen's "Try Again / Use Saved
Data" pair is the reference implementation.

`NoConnection` is derived from the request actually failing rather than from a
connectivity API, which is both more testable and more accurate: a connectivity
check reports "online" behind a captive portal.

Cached reads return `Stale<T>` carrying `fetchedAt`. That is what renders
"Last updated 2h ago".

---

## 4. Data flow

```
View → ViewModel → Repository → ┬→ WeatherApi → NetworkClient → WeatherAPI.com
                                └→ WeatherCache (Drift)
```

The repository is the only place that decides between network and cache. It
attempts the network, falls back to cache on `NoConnection`, and marks the result
stale so the UI can say so.

---

## 5. Derived values

Much of what the design shows is not a field WeatherAPI returns: UV bands, EPA
categories, pollutant categories, daylight duration, sun-arc angle, range-bar
geometry, unit conversion.

All of it lives in `aura_domain` as **pure, deterministic, I/O-free functions**
with table-driven tests. This is the highest-value test surface in the codebase.

**A value is only legal if it is either a field WeatherAPI returns, or a standard
published scale or arithmetic applied to one.** Authored prose is banned: no
narrative summaries, no invented descriptors. Where the design shows a descriptor
in a slot that has a real API field, the field is rendered — wind sub-line is
`wind_dir` + `gust_kph`, humidity is `dewpoint_c`, pressure is `pressure_in`.
Where no field exists for a slot, the slot is left empty.

Presentation takes the *result* of these functions, never the inputs: the range
bar receives `start` and `extent` as `0..1` fractions, so the geometry is tested
as a pure function and the widget is tested as layout, separately.

---

## 6. Design system

`aura_design` owns every visual value in the app, read from `aura.pen`. No
colour, size, radius, shadow, font or icon literal may appear anywhere else.

| Layer | Contents |
|---|---|
| Tokens | colours · 13 condition skies · shadows · type scale · spacing/radii/sizes · Lucide icons · motion |
| Foundations | `AuraSky` (crossfading, starfield on clear night) · `AuraGlass` |
| Controls | buttons · live pill · chip · toggle · search field · skeleton · mark |
| Composites | metric card · scale bar · forecast row · range bar · hour cell · city card · alert banner · settings row |

Notes that matter:

- **The background is the weather.** Each condition swaps the whole-screen
  gradient, so the sky is a piece of state, not decoration.
- **The palette is one condition-driven theme, not a light/dark pair.** There is
  no light-mode fork to add.
- Controls are built on `GestureDetector` and `EditableText` rather than
  Material, which ships track geometry, ripples and platform variance that would
  otherwise have to be overridden back out.
- No `BackdropFilter`. The design is flat translucency, and a blur behind every
  card costs a full-screen read-back per frame on scrolling lists.
- Fonts are bundled variable TTFs, and weight is driven through `fontVariations`
  rather than `fontWeight`. See §8.

---

## 7. Testing

| Layer | Tool | Bar |
|---|---|---|
| Domain, mappers, derived values | `test` | Exhaustive and table-driven. The bulk of the suite. |
| Repositories | `mocktail` | Success, every `AppFailure`, cache hit, cache miss, stale |
| ViewModels | `ProviderContainer` + overrides | No `BuildContext`, no pumping |
| Widgets | `flutter_test` | Every state: loading, error, empty, ready |
| Design system | golden | Pinned fonts and device pixel ratio |
| Flows | `integration_test` | Against a fake API server, never the live network |

Every dependency is an interface with a fake. Tests never reach the network.
Generated files are excluded from coverage.

---

## 8. Platform

- **iOS** uses Swift Package Manager, the Flutter 3.44 default. There is no
  Podfile and none should be reintroduced.
- **Android** keeps the Kotlin Gradle Plugin declaration in
  `settings.gradle.kts`. Several 3.44 write-ups say to remove it; the official
  3.44.8 template still declares it and removing it breaks the build.
- **Fonts** are bundled variable TTFs. The axis defaults are not the weights Aura
  uses — Fraunces defaults to `wght 900`, Outfit to `wght 100` — so weight is
  driven through `fontVariations`. Setting `fontWeight` as well invites a
  synthetic bold stacked on the real axis value.
- **Secrets** come from `--dart-define-from-file=env/dev.json`, read at compile
  time via `String.fromEnvironment`. `env/` is gitignored and `env/example.json`
  is committed. A runtime `.env` asset is never used, because that bundles the
  key into the shipped package.

---

## 9. Commands

```bash
dart pub global activate melos 7.8.1   # one-time; 7.8.x is pinned, see below
melos bootstrap                        # install and link every package
melos run analyze                      # static analysis, infos fatal
melos run test                         # unit and widget tests
melos run gold:update                  # regenerate goldens, review by eye
melos run ci                           # format + analyze + test

flutter run --dart-define-from-file=env/dev.json
```

Narrow loops while iterating:

```bash
melos exec --scope=aura_domain -- dart test
flutter test test/foo_test.dart --plain-name 'maps 1006'
```

Never run `flutter pub get` inside a single package — `melos bootstrap` owns
linking.

---

## 10. Deliberate version pins

Flutter 3.44.8's `flutter_test` pins `meta 1.18.0`, which caps the whole
workspace at `analyzer <13.0.0`. Everything below follows from that, and each
pin carries the same explanation in its `pubspec.yaml`.

| Pin | Reason |
|---|---|
| `melos >=7.8.0 <7.8.2` | 7.8.2+ needs `cli_util ^0.5.0`; `drift_dev` at the analyzer ceiling needs `^0.4.0` |
| `drift_dev >=2.34.0 <2.34.1` | 2.34.1+ requires `analyzer ^13`, above the SDK ceiling |
| `build_runner ^2.4.0` | Left loose so pub can pick a build under the analyzer ceiling |
| no `riverpod_generator` | Requires `analyzer ^12`, mutually exclusive with `drift_dev` |
| `meta ^1.18.0`, `intl ^0.20.2` | Match the SDK's own pins exactly |

Revisit all of these together when Flutter's bundled `meta` moves.
