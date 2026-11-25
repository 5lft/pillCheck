/// 하루 중 복용 시각 (시:분). Flutter의 TimeOfDay에 의존하지 않는 순수 도메인 값 객체.
class DoseTime implements Comparable<DoseTime> {
  const DoseTime(this.hour, this.minute)
      : assert(hour >= 0 && hour < 24),
        assert(minute >= 0 && minute < 60);

  factory DoseTime.fromMinutes(int totalMinutes) =>
      DoseTime(totalMinutes ~/ 60, totalMinutes % 60);

  final int hour;
  final int minute;

  int get totalMinutes => hour * 60 + minute;

  /// 08:30 형식
  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// 해당 날짜의 이 시각
  DateTime on(DateTime date) =>
      DateTime(date.year, date.month, date.day, hour, minute);

  @override
  int compareTo(DoseTime other) => totalMinutes.compareTo(other.totalMinutes);

  @override
  bool operator ==(Object other) =>
      other is DoseTime && other.totalMinutes == totalMinutes;

  @override
  int get hashCode => totalMinutes.hashCode;

  @override
  String toString() => 'DoseTime($label)';
}
