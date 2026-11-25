import '../entities/date_only.dart';
import '../entities/dose_time.dart';
import '../entities/intake_record.dart';
import '../entities/medication.dart';
import '../repositories/intake_repository.dart';
import '../repositories/medication_repository.dart';

/// 알림의 "복용 완료" 버튼 처리. 이미 체크돼 있어도 안전하게 덮어쓴다(멱등).
class MarkDoseTaken {
  const MarkDoseTaken(
    this._medicationRepository,
    this._intakeRepository, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final MedicationRepository _medicationRepository;
  final IntakeRepository _intakeRepository;
  final DateTime Function() _clock;

  /// 기록한 약을 돌려준다. 약이 삭제됐으면 null.
  Future<Medication?> call({
    required int medicationId,
    required DoseTime time,
  }) async {
    final medication = await _medicationRepository.getById(medicationId);
    if (medication == null) return null;

    final now = _clock();
    await _intakeRepository.save(
      IntakeRecord(
        medicationId: medicationId,
        date: now.dateOnly,
        time: time,
        takenAt: now,
      ),
    );
    return medication;
  }
}
