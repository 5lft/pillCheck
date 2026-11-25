import '../entities/medication.dart';
import '../exceptions/medication_exceptions.dart';
import '../repositories/medication_repository.dart';
import '../services/reminder_scheduler.dart';

class SaveMedication {
  const SaveMedication(this._repository, this._scheduler);

  final MedicationRepository _repository;
  final ReminderScheduler _scheduler;

  /// 한 약에 등록 가능한 최대 복용 시각 수 (알림 id 체계상 9 이하)
  static const maxTimesPerMedication = 6;

  Future<Medication> call(Medication input) async {
    final medication = input.copyWith(
      name: input.name.trim(),
      memo: input.memo.trim(),
      times: ({...input.times}.toList()..sort()),
    );
    _validate(medication);
    await _ensureReminderCapacity(medication);

    final saved = await _repository.save(medication);
    await _scheduler.requestPermission();
    await _scheduler.schedule(saved);
    return saved;
  }

  void _validate(Medication m) {
    if (m.name.isEmpty) {
      throw const MedicationValidationException(
        MedicationValidationError.emptyName,
      );
    }
    if (m.times.isEmpty) {
      throw const MedicationValidationException(
        MedicationValidationError.noTimes,
      );
    }
    if (m.times.length > maxTimesPerMedication) {
      throw const MedicationValidationException(
        MedicationValidationError.tooManyTimes,
      );
    }
    if (m.weekdays.isEmpty) {
      throw const MedicationValidationException(
        MedicationValidationError.noWeekdays,
      );
    }
  }

  Future<void> _ensureReminderCapacity(Medication m) async {
    final others = (await _repository.getAll()).where((e) => e.id != m.id);
    final total = others.fold<int>(
          0,
          (sum, e) => sum + e.requiredReminderCount,
        ) +
        m.requiredReminderCount;
    if (total > _scheduler.maxPendingReminders) {
      throw ReminderLimitExceededException(
        requiredCount: total,
        limit: _scheduler.maxPendingReminders,
      );
    }
  }
}
