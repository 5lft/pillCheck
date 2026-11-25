extension DateOnly on DateTime {
  /// 시/분/초를 버린 날짜
  DateTime get dateOnly => DateTime(year, month, day);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
