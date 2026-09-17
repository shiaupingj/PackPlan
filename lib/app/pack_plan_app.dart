import 'package:flutter/material.dart';

import '../data/pack_list_repository.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';
import 'app_scope.dart';

class PackPlanApp extends StatefulWidget {
  const PackPlanApp({super.key, this.repository});

  final PackListRepository? repository;

  @override
  State<PackPlanApp> createState() => _PackPlanAppState();
}

class _PackPlanAppState extends State<PackPlanApp> {
  late final PackListRepository _repository =
      widget.repository ?? InMemoryPackListRepository();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: _repository,
      child: MaterialApp(
        title: 'PackPlan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AppShell(),
      ),
    );
  }
}
