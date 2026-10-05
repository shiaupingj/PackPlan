import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/data/pack_list_repository.dart';
import 'package:packplan/models/pack_list.dart';
import 'package:packplan/theme/app_colors.dart';

void main() {
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<InMemoryPackListRepository> openCreateFlow(WidgetTester tester) async {
    // Step 3 項目很多,ListView 只建可見範圍;畫面拉高讓「下一步」一定被建出來。
    tester.view
      ..physicalSize = const Size(400, 6000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = InMemoryPackListRepository();
    await tester.pumpWidget(PackPlanApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('建立新清單'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 / 4'), findsOneWidget);
    return repository;
  }

  Future<void> goToReview(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tapVisible(tester, find.text('下一步'));
    }
    expect(find.text('Step 4 / 4'), findsOneWidget);
  }

  final titleField = find.byKey(const ValueKey('create-list-title'));
  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(titleField).controller!.text;

  testWidgets('清單名稱在 Step 2,帶入所選範本的預設名稱', (tester) async {
    await openCreateFlow(tester);

    expect(titleField, findsNothing, reason: 'Step 1 不放名稱');
    await tapVisible(tester, find.text('城市旅遊'));
    await tapVisible(tester, find.text('下一步'));
    expect(find.text('Step 2 / 4'), findsOneWidget);
    expect(fieldText(tester), '城市旅遊');

    await tapVisible(tester, find.text('上一步'));
    await tapVisible(tester, find.text('基礎登山'));
    await tapVisible(tester, find.text('下一步'));
    expect(fieldText(tester), '登山計劃', reason: '沒自己改過時跟著範本換');
  });

  testWidgets('Step 2 自訂名稱:換範本不覆蓋,Step 4 卡片滿版並顯示名稱', (tester) async {
    final repository = await openCreateFlow(tester);

    await tapVisible(tester, find.text('基礎登山'));
    await tapVisible(tester, find.text('下一步'));
    await tester.enterText(titleField, '奇萊北峰');
    await tapVisible(tester, find.text('上一步'));
    await tapVisible(tester, find.text('城市旅遊'));
    await tapVisible(tester, find.text('下一步'));
    expect(fieldText(tester), '奇萊北峰');
    await tapVisible(tester, find.text('上一步'));
    await tapVisible(tester, find.text('基礎登山'));

    await goToReview(tester);
    expect(titleField, findsNothing, reason: '名稱只在 Step 2 設定');
    final title = find.byKey(const ValueKey('review-list-title'));
    expect(tester.widget<Text>(title).data, '奇萊北峰');
    final card = find.ancestor(of: title, matching: find.byType(Card));
    expect(tester.getSize(card).width, closeTo(400 - 32, 1));

    await tapVisible(tester, find.text('生成清單'));
    expect(find.widgetWithText(AppBar, '奇萊北峰'), findsOneWidget);
    expect(repository.lists.first.title, '奇萊北峰');
  });

  testWidgets('從範本分頁進來(跳過 Step 1)也能在 Step 2 設名稱', (tester) async {
    tester.view
      ..physicalSize = const Size(400, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      PackPlanApp(repository: InMemoryPackListRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('範本'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('城市旅遊').last);

    expect(find.text('Step 2 / 4'), findsOneWidget);
    expect(fieldText(tester), '城市旅遊');
  });

  test('名稱空白時用預設名稱', () {
    final repository = InMemoryPackListRepository();
    final template = repository.templates.firstWhere(
      (t) => t.tripType == TripType.hiking && !t.proOnly,
    );
    final list = repository.createFromDraft(
      CreatePackListDraft(
        template: template,
        days: 2,
        weatherConditions: {WeatherCondition.sunny},
        title: '   ',
      ),
    );
    expect(list.title, defaultPackListTitle(TripType.hiking));
  });

  testWidgets('旅程設定:天氣不打勾、顯示重量沒有說明文字', (tester) async {
    await tester.pumpWidget(
      PackPlanApp(repository: InMemoryPackListRepository()),
    );
    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('旅程設定'));
    await tester.pumpAndSettle();

    for (final chip in tester.widgetList<FilterChip>(find.byType(FilterChip))) {
      expect(chip.showCheckmark, isFalse);
    }
    expect(
      find.descendant(
        of: find.byType(FilterChip),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
    expect(find.text('套用於首頁、清單詳情與分享摘要'), findsNothing);
    expect(find.text('顯示重量'), findsOneWidget);
  });

  testWidgets('城市旅遊 Step 3:指定項目預設不勾,其餘預設勾', (tester) async {
    await openCreateFlow(tester);
    await tapVisible(tester, find.text('城市旅遊'));
    await tapVisible(tester, find.text('下一步'));
    // 選雨天與晴天,讓天氣裝備(背包防雨套、防曬用品)也出現。
    await tapVisible(tester, find.byKey(const ValueKey('weather-chip-rainy')));
    await tapVisible(tester, find.text('下一步'));
    expect(find.text('Step 3 / 4'), findsOneWidget);

    bool selected(String key) =>
        tester
            .widget<Material>(find.byKey(ValueKey('draft-item-$key')))
            .color ==
        AppColors.primary;
    for (final key in [
      'luggage:登機箱',
      'luggage:後背包',
      'clothes:正式服裝',
      'clothes:睡衣',
      'clothes:圍巾配件',
      'toiletries:刮鬍刀',
      'toiletries:隱形眼鏡/眼鏡',
      'toiletries:化妝品',
      'toiletries:保養品',
      'toiletries:毛巾',
      'toiletries:洗面乳',
      'electronics:耳機',
      'electronics:相機',
      'documents:旅遊保險',
      'personal:環保購物袋',
      'personal:太陽眼鏡',
      'personal:水瓶',
      'weather:背包防雨套',
      'weather:防曬用品',
    ]) {
      expect(selected(key), isFalse, reason: key);
    }
    for (final key in [
      'luggage:隨身包',
      'clothes:上衣',
      'documents:護照/證件',
      'personal:雨傘',
    ]) {
      expect(selected(key), isTrue, reason: key);
    }
  });

  testWidgets('Step 2 清單名稱:標題字級同 Step 3 項目文字,輸入文字 22', (tester) async {
    await openCreateFlow(tester);
    await tapVisible(tester, find.text('基礎登山'));
    await tapVisible(tester, find.text('下一步'));

    double? fontSize(Finder text) => tester
        .widget<RichText>(
          find.descendant(of: text, matching: find.byType(RichText)),
        )
        .text
        .style
        ?.fontSize;
    final labelSize = fontSize(find.text('清單名稱'));
    final inputSize = tester
        .widget<EditableText>(
          find.descendant(of: titleField, matching: find.byType(EditableText)),
        )
        .style
        .fontSize;

    await tapVisible(tester, find.text('下一步'));
    final itemSize = fontSize(
      find.descendant(
        of: find.byKey(const ValueKey('draft-item-backpack:大背包')),
        matching: find.text('大背包'),
      ),
    );
    expect(itemSize, isNotNull);
    expect(labelSize, itemSize);
    expect(inputSize, 22);
  });

  testWidgets('進階登山 Step 3 沿用基礎登山的預設不勾名單', (tester) async {
    await openCreateFlow(tester);
    await tapVisible(tester, find.text('進階登山'));
    await tapVisible(tester, find.text('下一步'));
    await tapVisible(tester, find.text('下一步'));

    bool selected(String key) =>
        tester
            .widget<Material>(find.byKey(ValueKey('draft-item-$key')))
            .color ==
        AppColors.primary;
    for (final key in ['backpack:小背包', 'personal:雨傘', 'hiking-tools:手套']) {
      expect(selected(key), isFalse, reason: key);
    }
    for (final key in ['backpack:大背包', 'advanced-gear:頭盔']) {
      expect(selected(key), isTrue, reason: key);
    }
  });

  testWidgets('Step 3 的上一步/下一步固定在頁面底部,其他步驟不固定', (tester) async {
    // 一般手機高度:Step 3 內容超出一頁,按鈕仍要看得到。
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      PackPlanApp(repository: InMemoryPackListRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('建立新清單'));
    await tester.pumpAndSettle();
    final pinned = find.byKey(const ValueKey('create-flow-pinned-actions'));
    expect(pinned, findsNothing);

    await tester.tap(find.text('基礎登山'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(pinned, findsNothing);
    await tapVisible(tester, find.text('下一步'));
    expect(find.text('Step 3 / 4'), findsOneWidget);

    expect(pinned, findsOneWidget);
    final next = find.descendant(of: pinned, matching: find.text('下一步'));
    expect(next, findsOneWidget);
    expect(tester.getRect(pinned).bottom, closeTo(800, 1));
    // 捲到底按鈕位置不變。
    final before = tester.getRect(next);
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.getRect(next), before);

    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Step 4 / 4'), findsOneWidget);
    expect(pinned, findsNothing);
  });
}
