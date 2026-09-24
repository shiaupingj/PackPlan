import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/services/cloud_backup_service.dart';
import 'package:packplan/services/google_drive_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GoogleDriveBackupService 是 CloudBackupService', () {
    expect(GoogleDriveBackupService(), isA<CloudBackupService>());
  });

  test('無平台實作時 isAvailable 安全回傳 false（不拋例外）', () async {
    // 測試環境沒有 google_sign_in 原生實作，signInSilently 會拋
    // MissingPluginException；isAvailable 必須吞掉並回 false。
    final service = GoogleDriveBackupService();
    expect(await service.isAvailable(), isFalse);
  });

  test('未連結帳號時對 Drive 操作丟出可顯示的 CloudBackupException', () async {
    final service = GoogleDriveBackupService();
    await expectLater(service.list(), throwsA(isA<CloudBackupException>()));
  });

  tearDown(() {
    // 清掉任何被安裝的假 method channel handler（保險）。
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/google_sign_in'),
          null,
        );
  });
}
