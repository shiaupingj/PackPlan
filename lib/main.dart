import 'package:flutter/material.dart';

import 'app/pack_plan_bootstrap.dart';
import 'data/pack_list_repository.dart';
import 'data/pack_plan_database_store.dart';
import 'data/persistent_pack_list_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    PackPlanBootstrap(
      initialize: _initializeRepository,
      resetLocalData: PackPlanDatabaseStore.reset,
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
