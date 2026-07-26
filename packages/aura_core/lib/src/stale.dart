import 'package:aura_core/src/clock.dart';
import 'package:meta/meta.dart';

/// A value together with the moment it was fetched.
///
/// A repository returns this when it falls back to the cache, so the screen
/// can say how old the reading is instead of presenting it as live.
@immutable
final class Stale<T> {
  /// Wraps [value], fetched at [fetchedAt].
  const Stale(this.value, {required this.fetchedAt});

  /// The cached value.
  final T value;

  /// When the value was read from the network.
  final DateTime fetchedAt;

  /// How long ago the value was fetched, according to [clock].
  ///
  /// Negative if [fetchedAt] is in the future, which happens when the device
  /// clock moves backwards between a write and a read.
  Duration age(Clock clock) => clock.now().difference(fetchedAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is Stale<T> &&
          other.value == value &&
          other.fetchedAt == fetchedAt);

  @override
  int get hashCode => Object.hash(runtimeType, value, fetchedAt);

  @override
  String toString() => 'Stale($value, fetchedAt: $fetchedAt)';
}
