import 'package:flutter/material.dart';

import '../data/pack_list_repository.dart';

class AppScope extends InheritedNotifier<PackListRepository> {
  const AppScope({
    super.key,
    required PackListRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static PackListRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree.');
    return scope!.notifier!;
  }
}
