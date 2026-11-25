import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/medication.dart';
import '../../providers/medication_providers.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/page_header.dart';
import '../../widgets/weekday_format.dart';
import 'medication_form_page.dart';

class MedicationListPage extends ConsumerWidget {
  const MedicationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(medicationsProvider);
    final count = medications.value?.length ?? 0;

    return Column(
      children: [
        PageHeader(
          eyebrow: count > 0 ? '$count개 복용 중' : null,
          title: '내 약',
          actions: [
            HeaderIconButton(
              icon: Icons.add_rounded,
              tooltip: '약 추가',
              primary: true,
              onPressed: () => MedicationFormPage.open(context),
            ),
          ],
        ),
        Expanded(
          child: medications.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => EmptyView(
              icon: Icons.error_outline_rounded,
              title: '목록을 불러오지 못했어요',
              message: '$error',
            ),
            data: (list) => list.isEmpty
                ? EmptyView(
                    icon: Icons.medication_rounded,
                    title: '등록된 약이 없어요',
                    message: '먹고 있는 약을 추가해 보세요.',
                    action: FilledButton.icon(
                      onPressed: () => MedicationFormPage.open(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('약 추가하기'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _MedicationCard(
                      medication: list[i],
                      onTap: () =>
                          MedicationFormPage.open(context, initial: list[i]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.medication, required this.onTap});

  final Medication medication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppPalette.of(context);
    final subtitle = [
      formatWeekdays(medication.weekdays),
      if (medication.memo.isNotEmpty) medication.memo,
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.accentSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.medication_rounded,
                      color: p.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: p.textTertiary),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final time in medication.times)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: p.fill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: p.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            time.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
