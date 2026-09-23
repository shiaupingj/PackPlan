import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'cloud_backup_service.dart';

/// Android 雲端備份:存進 Google Drive 的 `appDataFolder`（App 專用隱藏區,
/// 使用者在 Drive 看不到,也不佔一般檔案空間）。單檔 `backup.json` 覆蓋。
class GoogleDriveBackupService implements CloudBackupService {
  GoogleDriveBackupService({GoogleSignIn? googleSignIn})
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(scopes: const [drive.DriveApi.driveAppdataScope]);

  static const _fileName = 'backup.json';

  final GoogleSignIn _googleSignIn;

  @override
  bool get isSupported => true;

  @override
  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();

  @override
  Future<bool> signIn() async {
    final account = await _googleSignIn.signIn();
    return account != null;
  }

  @override
  Future<void> signOut() => _googleSignIn.signOut();

  Future<drive.DriveApi> _api() async {
    var account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('尚未登入 Google 帳號');
    }
    final headers = await account.authHeaders;
    return drive.DriveApi(_GoogleAuthClient(headers));
  }

  Future<drive.File?> _findBackup(drive.DriveApi api) async {
    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName'",
      $fields: 'files(id, modifiedTime)',
    );
    final files = result.files;
    if (files == null || files.isEmpty) return null;
    return files.first;
  }

  @override
  Future<void> uploadBackup(Uint8List bytes) async {
    final api = await _api();
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );
    final existing = await _findBackup(api);
    final existingId = existing?.id;
    if (existingId != null) {
      await api.files.update(drive.File(), existingId, uploadMedia: media);
    } else {
      final metadata = drive.File()
        ..name = _fileName
        ..parents = ['appDataFolder'];
      await api.files.create(metadata, uploadMedia: media);
    }
  }

  @override
  Future<CloudBackup?> downloadBackup() async {
    final api = await _api();
    final existing = await _findBackup(api);
    final existingId = existing?.id;
    if (existingId == null) return null;
    final media =
        await api.files.get(
              existingId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return CloudBackup(
      bytes: Uint8List.fromList(bytes),
      modifiedTime: existing?.modifiedTime,
    );
  }

  @override
  Future<DateTime?> lastBackupTime() async {
    final api = await _api();
    final existing = await _findBackup(api);
    return existing?.modifiedTime;
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
