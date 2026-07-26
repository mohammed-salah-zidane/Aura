// package:test exports its own Timeout, which shadows the AppFailure variant.
import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart' hide Timeout;

const Result<int, AppFailure> _ok = Ok<int, AppFailure>(7);
const Result<int, AppFailure> _err = Err<int, AppFailure>(NoConnection());

void main() {
  group('isOk / isErr', () {
    test('isOk true on Ok and false on Err', () {
      expect(_ok.isOk, isTrue);
      expect(_err.isOk, isFalse);
    });

    test('isErr true on Err and false on Ok', () {
      expect(_err.isErr, isTrue);
      expect(_ok.isErr, isFalse);
    });
  });

  group('valueOrNull / failureOrNull', () {
    test('valueOrNull returns the value on Ok', () {
      expect(_ok.valueOrNull, 7);
    });

    test('valueOrNull returns null on Err', () {
      expect(_err.valueOrNull, isNull);
    });

    test('failureOrNull returns the failure on Err', () {
      expect(_err.failureOrNull, const NoConnection());
    });

    test('failureOrNull returns null on Ok', () {
      expect(_ok.failureOrNull, isNull);
    });

    // Documents the one ambiguity in the nullable accessors: with a nullable
    // T, valueOrNull cannot tell a null success from a failure. isOk can.
    test('valueOrNull returns null for a successful null value', () {
      const result = Ok<int?, AppFailure>(null);
      expect(result.valueOrNull, isNull);
      expect(result.isOk, isTrue);
    });
  });

  group('fold', () {
    test('fold runs only the ok branch on Ok', () {
      var errBranchRan = false;
      final folded = _ok.fold((value) => value * 2, (failure) {
        errBranchRan = true;
        return -1;
      });
      expect(folded, 14);
      expect(errBranchRan, isFalse);
    });

    test('fold runs only the err branch on Err', () {
      var okBranchRan = false;
      final folded = _err.fold((value) {
        okBranchRan = true;
        return -1;
      }, (failure) => failure is NoConnection ? 99 : 0);
      expect(folded, 99);
      expect(okBranchRan, isFalse);
    });

    test('fold collapses both variants to one type', () {
      String describe(Result<int, AppFailure> r) =>
          r.fold((value) => 'value $value', (failure) => 'failed $failure');
      expect(describe(_ok), 'value 7');
      expect(describe(_err), 'failed NoConnection');
    });
  });

  group('when', () {
    test('when runs only the ok branch on Ok', () {
      var errBranchRan = false;
      final result = _ok.when(
        ok: (value) => value + 1,
        err: (failure) {
          errBranchRan = true;
          return -1;
        },
      );
      expect(result, 8);
      expect(errBranchRan, isFalse);
    });

    test('when runs only the err branch on Err', () {
      var okBranchRan = false;
      final result = _err.when(
        ok: (value) {
          okBranchRan = true;
          return -1;
        },
        err: (failure) => 42,
      );
      expect(result, 42);
      expect(okBranchRan, isFalse);
    });

    test('when agrees with fold on both variants', () {
      for (final r in <Result<int, AppFailure>>[_ok, _err]) {
        expect(
          r.when(ok: (v) => 'ok $v', err: (f) => 'err $f'),
          r.fold((v) => 'ok $v', (f) => 'err $f'),
        );
      }
    });
  });

  group('map', () {
    test('map transforms the value of an Ok', () {
      expect(_ok.map((value) => value * 3), const Ok<int, AppFailure>(21));
    });

    test('map changes the success type', () {
      final mapped = _ok.map((value) => 'n=$value');
      expect(mapped, const Ok<String, AppFailure>('n=7'));
    });

    test('map leaves an Err untouched and never calls the transform', () {
      var transformRan = false;
      final mapped = _err.map((value) {
        transformRan = true;
        return value * 3;
      });
      expect(mapped, const Err<int, AppFailure>(NoConnection()));
      expect(transformRan, isFalse);
    });

    test('map composes', () {
      final mapped = _ok.map((value) => value + 1).map((value) => value * 10);
      expect(mapped, const Ok<int, AppFailure>(80));
    });
  });

  group('mapErr', () {
    test('mapErr transforms the failure of an Err', () {
      final mapped = _err.mapErr((failure) => 'saw $failure');
      expect(mapped, const Err<int, String>('saw NoConnection'));
    });

    test('mapErr leaves an Ok untouched and never calls the transform', () {
      var transformRan = false;
      final mapped = _ok.mapErr((failure) {
        transformRan = true;
        return 'unreachable';
      });
      expect(mapped, const Ok<int, String>(7));
      expect(transformRan, isFalse);
    });

    test('mapErr can swap one AppFailure variant for another', () {
      final mapped = _err.mapErr<AppFailure>(
        (failure) => failure is NoConnection ? const CacheMiss() : failure,
      );
      expect(mapped, const Err<int, AppFailure>(CacheMiss()));
    });

    test('mapErr after map keeps the mapped value', () {
      final mapped = _ok
          .map((value) => value * 2)
          .mapErr((failure) => 'unreachable');
      expect(mapped, const Ok<int, String>(14));
    });
  });

  group('pattern matching', () {
    test('switch over the sealed type destructures both variants', () {
      String describe(Result<int, AppFailure> r) => switch (r) {
        Ok<int, AppFailure>(:final value) => 'ok $value',
        Err<int, AppFailure>(:final failure) => 'err $failure',
      };
      expect(describe(_ok), 'ok 7');
      expect(describe(_err), 'err NoConnection');
    });
  });

  group('equality', () {
    test('== is true for two Ok holding equal values', () {
      expect(const Ok<int, AppFailure>(7), const Ok<int, AppFailure>(7));
      expect(
        const Ok<int, AppFailure>(7).hashCode,
        const Ok<int, AppFailure>(7).hashCode,
      );
    });

    test('== is false for two Ok holding different values', () {
      expect(
        const Ok<int, AppFailure>(7),
        isNot(const Ok<int, AppFailure>(8)),
      );
    });

    test('== is true for two Err holding the same failure variant', () {
      expect(
        const Err<int, AppFailure>(Timeout()),
        const Err<int, AppFailure>(Timeout()),
      );
      expect(
        const Err<int, AppFailure>(Timeout()).hashCode,
        const Err<int, AppFailure>(Timeout()).hashCode,
      );
    });

    test('== is false for two Err holding different failure variants', () {
      expect(
        const Err<int, AppFailure>(Timeout()),
        isNot(const Err<int, AppFailure>(NoConnection())),
      );
    });

    test('== is false across the two variants', () {
      expect(_ok, isNot(_err));
    });

    test('== is false for the same value at a different success type', () {
      expect(
        const Ok<int, AppFailure>(7),
        isNot(const Ok<num, AppFailure>(7)),
      );
    });
  });

  group('toString', () {
    test('toString names the variant and its payload', () {
      expect(_ok.toString(), 'Ok(7)');
      expect(_err.toString(), 'Err(NoConnection)');
    });
  });
}
