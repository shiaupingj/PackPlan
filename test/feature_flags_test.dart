import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/app/feature_flags.dart';
import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/data/pack_list_repository.dart';
import 'package:packplan/data/seed_data.dart';

void main() {
  void previewPro(bool enabled) {
    FeatureFlags.debugPreviewPro = enabled;
    addTearDown(() => FeatureFlags.debugPreviewPro = false);
  }

  test('正式版:不列 Pro 範本', () {
    previewPro(false);
    final names = FeatureFlags.visibleTemplates(
      SeedData.templates,
    ).map((t) => t.name);
    expect(names, ['基礎登山', '城市旅遊']);
  });

  test('debug 預覽:列出全部範本,且都不上鎖', () {
    previewPro(true);
    expect(
      FeatureFlags.visibleTemplates(SeedData.templates),
      hasLength(SeedData.templates.length),
    );
    expect(SeedData.templates.where(FeatureFlags.isLocked), isEmpty);
  });

  testWidgets('debug 預覽:範本頁可直接選進階登山進入建立流程', (tester) async {
    previewPro(true);
    tester.view
      ..physicalSize = const Size(400, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      PackPlanApp(repository: InMemoryPackListRepository()),
    );
    await tester.tap(find.text('範本'));
    await tester.pumpAndSettle();

    for (final name in ['進階登山', '極簡露營', '長天數旅行']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    await tester.tap(find.text('進階登山'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 / 4'), findsOneWidget);
  });
}
