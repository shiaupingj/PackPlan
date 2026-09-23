import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/data/pack_list_repository.dart';
import 'package:packplan/services/cloud_backup_service.dart';

/// 記憶體版雲端備份，供 UI 測試注入。
class FakeCloudBackupService implements CloudBackupService {
  FakeCloudBackupService({this.available = true});

  bool available;
  final List<CloudBackupEntry> _store = [];
  final Map<String, Uint8List> _bytes = {};
  int _seq = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> connect() async {
    available = true;
    return true;
  }

  @override
  Future<void> disconnect() async => available = false;

  @override
  Future<String?> accountLabel() async =>
      available ? 'test@example.com' : null;

  @override
  Future<CloudBackupEntry> upload(Uint8List bytes) async {
    _seq += 1;
    final id = 'backup-$_seq';
    final entry = CloudBackupEntry(
      id: id,
      name: '$id.json',
      createdAt: DateTime(2026, 9, 22, 10, _seq),
      sizeBytes: bytes.length,
    );
    _store.insert(0, entry);
    _bytes[id] = bytes;
    return entry;
  }

  @override
  Future<List<CloudBackupEntry>> list() async => List.of(_store);

  @override
  Future<Uint8List> download(CloudBackupEntry entry) async => _bytes[entry.id]!;

  @override
  Future<void> delete(CloudBackupEntry entry) async {
    _store.removeWhere((e) => e.id == entry.id);
    _bytes.remove(entry.id);
  }
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('設定'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('雲端備份'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('已連結時可備份並列出新版本', (tester) async {
    final fake = FakeCloudBackupService(available: true);
    await tester.pumpWidget(
      PackPlanApp(
        repository: InMemoryPackListRepository(),
        cloudBackupService: fake,
      ),
    );
    await tester.pumpAndSettle();
    await _openSettings(tester);

    expect(find.text('立即備份到雲端'), findsOneWidget);
    expect(find.text('尚無雲端備份，點上方按鈕建立第一份。'), findsOneWidget);

    await tester.tap(find.text('立即備份到雲端'));
    await tester.pumpAndSettle();

    expect(find.text('備份版本（1）'), findsOneWidget);
    expect(find.text('還原'), findsOneWidget);
  });

  testWidgets('未連結時顯示連結按鈕', (tester) async {
    final fake = FakeCloudBackupService(available: false);
    await tester.pumpWidget(
      PackPlanApp(
        repository: InMemoryPackListRepository(),
        cloudBackupService: fake,
      ),
    );
    await tester.pumpAndSettle();
    await _openSettings(tester);

    // 狀態列是「尚未連結 Google Drive」，按鈕是「連結 Google Drive」，字串不同。
    expect(find.text('連結 Google Drive'), findsOneWidget);
    expect(find.text('立即備份到雲端'), findsNothing);
  });

  testWidgets('還原會以雲端備份取代目前資料', (tester) async {
    final repository = InMemoryPackListRepository();
    final fake = FakeCloudBackupService(available: true);
    await tester.pumpWidget(
      PackPlanApp(repository: repository, cloudBackupService: fake),
    );
    await tester.pumpAndSettle();
    await _openSettings(tester);

    await tester.tap(find.text('立即備份到雲端'));
    await tester.pumpAndSettle();
    // 先讓「已備份」SnackBar 逾時消失，避免與稍後的「已還原」疊在一起。
    await tester.pump(const Duration(seconds: 5));

    await tester.ensureVisible(find.text('還原'));
    await tester.tap(find.text('還原'));
    await tester.pumpAndSettle();
    // 確認對話框出現後按下還原。
    await tester.tap(find.widgetWithText(FilledButton, '還原'));
    await tester.pumpAndSettle();

    expect(find.textContaining('已還原'), findsOneWidget);
  });
}
