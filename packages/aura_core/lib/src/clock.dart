// one_member_abstracts would have this be a bare function. It is a named
// injection seam with two implementations, which is what the rule exists to
// stop people faking with a class. Keeping the type keeps call sites honest.
// ignore_for_file: one_member_abstracts

/// The source of "now".
///
/// Nothing outside this file may call `DateTime.now()`. Every reading of the
/// current time goes through an injected [Clock], which is what makes the
/// time-dependent parts of the app repeatable under test: cache staleness, the
/// sun-arc position, and "last updated 2h ago".
abstract interface class Clock {
  /// The current instant.
  DateTime now();
}

/// The real clock, reading the device time in its local zone.
///
/// Injected once at the composition root.
final class SystemClock implements Clock {
  /// Creates the system clock.
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// A clock that stands still until it is told to move.
///
/// Lives in `lib` rather than in a test folder because every package that
/// depends on `aura_core` needs it in its own suite, and a fake copied into
/// six test folders is six chances to diverge.
final class FixedClock implements Clock {
  /// Creates a clock reading [instant].
  FixedClock(this.instant);

  /// The instant this clock reports.
  DateTime instant;

  @override
  DateTime now() => instant;

  /// Moves the clock forward by [by]. A negative duration moves it back.
  void advance(Duration by) => instant = instant.add(by);
}
