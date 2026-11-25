import '../entities/medication.dart';
import '../entities/reminder_response.dart';

/// 복약 알림 예약을 추상화. 구현은 data 계층(로컬 알림)에 있다.
abstract interface class ReminderScheduler {
  /// 플랫폼이 허용하는 최대 예약 알림 수 (iOS: 64)
  int get maxPendingReminders;

  Future<bool> requestPermission();

  /// 해당 약의 기존 알림을 지우고 다시 예약한다.
  Future<void> schedule(Medication medication);

  Future<void> cancel(int medicationId);

  /// 알림 탭 / "복용 완료" 버튼 이벤트
  Stream<ReminderResponse> get responses;
}
