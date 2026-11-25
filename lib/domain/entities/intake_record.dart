import 'dose_time.dart';

/// 특정 날짜·시각에 약을 먹었다는 기록
class IntakeRecord {
  const IntakeRecord({
    required this.medicationId,
    required this.date,
    required this.time,
    required this.takenAt,
  });

  final int medicationId;

  /// 복용 예정일 (날짜만 의미 있음)
  final DateTime date;

  /// 복용 예정 시각
  final DoseTime time;

  /// 실제로 체크한 시각
  final DateTime takenAt;
}
