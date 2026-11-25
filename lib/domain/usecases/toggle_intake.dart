import '../entities/dose_slot.dart';
import '../entities/intake_record.dart';
import '../repositories/intake_repository.dart';

/// 복용 체크 / 체크 해제
class ToggleIntake {
  const ToggleIntake(this._repository, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final IntakeRepository _repository;
  final DateTime Function() _clock;

  Future<void> call(DoseSlot slot) async {
    if (slot.isTaken) {
      await _repository.remove(
        medicationId: slot.medication.id!,
        date: slot.date,
        time: slot.time,
      );
    } else {
      await _repository.save(
        IntakeRecord(
          medicationId: slot.medication.id!,
          date: slot.date,
          time: slot.time,
          takenAt: _clock(),
        ),
      );
    }
  }
}
