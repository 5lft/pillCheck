import '../repositories/intake_repository.dart';
import '../repositories/medication_repository.dart';
import '../services/reminder_scheduler.dart';

class DeleteMedication {
  const DeleteMedication(
    this._medicationRepository,
    this._intakeRepository,
    this._scheduler,
  );

  final MedicationRepository _medicationRepository;
  final IntakeRepository _intakeRepository;
  final ReminderScheduler _scheduler;

  Future<void> call(int medicationId) async {
    await _scheduler.cancel(medicationId);
    await _intakeRepository.removeAllOf(medicationId);
    await _medicationRepository.delete(medicationId);
  }
}
