import 'dart:io';

import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_storage/aura_storage.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

SavedCity _city(
  String name, {
  String? query,
  String country = 'Egypt',
  String? displayName,
  DateTime? addedAt,
}) => SavedCity(
  location: LocationRef(query: query ?? name, displayName: displayName),
  name: name,
  country: country,
  addedAt: addedAt ?? DateTime.utc(2026, 7, 26, 12),
);

void main() {
  late AuraDatabase database;
  late SavedCitiesStore store;

  setUp(() {
    database = AuraDatabase(NativeDatabase.memory());
    store = SavedCitiesStore(database);
  });

  tearDown(() => database.close());

  group('readAll', () {
    test('readAll returns nothing before anything is saved', () async {
      expect((await store.readAll()).valueOrNull, isEmpty);
    });

    test('readAll returns a city with every field it was saved with', () async {
      final cairo = _city(
        'Cairo',
        query: '30.05,31.25',
        displayName: 'Cairo',
        addedAt: DateTime.utc(2026, 7, 20, 9, 15),
      );
      await store.add(cairo);

      final saved = (await store.readAll()).valueOrNull?.single;

      expect(saved?.name, 'Cairo');
      expect(saved?.country, 'Egypt');
      expect(saved?.location.query, '30.05,31.25');
      expect(saved?.location.displayName, 'Cairo');
      expect(saved?.addedAt.isAtSameMomentAs(cairo.addedAt), isTrue);
    });

    test('readAll returns a city saved without a display name', () async {
      await store.add(_city('Cairo'));

      expect(
        (await store.readAll()).valueOrNull?.single.location.displayName,
        isNull,
      );
    });

    // The list is the order the user built it in, not the order the database
    // happens to return rows in.
    test('readAll returns cities oldest first', () async {
      await store.add(
        _city('Cairo', addedAt: DateTime.utc(2026, 7, 22, 8)),
      );
      await store.add(
        _city('Aswan', addedAt: DateTime.utc(2026, 7, 20, 8)),
      );
      await store.add(
        _city('Luxor', addedAt: DateTime.utc(2026, 7, 24, 8)),
      );

      final names = (await store.readAll()).valueOrNull
          ?.map((city) => city.name)
          .toList();

      expect(names, <String>['Aswan', 'Cairo', 'Luxor']);
    });
  });

  group('add', () {
    test('add keeps two different cities', () async {
      await store.add(_city('Cairo'));
      await store.add(_city('Aswan'));

      expect((await store.readAll()).valueOrNull, hasLength(2));
    });

    // The port says adding one that is already saved changes nothing, and that
    // has to include the moment it was added, which is what orders the list.
    test('add a second time changes nothing', () async {
      final first = _city('Cairo', addedAt: DateTime.utc(2026, 7, 20, 8));
      await store.add(first);
      await store.add(
        _city(
          'Cairo',
          country: 'Elsewhere',
          addedAt: DateTime.utc(2026, 7, 25),
        ),
      );

      final saved = (await store.readAll()).valueOrNull;

      expect(saved, hasLength(1));
      expect(saved?.single.country, 'Egypt');
      expect(saved?.single.addedAt.isAtSameMomentAs(first.addedAt), isTrue);
    });

    test('add reports success', () async {
      expect((await store.add(_city('Cairo'))).isOk, isTrue);
    });
  });

  group('remove', () {
    test('remove drops the city it names', () async {
      await store.add(_city('Cairo'));
      await store.add(_city('Aswan'));

      await store.remove(const LocationRef(query: 'Cairo'));

      final names = (await store.readAll()).valueOrNull
          ?.map((city) => city.name)
          .toList();
      expect(names, <String>['Aswan']);
    });

    // A city is identified by the query it is asked about with, not by the
    // label it happens to be showing under.
    test('remove matches on the query alone', () async {
      await store.add(
        _city('Cairo', query: '30.05,31.25', displayName: 'Cairo'),
      );

      await store.remove(const LocationRef(query: '30.05,31.25'));

      expect((await store.readAll()).valueOrNull, isEmpty);
    });

    test('remove of a city that was never saved changes nothing', () async {
      await store.add(_city('Cairo'));

      expect(
        (await store.remove(const LocationRef(query: 'Paris'))).isOk,
        isTrue,
      );
      expect((await store.readAll()).valueOrNull, hasLength(1));
    });
  });

  group('when the database cannot be opened', () {
    late SavedCitiesStore unopenable;

    setUp(() async {
      await database.close();
      unopenable = SavedCitiesStore(
        AuraDatabase(
          NativeDatabase(File('/aura-test-no-such-directory/aura.sqlite')),
        ),
      );
    });

    test('readAll reports a failure rather than throwing', () async {
      expect((await unopenable.readAll()).failureOrNull, isA<Unknown>());
    });

    test('add reports a failure rather than throwing', () async {
      expect(
        (await unopenable.add(_city('Cairo'))).failureOrNull,
        isA<Unknown>(),
      );
    });

    test('remove reports a failure rather than throwing', () async {
      expect(
        (await unopenable.remove(
          const LocationRef(query: 'Cairo'),
        )).failureOrNull,
        isA<Unknown>(),
      );
    });
  });
}
