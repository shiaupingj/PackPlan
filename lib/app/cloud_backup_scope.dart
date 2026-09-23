import 'package:flutter/widgets.dart';

import '../services/cloud_backup_service.dart';

/// 讓畫面（設定頁）取用 [CloudBackupService];測試可注入 fake。
class CloudBackupScope extends InheritedWidget {
  const CloudBackupScope({
    super.key,
    required this.service,
    required super.child,
  });

  final CloudBackupService service;

  static CloudBackupService of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CloudBackupScope>();
    assert(scope != null, 'CloudBackupScope not found in widget tree.');
    return scope!.service;
  }

  @override
  bool updateShouldNotify(CloudBackupScope oldWidget) =>
      oldWidget.service != service;
}
