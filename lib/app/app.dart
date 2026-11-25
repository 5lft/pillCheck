import 'package:material_ui/material_ui.dart';

import '../presentation/pages/home_shell.dart';
import 'theme/app_theme.dart';

class PillCheckApp extends StatelessWidget {
  const PillCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '약챙김',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeShell(),
    );
  }
}
