import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';

/// 의료 면책 + 개인정보 안내. 앱스토어 심사(1.4.1 등) 대비용으로 앱 안에 노출한다.
Future<void> showAppInfoDialog(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppPalette.of(context).card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      final theme = Theme.of(context);
      final p = AppPalette.of(context);
      Widget item(IconData icon, String title, String body) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: p.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: p.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('약챙김 안내', style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              item(
                Icons.health_and_safety_rounded,
                '복약을 돕는 보조 도구예요',
                '의학적 조언, 진단, 치료를 대체하지 않아요. '
                    '복용량과 복용법은 반드시 의사·약사의 안내를 따라 주세요.',
              ),
              item(
                Icons.lock_rounded,
                '정보는 이 기기에만 저장돼요',
                '입력한 정보는 외부로 전송되지 않아요.',
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
