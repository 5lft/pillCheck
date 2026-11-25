import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/adherence_summary.dart';
import '../../providers/dose_providers.dart';
import '../../widgets/dose_tile.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/page_header.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/weekday_format.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final date = ref.watch(historyDateProvider);
    final doses = ref.watch(dailyDosesProvider(date));
    final adherence = ref.watch(weeklyAdherenceProvider);
    final dateNotifier = ref.read(historyDateProvider.notifier);
    final now = DateTime.now();

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(today.year - 1, today.month, today.day),
        lastDate: today,
      );
      if (picked != null) dateNotifier.select(picked);
    }

    return Column(
      children: [
        PageHeader(
          title: '복용 기록',
          actions: [
            HeaderIconButton(
              icon: Icons.calendar_month_rounded,
              tooltip: '날짜 선택',
              onPressed: pickDate,
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              adherence.when(
                data: (summary) => _AdherenceCard(summary: summary),
                loading: () => const SizedBox(height: 112),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              _WeekStrip(
                today: today,
                selected: date,
                onSelect: dateNotifier.select,
                onPrevious: dateNotifier.previous,
                onNext: date.isBefore(today) ? dateNotifier.next : null,
              ),
              const SizedBox(height: 24),
              SectionLabel(
                date == today
                    ? '오늘'
                    : DateFormat('M월 d일 EEEE').format(date),
              ),
              doses.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => EmptyView(
                  icon: Icons.error_outline_rounded,
                  title: '기록을 불러오지 못했어요',
                  message: '$error',
                ),
                data: (slots) => slots.isEmpty
                    ? const _EmptyDay()
                    : DoseList(
                        slots: slots,
                        now: now,
                        onToggle: (slot) => ref
                            .read(doseControllerProvider.notifier)
                            .toggle(slot),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard({required this.summary});

  final AdherenceSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppPalette.of(context);
    final rate = summary.rate;

    final String headline;
    if (rate == null) {
      headline = '아직 기록이 없어요';
    } else if (rate >= 0.9) {
      headline = '아주 잘 챙기고 있어요';
    } else if (rate >= 0.6) {
      headline = '조금만 더 챙겨볼까요';
    } else {
      headline = '알림을 놓치지 마세요';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            ProgressRing(
              value: rate ?? 0,
              size: 72,
              strokeWidth: 8,
              color: p.accent,
              trackColor: p.fill,
              child: Text(
                rate == null ? '-' : '${(rate * 100).round()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최근 7일 복용률',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(headline, style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                  )),
                  if (rate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${summary.total}번 중 ${summary.taken}번 먹었어요',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 선택한 날짜 주변 7일을 보여주는 가로 스트립
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.today,
    required this.selected,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime today;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    // 선택일이 최근 7일 안이면 오늘로 끝나는 창, 아니면 선택일을 가운데쯤 둔다
    final daysAgo = today.difference(selected).inDays;
    final end = daysAgo < 7
        ? today
        : DateTime(selected.year, selected.month, selected.day + 3);
    final days = [
      for (var i = 6; i >= 0; i--) DateTime(end.year, end.month, end.day - i),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 14),
        child: Row(
          children: [
            _ArrowButton(
              icon: Icons.chevron_left_rounded,
              tooltip: '이전 날',
              onPressed: onPrevious,
            ),
            for (final day in days)
              Expanded(
                child: _DayCell(
                  day: day,
                  selected: day == selected,
                  isToday: day == today,
                  onTap: () => onSelect(day),
                ),
              ),
            _ArrowButton(
              icon: Icons.chevron_right_rounded,
              tooltip: '다음 날',
              onPressed: onNext,
              color: onNext == null ? p.border : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(icon, color: color ?? AppPalette.of(context).textSecondary),
      onPressed: onPressed,
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Text(
            weekdayLabels[day.weekday - 1],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? p.accent : Colors.transparent,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : isToday
                        ? p.accent
                        : p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 32, color: p.textTertiary),
            const SizedBox(height: 10),
            Text(
              '이 날은 먹을 약이 없었어요',
              style: TextStyle(
                color: p.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
