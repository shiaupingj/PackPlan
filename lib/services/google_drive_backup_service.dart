import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'cloud_backup_service.dart';

/// Android 雲端備份：存進使用者 Google Drive 的專屬資料夾「PackPlan」。
///
/// 採 `drive.file` scope（只能存取本 App 建立的檔案），與 OAuth 同意畫面
/// 設定一致。保留多份歷史版本：每次備份都新增一份帶時間戳的檔案。
class GoogleDriveBackupService implements CloudBackupService {
  GoogleDriveBackupService({GoogleSignIn? googleSignIn})
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(scopes: const [drive.DriveApi.driveFileScope]);

  /// 備份檔存放的資料夾名稱（使用者可在 Drive 看到與管理）。
  static const String _folderName = 'PackPlan';
  static const String _folderMime = 'application/vnd.google-apps.folder';

  final GoogleSignIn _googleSignIn;

  @override
  Future<bool> isAvailable() async {
    try {
      final account =
          _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      return account != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> connect() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } on Exception catch (error) {
      throw CloudBackupException('無法連結 Google 帳號：$error');
    }
  }

  @override
  Future<void> disconnect() => _googleSignIn.signOut();

  @override
  Future<String?> accountLabel() async {
    final account =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    return account?.email;
  }

  @override
  Future<CloudBackupEntry> upload(Uint8List bytes) async {
    try {
      final api = await _api();
      final folderId = await _ensureFolder(api);
      final name = CloudBackupNaming.fileNameFor(DateTime.now());
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );
      final metadata = drive.File()
        ..name = name
        ..parents = [folderId];
      final created = await api.files.create(
        metadata,
        uploadMedia: media,
        $fields: 'id, name, createdTime, size',
      );
      return _toEntry(created) ??
          CloudBackupEntry(
            id: created.id ?? name,
            name: name,
            createdAt: DateTime.now(),
            sizeBytes: bytes.length,
          );
    } on CloudBackupException {
      rethrow;
    } on Exception catch (error) {
      throw CloudBackupException('無法上傳到 Google Drive：$error');
    }
  }

  @override
  Future<List<CloudBackupEntry>> list() async {
    try {
      final api = await _api();
      // drive.file scope 下 files.list 只會回傳本 App 建立的檔案，
      // 再以檔名前綴過濾即為 PackPlan 備份。
      final result = await api.files.list(
        spaces: 'drive',
        q: "name contains '${CloudBackupNaming.prefix}' and trashed = false",
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, createdTime, size)',
      );
      final files = result.files ?? const <drive.File>[];
      return files
          .where((file) => CloudBackupNaming.isBackupFile(file.name ?? ''))
          .map(_toEntry)
          .whereType<CloudBackupEntry>()
          .toList();
    } on Exception catch (error) {
      throw CloudBackupException('無法讀取 Google Drive 備份清單：$error');
    }
  }

  @override
  Future<Uint8List> download(CloudBackupEntry entry) async {
    try {
      final api = await _api();
      final media =
          await api.files.get(
                entry.id,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      return Uint8List.fromList(bytes);
    } on Exception catch (error) {
      throw CloudBackupException('無法從 Google Drive 下載備份：$error');
    }
  }

  @override
  Future<void> delete(CloudBackupEntry entry) async {
    try {
      final api = await _api();
      await api.files.delete(entry.id);
    } on Exception catch (error) {
      throw CloudBackupException('無法刪除 Google Drive 備份：$error');
    }
  }

  Future<drive.DriveApi> _api() async {
    final account =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) {
      throw const CloudBackupException('尚未連結 Google 帳號');
    }
    final headers = await account.authHeaders;
    return drive.DriveApi(_GoogleAuthClient(headers));
  }

  /// 找出或建立 PackPlan 資料夾，回傳其 id。
  Future<String> _ensureFolder(drive.DriveApi api) async {
    final result = await api.files.list(
      spaces: 'drive',
      q: "mimeType = '$_folderMime' and name = '$_folderName' "
          'and trashed = false',
      $fields: 'files(id)',
    );
    final existing = result.files;
    if (existing != null && existing.isNotEmpty) {
      final id = existing.first.id;
      if (id != null) return id;
    }
    final folder = drive.File()
      ..name = _folderName
      ..mimeType = _folderMime;
    final created = await api.files.create(folder, $fields: 'id');
    final id = created.id;
    if (id == null) {
      throw const CloudBackupException('無法建立 Google Drive 備份資料夾');
    }
    return id;
  }

  CloudBackupEntry? _toEntry(drive.File file) {
    final id = file.id;
    final name = file.name;
    if (id == null || name == null) return null;
    return CloudBackupEntry(
      id: id,
      name: name,
      createdAt: file.createdTime ?? DateTime.now(),
      sizeBytes: int.tryParse(file.size ?? '') ?? 0,
    );
  }
}

/// 把 google_sign_in 取得的授權標頭套到每個 Drive 請求上。
class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
