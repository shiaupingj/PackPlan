import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/pack_plan_bootstrap.dart';
import 'data/pack_list_repository.dart';
import 'data/pack_plan_database_store.dart';
import 'data/persistent_pack_list_repository.dart';
import 'data/weight_reference_repository.dart';
import 'services/crash_reporting.dart';
import 'services/weight_reference_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 版面只針對直向設計;iPhone 另在 Info.plist 限定直向。
  unawaited(
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  );
  final weightReferences = WeightReferenceRepository(
    source: FirestoreWeightReferenceSource(),
    cacheStore: FileWeightReferenceCacheStore(),
  );
  // 開 App 時在背景同步一次線上參考重量;離線或失敗就沿用快取。
  unawaited(weightReferences.syncQuietly());
  await CrashReporting.run(
    () => runApp(
      PackPlanBootstrap(
        initialize: _initializeRepository,
        resetLocalData: PackPlanDatabaseStore.reset,
        weightReferenceRepository: weightReferences,
      ),
    ),
  );
}

Future<PackListRepository> _initializeRepository() async {
  PackPlanDatabaseStore? store;
  try {
    store = await PackPlanDatabaseStore.open();
    return await PersistentPackListRepository.open(store);
  } catch (error, stackTrace) {
    // 本機資料讀不回來會進復原畫面;這類錯誤一定要知道。
    CrashReporting.report(error, stackTrace);
    await store?.close();
    rethrow;
  }
}
