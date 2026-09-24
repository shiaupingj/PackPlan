import 'package:flutter/widgets.dart';

import '../data/weight_reference_repository.dart';

/// 讓畫面取用 [WeightReferenceRepository];測試可注入 fake 來源。
class WeightReferenceScope extends InheritedWidget {
  const WeightReferenceScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final WeightReferenceRepository repository;

  static WeightReferenceRepository of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<WeightReferenceScope>();
    assert(scope != null, 'WeightReferenceScope not found in widget tree.');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(WeightReferenceScope oldWidget) =>
      oldWidget.repository != repository;
}
