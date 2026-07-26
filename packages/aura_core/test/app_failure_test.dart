// package:test exports its own Timeout, which shadows the AppFailure variant.
import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart' hide Timeout;

/// One instance of every variant. A new variant that is not added here makes
/// the exhaustive switch below fail to compile, which is the point.
const List<AppFailure> _allVariants = <AppFailure>[
  NoConnection(),
  Timeout(),
  InvalidCity(),
  Unauthorized(),
  RateLimited(),
  ServerError(),
  CacheMiss(),
  Unknown(),
];

String _name(AppFailure failure) => switch (failure) {
  NoConnection() => 'NoConnection',
  Timeout() => 'Timeout',
  InvalidCity() => 'InvalidCity',
  Unauthorized() => 'Unauthorized',
  RateLimited() => 'RateLimited',
  ServerError() => 'ServerError',
  CacheMiss() => 'CacheMiss',
  Unknown() => 'Unknown',
};

void main() {
  group('the sealed family', () {
    test('every variant switches to a distinct name', () {
      final names = _allVariants.map(_name).toSet();
      expect(names, hasLength(_allVariants.length));
    });

    test('every variant is unequal to every other variant', () {
      for (final a in _allVariants) {
        for (final b in _allVariants) {
          if (identical(a, b)) continue;
          expect(a, isNot(b), reason: '$a and $b compared equal');
        }
      }
    });
  });

  group('equality', () {
    test('== is true for two instances of the same variant', () {
      expect(const NoConnection(), const NoConnection());
      expect(const CacheMiss(), const CacheMiss());
    });

    test('hashCode matches for two instances of the same variant', () {
      for (final variant in _allVariants) {
        expect(variant.hashCode, variant.runtimeType.hashCode);
      }
    });

    test('== ignores cause, because the variant is the identity', () {
      const withCause = NoConnection(cause: 'SocketException');
      const withoutCause = NoConnection();
      expect(withCause, withoutCause);
      expect(withCause.hashCode, withoutCause.hashCode);
    });

    test('== is false for different variants carrying the same cause', () {
      expect(
        const Unauthorized(cause: 'boom'),
        isNot(const RateLimited(cause: 'boom')),
      );
    });
  });

  group('cause', () {
    test('cause defaults to null', () {
      for (final variant in _allVariants) {
        expect(variant.cause, isNull, reason: '$variant carried a cause');
      }
    });

    test('cause is kept as given for logging', () {
      final underlying = StateError('socket closed');
      final failure = ServerError(cause: underlying);
      expect(failure.cause, same(underlying));
    });
  });

  group('toString', () {
    test('toString names the variant when there is no cause', () {
      for (final variant in _allVariants) {
        expect(variant.toString(), _name(variant));
      }
    });

    test('toString appends the cause when there is one', () {
      expect(
        const InvalidCity(cause: 'code 1006').toString(),
        'InvalidCity(cause: code 1006)',
      );
    });
  });
}
