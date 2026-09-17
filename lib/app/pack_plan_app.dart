import 'package:flutter/material.dart';

import '../data/pack_list_repository.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';
import 'app_scope.dart';

class PackPlanApp extends StatefulWidget {
  const PackPlanApp({super.key, this.repository});

  final PackListRepository? repository;

  @override
  State<PackPlanApp> createState() => _PackPlanAppState();
}

class _PackPlanAppState extends State<PackPlanApp> {
  late final PackListRepository _repository =
      widget.repository ?? InMemoryPackListRepository();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: _repository,
      // settings.themeMode 變動時（例如在設定頁切換外觀）重建 MaterialApp。
      child: ListenableBuilder(
        listenable: _repository,
        builder: (context, _) {
          return MaterialApp(
            title: 'PackPlan',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _repository.settings.themeMode,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
