import 'date_only.dart';
import 'dose_time.dart';

/// 복용 중인 약 한 가지
class Medication {
  const Medication({
    this.id,
    required this.name,
    this.memo = '',
    required this.times,
    required this.weekdays,
    required this.createdAt,
  });

  /// 저장 전에는 null
  final int? id;
  final String name;

  /// 예: "식후 30분, 1정"
  final String memo;

  /// 하루 복용 시각들 (정렬됨)
  final List<DoseTime> times;

  /// 복용 요일. DateTime.monday(1) ~ DateTime.sunday(7)
  final Set<int> weekdays;

  final DateTime createdAt;

  static const allWeekdays = {1, 2, 3, 4, 5, 6, 7};

  bool get isEveryDay => weekdays.length == 7;

  /// 해당 날짜에 복용해야 하는 약인지. 등록일 이전 날짜는 제외한다.
  bool isScheduledOn(DateTime date) =>
      weekdays.contains(date.weekday) &&
      !date.dateOnly.isBefore(createdAt.dateOnly);

  /// 이 약을 위해 예약해야 하는 반복 알림 개수.
  /// 매일이면 시각당 1개(daily), 아니면 시각 × 요일 수(weekly).
  int get requiredReminderCount =>
      times.length * (isEveryDay ? 1 : weekdays.length);

  Medication copyWith({
    int? id,
    String? name,
    String? memo,
    List<DoseTime>? times,
    Set<int>? weekdays,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      memo: memo ?? this.memo,
      times: times ?? this.times,
      weekdays: weekdays ?? this.weekdays,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
