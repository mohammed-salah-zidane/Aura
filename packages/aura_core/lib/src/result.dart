import 'package:meta/meta.dart';

/// The outcome of an operation that can fail: either [Ok] or [Err].
///
/// Every layer boundary in Aura returns `Result<T, AppFailure>`, so no
/// exception ever crosses one and a caller never has to guess what a function
/// throws. Because the type is sealed, a `switch` over it is exhaustive and the
/// analyzer reports any branch that is missed.
@immutable
sealed class Result<T, F> {
  /// Const base constructor for the two variants.
  const Result();

  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T, F>;

  /// Whether this is an [Err].
  bool get isErr => this is Err<T, F>;

  /// The success value, or `null` when this is an [Err].
  T? get valueOrNull => switch (this) {
    Ok<T, F>(:final value) => value,
    Err<T, F>() => null,
  };

  /// The failure, or `null` when this is an [Ok].
  F? get failureOrNull => switch (this) {
    Ok<T, F>() => null,
    Err<T, F>(:final failure) => failure,
  };

  /// Collapses both variants into a single value.
  R fold<R>(R Function(T value) onOk, R Function(F failure) onErr) =>
      switch (this) {
        Ok<T, F>(:final value) => onOk(value),
        Err<T, F>(:final failure) => onErr(failure),
      };

  /// [fold] with named branches, for call sites where the two bodies are long
  /// enough that positional arguments stop reading clearly.
  R when<R>({
    required R Function(T value) ok,
    required R Function(F failure) err,
  }) => fold(ok, err);

  /// Applies [transform] to a success value and leaves a failure untouched.
  Result<R, F> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T, F>(:final value) => Ok<R, F>(transform(value)),
    Err<T, F>(:final failure) => Err<R, F>(failure),
  };

  /// Applies [transform] to a failure and leaves a success value untouched.
  Result<T, G> mapErr<G>(G Function(F failure) transform) => switch (this) {
    Ok<T, F>(:final value) => Ok<T, G>(value),
    Err<T, F>(:final failure) => Err<T, G>(transform(failure)),
  };
}

/// A successful [Result] carrying its [value].
@immutable
final class Ok<T, F> extends Result<T, F> {
  /// Wraps [value] as a success.
  const Ok(this.value);

  /// The value the operation produced.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is Ok<T, F> &&
          other.value == value);

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => 'Ok($value)';
}

/// A failed [Result] carrying its [failure].
@immutable
final class Err<T, F> extends Result<T, F> {
  /// Wraps [failure] as a failure.
  const Err(this.failure);

  /// Why the operation failed.
  final F failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is Err<T, F> &&
          other.failure == failure);

  @override
  int get hashCode => Object.hash(runtimeType, failure);

  @override
  String toString() => 'Err($failure)';
}
