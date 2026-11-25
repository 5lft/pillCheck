import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../data/local/hive_database.dart';
import '../data/services/local_notification_reminder_scheduler.dart';
import 'app.dart';
import 'di/providers.dart';

/// 앱 실행 전 비동기 초기화 후 의존성을 주입한다.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR');
  Intl.defaultLocale = 'ko_KR';

  final database = await HiveDatabase.open();
  final scheduler = LocalNotificationReminderScheduler();
  await scheduler.init();

  runApp(
    ProviderScope(
      overrides: [
        hiveDatabaseProvider.overrideWithValue(database),
        reminderSchedulerProvider.overrideWithValue(scheduler),
      ],
      child: const PillCheckApp(),
    ),
  );
}
