import 'dart:typed_data';

/// 雲端上一份備份的中繼資料。
///
/// 各平台以 [id] 做為下載／刪除的識別：iCloud 用檔案的相對路徑，
/// Google Drive 用 file id。
class CloudBackupEntry {
  const CloudBackupEntry({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
  });

  /// 平台識別碼（iCloud=relativePath、Drive=fileId）。
  final String id;

  /// 顯示用檔名，例如 packplan-backup-20260922-103045.json。
  final String name;

  /// 備份建立時間（雲端檔案的內容變更時間）。
  final DateTime createdAt;

  /// 備份檔位元組大小。
  final int sizeBytes;
}

/// 雲端備份流程的錯誤，訊息可直接顯示給使用者。
class CloudBackupException implements Exception {
  const CloudBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 雲端備份存取層。iOS 以 iCloud、Android 以 Google Drive 實作。
///
/// 採「保留多份歷史版本」策略：每次 [upload] 都新增一份帶時間戳的檔案，
/// 不覆蓋既有備份；還原時由使用者從 [list] 選擇要還原的版本。
abstract interface class CloudBackupService {
  /// 這個平台的雲端備份目前是否可用（免互動即可存取）。
  /// iOS 在 iCloud 已登入時為 true；Android 在已授權 Google 帳號時為 true。
  Future<bool> isAvailable();

  /// 互動式連結帳號並取得授權，回傳是否成功。
  /// iOS 無需連結，直接回傳 [isAvailable] 的結果；Android 會跳出 Google 登入。
  Future<bool> connect();

  /// 解除連結。iOS 為 no-op；Android 會登出 Google 帳號。
  Future<void> disconnect();

  /// 目前連結的帳號標示（Android 回傳 Google 帳號 email，iOS 回傳 null）。
  Future<String?> accountLabel();

  /// 上傳一份新的備份，回傳新建立的項目。不覆蓋既有備份。
  Future<CloudBackupEntry> upload(Uint8List bytes);

  /// 列出雲端上所有 PackPlan 備份，最新的排在最前面。
  Future<List<CloudBackupEntry>> list();

  /// 下載指定備份的完整內容。
  Future<Uint8List> download(CloudBackupEntry entry);

  /// 刪除指定備份。
  Future<void> delete(CloudBackupEntry entry);
}

/// 不支援雲端備份的平台（例如桌面／Web）使用的空實作。
///
/// [isAvailable] 恆為 false，UI 應據此隱藏雲端備份區塊；
/// 讀取類操作安全回傳空結果，寫入類操作丟出可顯示的例外。
class UnsupportedCloudBackupService implements CloudBackupService {
  const UnsupportedCloudBackupService();

  static const String _message = '此平台不支援雲端備份';

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> connect() async => false;

  @override
  Future<void> disconnect() async {}

  @override
  Future<String?> accountLabel() async => null;

  @override
  Future<CloudBackupEntry> upload(Uint8List bytes) async =>
      throw const CloudBackupException(_message);

  @override
  Future<List<CloudBackupEntry>> list() async => const <CloudBackupEntry>[];

  @override
  Future<Uint8List> download(CloudBackupEntry entry) async =>
      throw const CloudBackupException(_message);

  @override
  Future<void> delete(CloudBackupEntry entry) async =>
      throw const CloudBackupException(_message);
}

/// 備份檔命名慣例，供各平台共用（辨識哪些檔案屬於 PackPlan 備份）。
class CloudBackupNaming {
  const CloudBackupNaming._();

  static const String prefix = 'packplan-backup-';
  static const String suffix = '.json';

  /// 產生本次備份的檔名，時間戳採本地時間 yyyyMMdd-HHmmss。
  static String fileNameFor(DateTime time) {
    final t = time;
    final buffer = StringBuffer(prefix)
      ..write(_four(t.year))
      ..write(_two(t.month))
      ..write(_two(t.day))
      ..write('-')
      ..write(_two(t.hour))
      ..write(_two(t.minute))
      ..write(_two(t.second))
      ..write(suffix);
    return buffer.toString();
  }

  /// 判斷某個檔名是否為 PackPlan 備份檔。
  static bool isBackupFile(String name) =>
      name.startsWith(prefix) && name.endsWith(suffix);

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _four(int value) => value.toString().padLeft(4, '0');
}
