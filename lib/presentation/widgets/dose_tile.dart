import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/entities/dose_slot.dart';

/// 복용 항목들을 하나의 흰 카드 안에 구분선으로 묶어 보여준다.
class DoseList extends StatelessWidget {
  const DoseList({
    super.key,
    required this.slots,
    required this.now,
    required this.onToggle,
  });

  final List<DoseSlot> slots;
  final DateTime now;
  final ValueChanged<DoseSlot> onToggle;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < slots.length; i++) ...[
            if (i > 0)
              Divider(indent: 88, endIndent: 20, color: p.border),
            DoseTile(
              slot: slots[i],
              now: now,
              onToggle: () => onToggle(slots[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class DoseTile extends StatelessWidget {
  const DoseTile({
    super.key,
    required this.slot,
    required this.now,
    required this.onToggle,
  });

  final DoseSlot slot;
  final DateTime now;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppPalette.of(context);
    final taken = slot.isTaken;
    final missed = slot.isMissed(now);

    final String status;
    final Color statusColor;
    if (taken) {
      status = '${DateFormat('HH:mm').format(slot.record!.takenAt)}에 먹었어요';
      statusColor = p.accent;
    } else if (missed) {
      status = '아직 안 먹었어요';
      statusColor = p.danger;
    } else {
      status = '예정';
      statusColor = p.textSecondary;
    }

    final memo = slot.medication.memo;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(
                slot.time.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: taken ? p.textTertiary : p.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: taken ? p.textTertiary : p.textPrimary,
                      decoration: taken ? TextDecoration.lineThrough : null,
                      decorationColor: p.textTertiary,
                    ),
                    child: Text(slot.medication.name),
                  ),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      children: [
                        if (memo.isNotEmpty) TextSpan(text: '$memo · '),
                        TextSpan(
                          text: status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              button: true,
              label: taken ? '복용 체크 해제' : '복용 체크',
              child: _CheckCircle(
                checked: taken,
                warn: missed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.checked, required this.warn});

  final bool checked;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? p.accent : p.fill,
        border: !checked && warn
            ? Border.all(color: p.danger.withValues(alpha: 0.5), width: 1.5)
            : null,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          Icons.check_rounded,
          key: ValueKey(checked),
          size: 20,
          color: checked ? Colors.white : p.textTertiary,
        ),
      ),
    );
  }
}
