import '../local/hive_database.dart';
import '../models/intake_record_model.dart';

class IntakeLocalDataSource {
  const IntakeLocalDataSource(this._db);

  final HiveDatabase _db;

  List<IntakeRecordModel> getByDateKey(int dateKey) => _db.intakeRecords.values
      .where((r) => r.dateKey == dateKey)
      .toList();

  Future<void> put(IntakeRecordModel model) =>
      _db.intakeRecords.put(model.boxKey, model);

  Future<void> delete(String boxKey) => _db.intakeRecords.delete(boxKey);

  Future<void> deleteAllOf(int medicationId) {
    final keys = _db.intakeRecords
        .toMap()
        .entries
        .where((e) => e.value.medicationId == medicationId)
        .map((e) => e.key)
        .toList();
    return _db.intakeRecords.deleteAll(keys);
  }
}
