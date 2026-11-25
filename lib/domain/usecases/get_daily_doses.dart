import '../entities/date_only.dart';
import '../entities/dose_slot.dart';
import '../repositories/intake_repository.dart';
import '../repositories/medication_repository.dart';

/// 특정 날짜에 먹어야 하는 약 목록 + 복용 여부
class GetDailyDoses {
  const GetDailyDoses(this._medicationRepository, this._intakeRepository);

  final MedicationRepository _medicationRepository;
  final IntakeRepository _intakeRepository;

  Future<List<DoseSlot>> call(DateTime date) async {
    final day = date.dateOnly;
    final medications = await _medicationRepository.getAll();
    final records = await _intakeRepository.getByDate(day);

    final slots = <DoseSlot>[
      for (final medication in medications)
        if (medication.isScheduledOn(day))
          for (final time in medication.times)
            DoseSlot(
              medication: medication,
              date: day,
              time: time,
              record: records
                  .where(
                    (r) => r.medicationId == medication.id && r.time == time,
                  )
                  .firstOrNull,
            ),
    ];

    slots.sort((a, b) {
      final byTime = a.time.compareTo(b.time);
      return byTime != 0 ? byTime : a.medication.name.compareTo(b.medication.name);
    });
    return slots;
  }
}
