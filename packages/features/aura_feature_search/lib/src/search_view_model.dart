import 'dart:async';

import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_search/src/search_ui_state.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The search screen's state.
final searchViewModelProvider =
    NotifierProvider<SearchViewModel, SearchUiState>(
      SearchViewModel.new,
      isAutoDispose: true,
    );

/// Runs autocomplete, then fills a temperature in beside each match.
///
/// Synchronous rather than an `AsyncNotifier`: the screen is never in one
/// loading state, because the names arrive before the readings do and the list
/// is worth showing in between.
final class SearchViewModel extends Notifier<SearchUiState> {
  /// How long the field stays quiet before a request goes out.
  ///
  /// Autocomplete is one request per keystroke without it, and a fast typist
  /// spends a dozen on a query they never meant to send.
  static const Duration _debounce = Duration(milliseconds: 300);

  Timer? _timer;

  /// Which query the answers arriving belong to.
  ///
  /// A slow request for `Cai` must not overwrite the answer for `Cairo`, so
  /// every result is checked against the query in flight before it is shown.
  int _generation = 0;

  @override
  SearchUiState build() {
    ref.onDispose(() => _timer?.cancel());
    return const SearchUiState();
  }

  /// Takes what the user has typed.
  void query(String text) {
    _timer?.cancel();
    _generation++;

    if (text.trim().isEmpty) {
      state = const SearchUiState();
      return;
    }

    state = state.copyWith(query: text, isSearching: true);
    final generation = _generation;
    _timer = Timer(_debounce, () => unawaited(_run(text, generation)));
  }

  Future<void> _run(String text, int generation) async {
    final result = await ref.read(weatherRepositoryProvider).search(text);
    if (generation != _generation) return;

    switch (result) {
      case Err<List<CitySuggestion>, AppFailure>(:final failure):
        state = state.copyWith(
          isSearching: false,
          matches: const <SearchMatch>[],
          failure: failure,
        );
      case Ok<List<CitySuggestion>, AppFailure>(:final value):
        final matches = value
            .map((suggestion) => SearchMatch(suggestion: suggestion))
            .toList(growable: false);
        state = state.copyWith(matches: matches, isSearching: false);
        await _fillReadings(matches, generation);
    }
  }

  /// Asks for every match's reading at once and shows them together.
  ///
  /// A reading that fails leaves its row without a temperature rather than
  /// failing the search: the name is still the answer the user asked for.
  Future<void> _fillReadings(
    List<SearchMatch> matches,
    int generation,
  ) async {
    final repository = ref.read(weatherRepositoryProvider);
    final language = ref.read(languageProvider);
    final readings = await Future.wait(
      matches.map(
        (match) =>
            repository.reading(match.suggestion.location, lang: language),
      ),
    );
    if (generation != _generation) return;

    state = state.copyWith(
      matches: <SearchMatch>[
        for (final (index, match) in matches.indexed)
          match.withReading(readings[index].valueOrNull),
      ],
    );
  }

  /// Keeps [suggestion] in the saved list.
  Future<void> save(CitySuggestion suggestion) => ref
      .read(savedCitiesProvider.notifier)
      .add(
        SavedCity(
          location: suggestion.location,
          name: suggestion.name,
          country: suggestion.country,
          addedAt: ref.read(clockProvider).now(),
        ),
      );

  /// Switches to wherever the device is.
  ///
  /// Asks for permission if it has never been answered, and falls back to the
  /// approximate position the service resolves from the request itself. That
  /// path needs no permission at all, so refusing is never a dead end.
  Future<void> useCurrentLocation() async {
    final port = ref.read(locationPortProvider);
    var permission = await port.permission();
    if (permission == LocationPermission.notDetermined) {
      permission = await port.request();
    }

    if (permission == LocationPermission.granted) {
      final position = await port.currentPosition();
      if (position case Ok<LocationRef, AppFailure>(:final value)) {
        ref.read(activeLocationProvider.notifier).location = value;
        return;
      }
    }
    ref.read(activeLocationProvider.notifier).location =
        const LocationRef.currentByIp();
  }
}
