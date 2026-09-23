import 'dart:io' show Platform;

import 'cloud_backup_service.dart';
import 'google_drive_backup_service.dart';
import 'icloud_backup_service.dart';

/// 依執行平台建立對應的雲端備份實作：
/// iOS → iCloud、Android → Google Drive、其餘 → 不支援。
CloudBackupService createCloudBackupService() {
  if (Platform.isIOS) return ICloudBackupService();
  if (Platform.isAndroid) return GoogleDriveBackupService();
  return const UnsupportedCloudBackupService();
}
