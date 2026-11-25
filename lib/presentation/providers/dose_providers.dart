import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di/providers.dart';
import '../../domain/entities/adherence_summary.dart';
import '../../domain/entities/date_only.dart';
import '../../domain/entities/dose_slot.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/reminder_response.dart';

/// 오늘 날짜. 앱이 자정을 넘겨 다시 열리면 [TodayNotifier.refresh]로 갱신.
final todayProvider = NotifierProvider<TodayNotifier, DateTime>(
  TodayNotifier.new,
);

class TodayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now().dateOnly;

  void refresh() {
    final now = DateTime.now().dateOnly;
    if (now != state) state = now;
  }
}

/// 날짜별 복용 목록
final dailyDosesProvider =
    FutureProvider.autoDispose.family<List<DoseSlot>, DateTime>(
  (ref, date) => ref.watch(getDailyDosesProvider).call(date),
);

/// 최근 7일 복약률
final weeklyAdherenceProvider = FutureProvider.autoDispose<AdherenceSummary>(
  (ref) {
    ref.watch(todayProvider);
    return ref.watch(getAdherenceSummaryProvider).call(days: 7);
  },
);

/// 기록 탭에서 보고 있는 날짜
final historyDateProvider = NotifierProvider<HistoryDateNotifier, DateTime>(
  HistoryDateNotifier.new,
);

class HistoryDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => ref.watch(todayProvider);

  void select(DateTime date) => state = date.dateOnly;

  void previous() => state = DateTime(state.year, state.month, state.day - 1);

  void next() {
    final candidate = DateTime(state.year, state.month, state.day + 1);
    if (!candidate.isAfter(ref.read(todayProvider))) state = candidate;
  }
}

/// 복용 체크 액션
final doseControllerProvider = NotifierProvider<DoseController, void>(
  DoseController.new,
);

class DoseController extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggle(DoseSlot slot) async {
    await ref.read(toggleIntakeProvider).call(slot);
    _refresh();
  }

  /// 알림의 "복용 완료" 버튼. 기록된 약을 돌려준다.
  Future<Medication?> markTakenFromReminder(ReminderResponse response) async {
    final medication = await ref.read(markDoseTakenProvider).call(
          medicationId: response.medicationId,
          time: response.time,
        );
    _refresh();
    return medication;
  }

  void _refresh() {
    ref.invalidate(dailyDosesProvider);
    ref.invalidate(weeklyAdherenceProvider);
  }
}
