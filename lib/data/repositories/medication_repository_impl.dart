import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/medication_local_data_source.dart';
import '../models/medication_model.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  const MedicationRepositoryImpl(this._local);

  final MedicationLocalDataSource _local;

  @override
  Future<List<Medication>> getAll() async =>
      _local.getAll().map((m) => m.toEntity()).toList();

  @override
  Future<Medication?> getById(int id) async => _local.getById(id)?.toEntity();

  @override
  Future<Medication> save(Medication medication) async {
    final entity = medication.id == null
        ? medication.copyWith(id: await _local.nextId())
        : medication;
    await _local.put(MedicationModel.fromEntity(entity));
    return entity;
  }

  @override
  Future<void> delete(int id) => _local.delete(id);
}
