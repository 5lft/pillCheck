sealed class MedicationException implements Exception {
  const MedicationException();
}

enum MedicationValidationError { emptyName, noTimes, tooManyTimes, noWeekdays }

class MedicationValidationException extends MedicationException {
  const MedicationValidationException(this.error);
  final MedicationValidationError error;
}

/// iOS는 앱당 예약 가능한 로컬 알림이 64개로 제한된다.
class ReminderLimitExceededException extends MedicationException {
  const ReminderLimitExceededException({
    required this.requiredCount,
    required this.limit,
  });

  final int requiredCount;
  final int limit;
}
