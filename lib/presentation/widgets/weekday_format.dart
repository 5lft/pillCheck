const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

/// {1,3,5} → "월·수·금", 전체 → "매일"
String formatWeekdays(Set<int> weekdays) {
  if (weekdays.length == 7) return '매일';
  if (weekdays.length == 5 && weekdays.every((d) => d <= 5)) return '평일';
  if (weekdays.length == 2 && weekdays.containsAll({6, 7})) return '주말';
  final sorted = weekdays.toList()..sort();
  return sorted.map((d) => weekdayLabels[d - 1]).join('·');
}
