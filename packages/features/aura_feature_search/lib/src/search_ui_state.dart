import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:meta/meta.dart';

/// One match, and the reading beside it once it arrives.
///
/// The reading is a second request per match, so the list appears as soon as
/// the names are known and each temperature fills in behind it.
@immutable
final class SearchMatch {
  /// Creates a match.
  const SearchMatch({required this.suggestion, this.reading});

  /// What the service matched.
  final CitySuggestion suggestion;

  /// Its reading for right now, or null while that is still on its way.
  final CityReading? reading;

  /// A copy of this match carrying [reading].
  SearchMatch withReading(CityReading? reading) =>
      SearchMatch(suggestion: suggestion, reading: reading);
}

/// What the search screen has to show.
@immutable
final class SearchUiState {
  /// Creates a search state.
  const SearchUiState({
    this.query = '',
    this.matches = const <SearchMatch>[],
    this.isSearching = false,
    this.failure,
  });

  /// What the user has typed.
  final String query;

  /// What the service matched, in the order it returned them.
  final List<SearchMatch> matches;

  /// Whether a request is out.
  final bool isSearching;

  /// Why the last request failed, or null.
  final AppFailure? failure;

  /// Whether the user has typed enough for the screen to have anything to say.
  bool get hasQuery => query.trim().isNotEmpty;

  /// Whether the service answered with nothing.
  bool get isEmpty =>
      hasQuery && !isSearching && failure == null && matches.isEmpty;

  /// A copy with the named fields replaced. [failure] is cleared unless given.
  SearchUiState copyWith({
    String? query,
    List<SearchMatch>? matches,
    bool? isSearching,
    AppFailure? failure,
  }) => SearchUiState(
    query: query ?? this.query,
    matches: matches ?? this.matches,
    isSearching: isSearching ?? this.isSearching,
    failure: failure,
  );
}
