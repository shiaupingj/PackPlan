import 'package:flutter/material.dart';

import '../data/pack_list_repository.dart';
import '../data/weight_reference_repository.dart';
import '../services/cloud_backup_factory.dart';
import '../services/cloud_backup_service.dart';
import '../services/weight_reference_source.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';
import 'app_scope.dart';
import 'cloud_backup_scope.dart';
import 'weight_reference_scope.dart';

class PackPlanApp extends StatefulWidget {
  const PackPlanApp({
    super.key,
    this.repository,
    this.cloudBackupService,
    this.weightReferenceRepository,
  });

  final PackListRepository? repository;

  /// 雲端備份服務；省略時依平台自動建立（iOS=iCloud、Android=Drive）。
  /// 測試可注入 fake。
  final CloudBackupService? cloudBackupService;

  /// 線上參考重量;正式環境由 main.dart 注入(Firestore + 檔案快取)。
  /// 省略時為沒有資料的離線版本,讓測試不會連網。
  final WeightReferenceRepository? weightReferenceRepository;

  @override
  State<PackPlanApp> createState() => _PackPlanAppState();
}

class _PackPlanAppState extends State<PackPlanApp> {
  late final PackListRepository _repository =
      widget.repository ?? InMemoryPackListRepository();
  late final CloudBackupService _cloudBackupService =
      widget.cloudBackupService ?? createCloudBackupService();
  late final WeightReferenceRepository _weightReferenceRepository =
      widget.weightReferenceRepository ??
      WeightReferenceRepository(
        source: const EmptyWeightReferenceSource(),
        cacheStore: InMemoryWeightReferenceCacheStore(),
      );

  @override
  void dispose() {
    if (widget.weightReferenceRepository == null) {
      _weightReferenceRepository.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: _repository,
      child: CloudBackupScope(
        service: _cloudBackupService,
        child: WeightReferenceScope(
          repository: _weightReferenceRepository,
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
      ),
    );
  }
}
