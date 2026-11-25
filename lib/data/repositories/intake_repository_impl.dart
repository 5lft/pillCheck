import '../../domain/entities/dose_time.dart';
import '../../domain/entities/intake_record.dart';
import '../../domain/repositories/intake_repository.dart';
import '../datasources/intake_local_data_source.dart';
import '../models/intake_record_model.dart';

class IntakeRepositoryImpl implements IntakeRepository {
  const IntakeRepositoryImpl(this._local);

  final IntakeLocalDataSource _local;

  @override
  Future<List<IntakeRecord>> getByDate(DateTime date) async => _local
      .getByDateKey(IntakeRecordModel.dateKeyOf(date))
      .map((m) => m.toEntity())
      .toList();

  @override
  Future<void> save(IntakeRecord record) =>
      _local.put(IntakeRecordModel.fromEntity(record));

  @override
  Future<void> remove({
    required int medicationId,
    required DateTime date,
    required DoseTime time,
  }) =>
      _local.delete(
        IntakeRecordModel.boxKeyOf(
          medicationId,
          IntakeRecordModel.dateKeyOf(date),
          time.totalMinutes,
        ),
      );

  @override
  Future<void> removeAllOf(int medicationId) =>
      _local.deleteAllOf(medicationId);
}
