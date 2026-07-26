import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_providers/aura_providers.dart';
import 'package:meta/meta.dart';

/// What the home screen has to show.
///
/// Sealed, so the screen's `switch` is exhaustive and a new state cannot be
/// added without every branch being written. Loading is not a member: that is
/// `AsyncLoading` on the provider, which is where Riverpod already models it.
@immutable
sealed class HomeUiState {
  const HomeUiState({required this.units});

  /// The units every reading on the screen is rendered in.
  final UnitPreferences units;
}

/// A reading the screen can draw.
@immutable
final class HomeReady extends HomeUiState {
  /// Creates the ready state.
  const HomeReady({required this.feed, required super.units});

  /// The reading, and where it came from.
  final WeatherFeed feed;

  /// The place's own reading for right now.
  WeatherSnapshot get snapshot => feed.snapshot;
}

/// The service could not be reached, but a stored reading is available.
///
/// The design puts the offline screen in front of the data rather than behind
/// it: the user is told how old the reading is and chooses to see it, instead
/// of being handed yesterday's weather with nothing to say so.
@immutable
final class HomeStale extends HomeUiState {
  /// Creates the stale state.
  const HomeStale({
    required this.feed,
    required this.age,
    required super.units,
  });

  /// The stored reading, offered but not yet shown.
  final WeatherFeed feed;

  /// How old it is.
  final Duration age;
}

/// Nothing can be shown, and why.
@immutable
final class HomeUnavailable extends HomeUiState {
  /// Creates the unavailable state.
  const HomeUnavailable({required this.failure, required super.units});

  /// What went wrong. Carries the recovery action the screen offers.
  final AppFailure failure;
}
