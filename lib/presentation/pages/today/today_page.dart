import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/dose_slot.dart';
import '../../providers/dose_providers.dart';
import '../../providers/medication_providers.dart';
import '../../widgets/app_info_dialog.dart';
import '../../widgets/dose_tile.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/page_header.dart';
import '../../widgets/progress_ring.dart';
import '../medications/medication_form_page.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final doses = ref.watch(dailyDosesProvider(today));
    final hasMedications =
        ref.watch(medicationsProvider).value?.isNotEmpty ?? false;

    return Column(
      children: [
        PageHeader(
          eyebrow: DateFormat('M월 d일 EEEE').format(today),
          title: '오늘 먹을 약',
          actions: [
            HeaderIconButton(
              icon: Icons.info_outline_rounded,
              tooltip: '안내',
              onPressed: () => showAppInfoDialog(context),
            ),
            HeaderIconButton(
              icon: Icons.add_rounded,
              tooltip: '약 추가',
              primary: true,
              onPressed: () => MedicationFormPage.open(context),
            ),
          ],
        ),
        Expanded(
          child: doses.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => EmptyView(
              icon: Icons.error_outline_rounded,
              title: '목록을 불러오지 못했어요',
              message: '$error',
            ),
            data: (slots) {
              if (slots.isEmpty) {
                return hasMedications
                    ? const EmptyView(
                        icon: Icons.event_available_rounded,
                        title: '오늘은 쉬는 날이에요',
                        message: '오늘 먹을 약이 없어요.',
                      )
                    : EmptyView(
                        icon: Icons.medication_rounded,
                        title: '등록된 약이 없어요',
                        message: '약과 복용 시간을 등록하면\n시간에 맞춰 알려드릴게요.',
                        action: FilledButton.icon(
                          onPressed: () => MedicationFormPage.open(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('첫 약 등록하기'),
                        ),
                      );
              }

              final now = DateTime.now();
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  _ProgressCard(slots: slots),
                  const SizedBox(height: 24),
                  const SectionLabel('복용 일정'),
                  DoseList(
                    slots: slots,
                    now: now,
                    onToggle: (slot) =>
                        ref.read(doseControllerProvider.notifier).toggle(slot),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.slots});

  final List<DoseSlot> slots;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final taken = slots.where((s) => s.isTaken).length;
    final total = slots.length;
    final done = taken == total;
    final ratio = total == 0 ? 0.0 : taken / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.accent, Color.lerp(p.accent, const Color(0xFF7B5CFF), 0.55)!],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? '오늘 약을 다 챙겼어요' : '오늘 ${total - taken}번 남았어요',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  done ? '내일도 잊지 않게 알려드릴게요' : '$total번 중 $taken번 먹었어요',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ProgressRing(
            value: ratio,
            size: 76,
            strokeWidth: 8,
            color: Colors.white,
            trackColor: Colors.white.withValues(alpha: 0.22),
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 32)
                : Text(
                    '${(ratio * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
