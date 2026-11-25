import 'dose_time.dart';
import 'intake_record.dart';
import 'medication.dart';

/// 특정 날짜의 "이 약을 이 시각에 먹어야 함" 한 칸
class DoseSlot {
  const DoseSlot({
    required this.medication,
    required this.date,
    required this.time,
    this.record,
  });

  final Medication medication;
  final DateTime date;
  final DoseTime time;
  final IntakeRecord? record;

  bool get isTaken => record != null;

  DateTime get scheduledAt => time.on(date);

  /// 예정 시각이 지났는데 아직 안 먹음
  bool isMissed(DateTime now) => !isTaken && scheduledAt.isBefore(now);
}
