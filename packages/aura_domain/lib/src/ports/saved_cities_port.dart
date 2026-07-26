import 'package:aura_core/aura_core.dart';
import 'package:aura_domain/src/entities/location_ref.dart';
import 'package:aura_domain/src/entities/saved_city.dart';

/// Where the user's kept cities live.
abstract interface class SavedCitiesPort {
  /// Every saved city, oldest first.
  Future<Result<List<SavedCity>, AppFailure>> readAll();

  /// Adds [city]. Adding one that is already saved changes nothing.
  Future<Result<void, AppFailure>> add(SavedCity city);

  /// Removes whatever is saved for [location].
  Future<Result<void, AppFailure>> remove(LocationRef location);
}
