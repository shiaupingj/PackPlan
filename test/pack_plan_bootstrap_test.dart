import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/app/pack_plan_bootstrap.dart';
import 'package:packplan/data/pack_list_repository.dart';

void main() {
  testWidgets('startup error offers retry and enters the app after recovery', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      PackPlanBootstrap(
        initialize: () async {
          attempts += 1;
          if (attempts == 1) {
            throw const FormatException('corrupted payload');
          }
          return InMemoryPackListRepository();
        },
        resetLocalData: () async {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('無法讀取本機資料'), findsOneWidget);
    expect(find.text('重新嘗試'), findsOneWidget);
    expect(find.text('重建本機資料'), findsOneWidget);
    // 實機 release 沒有 log:錯誤原因直接顯示在畫面上,方便截圖回報。
    expect(
      find.text('錯誤原因：FormatException: FormatException: corrupted payload'),
      findsOneWidget,
    );

    await tester.tap(find.text('重新嘗試'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('打包清單'), findsOneWidget);
  });

  testWidgets('reset requires confirmation before rebuilding local data', (
    tester,
  ) async {
    var attempts = 0;
    var resets = 0;

    await tester.pumpWidget(
      PackPlanBootstrap(
        initialize: () async {
          attempts += 1;
          if (resets == 0) throw StateError('database unavailable');
          return InMemoryPackListRepository();
        },
        resetLocalData: () async {
          resets += 1;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('重建本機資料'));
    await tester.pumpAndSettle();

    expect(find.text('重建本機資料？'), findsOneWidget);
    expect(resets, 0);

    await tester.tap(find.widgetWithText(FilledButton, '重建資料'));
    await tester.pumpAndSettle();

    expect(resets, 1);
    expect(attempts, 2);
    expect(find.text('打包清單'), findsOneWidget);
  });
}
