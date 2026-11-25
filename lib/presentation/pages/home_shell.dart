import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/di/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../domain/entities/reminder_response.dart';
import '../providers/dose_providers.dart';
import 'history/history_page.dart';
import 'medications/medication_list_page.dart';
import 'today/today_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  StreamSubscription<ReminderResponse>? _reminderSub;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _reminderSub = ref
        .read(reminderSchedulerProvider)
        .responses
        .listen(_onReminderResponse);
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _reminderSub?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  /// 백그라운드에서 돌아오면 날짜(자정 경과)와 목록을 갱신
  void _onResume() {
    ref.read(todayProvider.notifier).refresh();
    ref.invalidate(dailyDosesProvider);
    ref.invalidate(weeklyAdherenceProvider);
  }

  Future<void> _onReminderResponse(ReminderResponse response) async {
    if (response.action == ReminderAction.markTaken) {
      final medication = await ref
          .read(doseControllerProvider.notifier)
          .markTakenFromReminder(response);
      if (!mounted || medication == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${medication.name} ${response.time.label} 복용을 기록했어요',
          ),
        ),
      );
    }
    if (mounted) setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: const [TodayPage(), MedicationListPage(), HistoryPage()],
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.border)),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: '오늘',
              ),
              NavigationDestination(
                icon: Icon(Icons.medication_outlined),
                selectedIcon: Icon(Icons.medication_rounded),
                label: '내 약',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: '기록',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
