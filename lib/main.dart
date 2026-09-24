import 'dart:async';

import 'package:flutter/material.dart';

import 'app/pack_plan_bootstrap.dart';
import 'data/pack_list_repository.dart';
import 'data/pack_plan_database_store.dart';
import 'data/persistent_pack_list_repository.dart';
import 'data/weight_reference_repository.dart';
import 'services/weight_reference_source.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final weightReferences = WeightReferenceRepository(
    source: FirestoreWeightReferenceSource(),
    cacheStore: FileWeightReferenceCacheStore(),
  );
  // 開 App 時在背景同步一次線上參考重量;離線或失敗就沿用快取。
  unawaited(weightReferences.syncQuietly());
  runApp(
    PackPlanBootstrap(
      initialize: _initializeRepository,
      resetLocalData: PackPlanDatabaseStore.reset,
      weightReferenceRepository: weightReferences,
    ),
  );
}

Future<PackListRepository> _initializeRepository() async {
  PackPlanDatabaseStore? store;
  try {
    store = await PackPlanDatabaseStore.open();
    return await PersistentPackListRepository.open(store);
  } catch (_) {
    await store?.close();
    rethrow;
  }
}
