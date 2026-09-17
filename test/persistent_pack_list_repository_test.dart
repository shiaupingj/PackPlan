import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/data/pack_plan_database_store.dart';
import 'package:packplan/data/persistent_pack_list_repository.dart';
import 'package:packplan/models/user_settings.dart';
import 'package:packplan/services/backup_codec.dart';

void main() {
  test('first launch seeds and saves the database', () async {
    final store = _MemoryStateStore();
    final repository = await PersistentPackListRepository.open(store);
    await repository.flush();

    expect(repository.lists, hasLength(2));
    expect(store.bytes, isNotNull);
  });

  test('changes survive repository recreation', () async {
    final store = _MemoryStateStore();
    final first = await PersistentPackListRepository.open(store);
    final listId = first.lists.first.id;

    first.renameList(listId, '已持久保存的清單');
    first.updateSettings(
      const UserSettings(
        weightUnit: WeightUnit.gram,
        defaultWeightLimitGram: 9000,
      ),
    );
    await first.flush();

    final reopened = await PersistentPackListRepository.open(store);

    expect(reopened.findById(listId)!.title, '已持久保存的清單');
    expect(reopened.settings.weightUnit, WeightUnit.gram);
    expect(reopened.settings.defaultWeightLimitGram, 9000);
  });

  test('import replacement is written to the database', () async {
    final store = _MemoryStateStore();
    final repository = await PersistentPackListRepository.open(store);
    final onlyList = repository.lists.first;

    repository.replaceAllData(
      lists: [onlyList],
      settings: const UserSettings(defaultWeightLimitGram: 11000),
    );
    await repository.flush();

    final reopened = await PersistentPackListRepository.open(store);

    expect(reopened.lists, hasLength(1));
    expect(reopened.lists.single.id, onlyList.id);
    expect(reopened.settings.defaultWeightLimitGram, 11000);
  });

  test(
    'corrupted saved data is rejected instead of silently overwritten',
    () async {
      final store = _MemoryStateStore()
        ..bytes = Uint8List.fromList('not-a-packplan-backup'.codeUnits);

      await expectLater(
        PersistentPackListRepository.open(store),
        throwsA(isA<BackupFormatException>()),
      );
    },
  );

  test('save failure surfaces hasSaveError and recovery clears it', () async {
    // 寫入失敗會經由 FlutterError.reportError 記錄，測試中先靜音。
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (_) {};
    addTearDown(() => FlutterError.onError = oldOnError);

    final store = _FlakyStateStore();
    final repository = await PersistentPackListRepository.open(store);
    await repository.flush();
    expect(repository.hasSaveError, isFalse);

    var notifications = 0;
    repository.addListener(() => notifications += 1);
    final listId = repository.lists.first.id;

    store.failSaves = true;
    repository.renameList(listId, '寫入失敗的清單');
    await repository.flush();

    expect(repository.hasSaveError, isTrue);
    // 一次來自資料變更、一次來自寫入失敗的狀態轉換。
    expect(notifications, 2);

    store.failSaves = false;
    repository.renameList(listId, '寫入恢復的清單');
    await repository.flush();

    expect(repository.hasSaveError, isFalse);
    expect(notifications, 4);
  });

  testWidgets('save error banner appears and disappears with save state', (
    tester,
  ) async {
    final store = _FlakyStateStore();
    final repository = await PersistentPackListRepository.open(store);
    await repository.flush();
    await tester.pumpWidget(PackPlanApp(repository: repository));

    const bannerText = '無法寫入本機儲存，最新變更可能遺失。請確認裝置空間。';
    expect(find.text(bannerText), findsNothing);

    store.failSaves = true;
    repository.renameList(repository.lists.first.id, '寫入失敗的清單');
    await repository.flush();
    await tester.pumpAndSettle();

    // 寫入失敗會回報給 FlutterError，取出以免測試框架視為未處理例外。
    expect(tester.takeException(), isNotNull);
    expect(find.text(bannerText), findsOneWidget);

    store.failSaves = false;
    repository.renameList(repository.lists.first.id, '寫入恢復的清單');
    await repository.flush();
    await tester.pumpAndSettle();

    expect(find.text(bannerText), findsNothing);
  });
}

class _MemoryStateStore implements PackPlanStateStore {
  Uint8List? bytes;

  @override
  Future<Uint8List?> load() async {
    final current = bytes;
    return current == null ? null : Uint8List.fromList(current);
  }

  @override
  Future<void> save(Uint8List bytes) async {
    this.bytes = Uint8List.fromList(bytes);
  }

  @override
  Future<void> close() async {}
}

class _FlakyStateStore extends _MemoryStateStore {
  bool failSaves = false;

  @override
  Future<void> save(Uint8List bytes) async {
    if (failSaves) {
      throw Exception('disk full');
    }
    await super.save(bytes);
  }
}
