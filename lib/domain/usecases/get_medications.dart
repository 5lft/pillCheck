import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class GetMedications {
  const GetMedications(this._repository);

  final MedicationRepository _repository;

  /// 첫 복용 시각 → 이름 순으로 정렬
  Future<List<Medication>> call() async {
    final list = [...await _repository.getAll()];
    list.sort((a, b) {
      final byTime = a.times.first.compareTo(b.times.first);
      return byTime != 0 ? byTime : a.name.compareTo(b.name);
    });
    return list;
  }
}
