import 'dose_time.dart';

enum ReminderAction {
  /// 알림 본문을 탭함
  open,

  /// 알림의 "복용 완료" 버튼을 누름
  markTaken,
}

/// 사용자가 복약 알림에 반응한 이벤트
class ReminderResponse {
  const ReminderResponse({
    required this.medicationId,
    required this.time,
    required this.action,
  });

  final int medicationId;
  final DoseTime time;
  final ReminderAction action;
}
