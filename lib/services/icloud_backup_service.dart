import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:icloud_storage/icloud_storage.dart';

import 'cloud_backup_service.dart';

/// 以 Apple iCloud Documents 容器實作的雲端備份。
///
/// 備份檔存放在容器根目錄，檔名帶時間戳以保留多份歷史版本。
/// 對應設定：Xcode iCloud capability + 容器
/// `iCloud.com.packplan.packplan`。
class ICloudBackupService implements CloudBackupService {
  ICloudBackupService({this.containerId = defaultContainerId});

  /// PackPlan 的 iCloud 容器 id，需與 Runner.entitlements 一致。
  static const String defaultContainerId = 'iCloud.com.packplan.packplan';

  /// 等待 iCloud 下載完成的上限，避免網路異常時無限卡住。
  static const Duration _downloadTimeout = Duration(seconds: 90);

  final String containerId;

  @override
  Future<bool> isAvailable() async {
    // iCloud 未登入時 gather 會拋出 PlatformException。
    try {
      await ICloudStorage.gather(containerId: containerId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // iCloud 使用裝置上的 Apple ID，不需要應用層連結流程。
  @override
  Future<bool> connect() => isAvailable();

  @override
  Future<void> disconnect() async {}

  @override
  Future<String?> accountLabel() async => null;

  @override
  Future<CloudBackupEntry> upload(Uint8List bytes) async {
    final now = DateTime.now();
    final name = CloudBackupNaming.fileNameFor(now);
    final temp = await _writeTempFile(name, bytes);
    try {
      // upload() 回傳時本地容器檔已寫入，iCloud 同步在背景進行，
      // 因此不需等待 onProgress 即可安全刪除暫存檔。
      await ICloudStorage.upload(
        containerId: containerId,
        filePath: temp.path,
        destinationRelativePath: name,
      );
      return CloudBackupEntry(
        id: name,
        name: name,
        createdAt: now,
        sizeBytes: bytes.length,
      );
    } on Exception catch (error) {
      throw CloudBackupException('無法上傳到 iCloud：$error');
    } finally {
      await _safeDelete(temp);
    }
  }

  @override
  Future<List<CloudBackupEntry>> list() async {
    final List<ICloudFile> files;
    try {
      files = await ICloudStorage.gather(containerId: containerId);
    } on Exception catch (error) {
      throw CloudBackupException('無法讀取 iCloud 備份清單：$error');
    }

    final entries = files
        .where((file) => CloudBackupNaming.isBackupFile(_fileName(file.relativePath)))
        .map(
          (file) => CloudBackupEntry(
            id: file.relativePath,
            name: _fileName(file.relativePath),
            createdAt: file.contentChangeDate,
            sizeBytes: file.sizeInBytes,
          ),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  @override
  Future<Uint8List> download(CloudBackupEntry entry) async {
    final destination = File(
      '${Directory.systemTemp.path}/packplan-restore-'
      '${DateTime.now().microsecondsSinceEpoch}.json',
    );
    try {
      final done = Completer<void>();
      await ICloudStorage.download(
        containerId: containerId,
        relativePath: entry.id,
        destinationFilePath: destination.path,
        onProgress: (stream) {
          stream.listen(
            null,
            onDone: () {
              if (!done.isCompleted) done.complete();
            },
            onError: (Object error) {
              if (!done.isCompleted) done.completeError(error);
            },
          );
        },
      );
      // download() 回傳時檔案未必已落地，需等 onProgress 結束再讀取。
      await done.future.timeout(
        _downloadTimeout,
        onTimeout: () =>
            throw const CloudBackupException('從 iCloud 下載逾時，請確認網路後再試'),
      );
      final materialized = await _awaitFile(destination);
      return await materialized.readAsBytes();
    } on CloudBackupException {
      rethrow;
    } on Exception catch (error) {
      throw CloudBackupException('無法從 iCloud 下載備份：$error');
    } finally {
      await _safeDelete(destination);
    }
  }

  @override
  Future<void> delete(CloudBackupEntry entry) async {
    try {
      await ICloudStorage.delete(
        containerId: containerId,
        relativePath: entry.id,
      );
    } on Exception catch (error) {
      throw CloudBackupException('無法刪除 iCloud 備份：$error');
    }
  }

  Future<File> _writeTempFile(String name, Uint8List bytes) async {
    final file = File('${Directory.systemTemp.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// onProgress 結束後檔案偶爾仍在落地，短暫輪詢等它出現。
  Future<File> _awaitFile(File file) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      if (await file.exists() && await file.length() > 0) return file;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    throw const CloudBackupException('iCloud 備份下載後找不到檔案內容');
  }

  Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // 暫存檔清理失敗不影響備份結果。
    }
  }

  String _fileName(String relativePath) => relativePath.split('/').last;
}
