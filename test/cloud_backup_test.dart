import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/data/pack_list_repository.dart';
import 'package:packplan/services/backup_codec.dart';
import 'package:packplan/services/cloud_backup_service.dart';

class FakeCloudBackupService implements CloudBackupService {
  FakeCloudBackupService({this.supported = true, this.signedIn = false});

  bool supported;
  bool signedIn;
  Uint8List? stored;
  DateTime? modified;
  int uploadCount = 0;
  int signInCount = 0;

  @override
  bool get isSupported => supported;

  @override
  Future<bool> isSignedIn() async => signedIn;

  @override
  Future<bool> signIn() async {
    signInCount += 1;
    signedIn = true;
    return true;
  }

  @override
  Future<void> signOut() async => signedIn = false;

  @override
  Future<void> uploadBackup(Uint8List bytes) async {
    stored = bytes;
    modified = DateTime(2026, 9, 21, 10, 30);
    uploadCount += 1;
  }

  @override
  Future<CloudBackup?> downloadBackup() async =>
      stored == null ? null : CloudBackup(bytes: stored!, modifiedTime: modified);

  @override
  Future<DateTime?> lastBackupTime() async => modified;
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('設定'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('unsupported platform shows an upcoming-support tile', (
    tester,
  ) async {
    final fake = FakeCloudBackupService(supported: false);
    await tester.pumpWidget(PackPlanApp(cloudBackupService: fake));
    await _openSettings(tester);

    await tester.scrollUntilVisible(
      find.text('此平台即將支援(iCloud 規劃中)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('此平台即將支援(iCloud 規劃中)'), findsOneWidget);
  });

  testWidgets('signing in reveals backup and restore actions', (tester) async {
    final fake = FakeCloudBackupService(signedIn: false);
    await tester.pumpWidget(PackPlanApp(cloudBackupService: fake));
    await _openSettings(tester);

    await tester.scrollUntilVisible(
      find.text('連結雲端帳號'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('連結雲端帳號'));
    await tester.pumpAndSettle();

    expect(fake.signInCount, 1);
    expect(find.text('備份到雲端'), findsOneWidget);
    expect(find.text('從雲端還原'), findsOneWidget);
  });

  testWidgets('backup uploads current data to the cloud', (tester) async {
    final fake = FakeCloudBackupService(signedIn: true);
    await tester.pumpWidget(PackPlanApp(cloudBackupService: fake));
    await _openSettings(tester);

    await tester.scrollUntilVisible(
      find.text('備份到雲端'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('備份到雲端'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fake.uploadCount, 1);
    expect(fake.stored, isNotNull);
    expect(find.textContaining('最後備份'), findsOneWidget);
  });

  testWidgets('restore asks for confirmation before replacing data', (
    tester,
  ) async {
    final repository = InMemoryPackListRepository();
    final fake = FakeCloudBackupService(signedIn: true);
    // 直接種一份有效的雲端備份,避免按備份鈕造出蓋住還原提示的 snackbar。
    fake.stored = BackupCodec.encode(
      lists: repository.lists,
      settings: repository.settings,
    );
    fake.modified = DateTime(2026, 9, 21, 10, 30);

    await tester.pumpWidget(
      PackPlanApp(repository: repository, cloudBackupService: fake),
    );
    await _openSettings(tester);
    await tester.scrollUntilVisible(
      find.text('從雲端還原'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    // 還原進行中會顯示旋轉指示器(無限動畫),故用 pump 而非 pumpAndSettle。
    await tester.tap(find.text('從雲端還原'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('從雲端還原並取代目前資料？'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '還原'));
    await tester.pump(); // 關閉對話框、續行 _restore
    await tester.pump(const Duration(milliseconds: 350)); // 對話框退場 + snackbar 進場

    expect(find.textContaining('已從雲端還原'), findsWidgets);
  });
}
