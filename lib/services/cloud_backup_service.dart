import 'dart:io' show Platform;
import 'dart:typed_data';

import 'google_drive_backup_service.dart';

/// 一次雲端備份下載的結果。
class CloudBackup {
  const CloudBackup({required this.bytes, this.modifiedTime});

  final Uint8List bytes;
  final DateTime? modifiedTime;
}

/// 雲端備份服務抽象。
///
/// v1 只做「手動備份 / 還原」:iOS 走 iCloud、Android 走 Google Drive。
/// 內部搭配 [BackupCodec] 產生 / 還原快照,不改動備份格式。
abstract interface class CloudBackupService {
  /// 此平台 / 建置是否支援雲端備份。
  bool get isSupported;

  /// 是否已可存取雲端（Android:已登入 Google;iOS:iCloud 可用）。
  Future<bool> isSignedIn();

  /// 觸發登入 / 授權;成功回 true。iOS 幾乎 no-op。
  Future<bool> signIn();

  Future<void> signOut();

  /// 上傳（覆蓋）備份內容,只保留最新一份。
  Future<void> uploadBackup(Uint8List bytes);

  /// 下載最新備份;沒有則回 null。
  Future<CloudBackup?> downloadBackup();

  /// 最後備份時間;無則 null。
  Future<DateTime?> lastBackupTime();
}

/// 依平台挑選實作。iOS 的 iCloud 尚未實作（PRD 步驟 5）→ 先回不支援。
CloudBackupService createCloudBackupService() {
  if (Platform.isAndroid) return GoogleDriveBackupService();
  return const UnsupportedCloudBackupService();
}

/// 尚未支援的平台（如 iOS iCloud 待實作）的預設實作。
class UnsupportedCloudBackupService implements CloudBackupService {
  const UnsupportedCloudBackupService();

  @override
  bool get isSupported => false;

  @override
  Future<bool> isSignedIn() async => false;

  @override
  Future<bool> signIn() async => false;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> uploadBackup(Uint8List bytes) async =>
      throw UnsupportedError('此平台尚未支援雲端備份');

  @override
  Future<CloudBackup?> downloadBackup() async => null;

  @override
  Future<DateTime?> lastBackupTime() async => null;
}
