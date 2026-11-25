import '../local/hive_database.dart';
import '../models/medication_model.dart';

class MedicationLocalDataSource {
  const MedicationLocalDataSource(this._db);

  final HiveDatabase _db;

  List<MedicationModel> getAll() => _db.medications.values.toList();

  MedicationModel? getById(int id) => _db.medications.get(id);

  Future<int> nextId() => _db.nextMedicationId();

  Future<void> put(MedicationModel model) =>
      _db.medications.put(model.id, model);

  Future<void> delete(int id) => _db.medications.delete(id);
}
