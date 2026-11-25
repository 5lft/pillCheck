import '../entities/dose_time.dart';
import '../entities/intake_record.dart';

abstract interface class IntakeRepository {
  Future<List<IntakeRecord>> getByDate(DateTime date);

  Future<void> save(IntakeRecord record);

  Future<void> remove({
    required int medicationId,
    required DateTime date,
    required DoseTime time,
  });

  Future<void> removeAllOf(int medicationId);
}
