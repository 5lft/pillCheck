import '../entities/medication.dart';

abstract interface class MedicationRepository {
  Future<List<Medication>> getAll();

  Future<Medication?> getById(int id);

  /// id가 없으면 새로 발급해서 저장하고, 저장된 엔티티를 돌려준다.
  Future<Medication> save(Medication medication);

  Future<void> delete(int id);
}
