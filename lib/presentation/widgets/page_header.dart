import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';

/// 탭 화면 상단의 큰 제목 헤더
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.actions = const [],
  });

  final String title;

  /// 제목 위 작은 회색 텍스트 (날짜 등)
  final String? eyebrow;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: p.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(title, style: theme.textTheme.headlineMedium),
              ],
            ),
          ),
          for (final action in actions) ...[const SizedBox(width: 8), action],
        ],
      ),
    );
  }
}

/// 헤더 우측의 원형 아이콘 버튼
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// true면 포인트 색으로 채운 버튼
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: primary ? p.accent : p.card,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 42,
            child: Icon(
              icon,
              size: 22,
              color: primary ? Colors.white : p.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 흰 카드 위 섹션 제목 (작은 회색 라벨)
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: p.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
