import 'package:flutter/material.dart';

import '../data/pack_list_repository.dart';
import '../services/cloud_backup_service.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';
import 'app_scope.dart';
import 'cloud_backup_scope.dart';

class PackPlanApp extends StatefulWidget {
  const PackPlanApp({super.key, this.repository, this.cloudBackupService});

  final PackListRepository? repository;
  final CloudBackupService? cloudBackupService;

  @override
  State<PackPlanApp> createState() => _PackPlanAppState();
}

class _PackPlanAppState extends State<PackPlanApp> {
  late final PackListRepository _repository =
      widget.repository ?? InMemoryPackListRepository();
  late final CloudBackupService _cloudBackup =
      widget.cloudBackupService ?? createCloudBackupService();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: _repository,
      child: CloudBackupScope(
        service: _cloudBackup,
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
      ),
    );
  }
}
