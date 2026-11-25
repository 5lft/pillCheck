import '../entities/adherence_summary.dart';
import '../entities/date_only.dart';
import 'get_daily_doses.dart';

/// 최근 N일 복약률. 아직 시각이 안 된 오늘 분은 분모에서 뺀다.
class GetAdherenceSummary {
  const GetAdherenceSummary(this._getDailyDoses, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final GetDailyDoses _getDailyDoses;
  final DateTime Function() _clock;

  Future<AdherenceSummary> call({int days = 7}) async {
    final now = _clock();
    final today = now.dateOnly;
    var taken = 0;
    var total = 0;

    for (var i = 0; i < days; i++) {
      final date = DateTime(today.year, today.month, today.day - i);
      for (final slot in await _getDailyDoses(date)) {
        final due = !slot.scheduledAt.isAfter(now);
        if (due || slot.isTaken) total++;
        if (slot.isTaken) taken++;
      }
    }
    return AdherenceSummary(taken: taken, total: total);
  }
}
