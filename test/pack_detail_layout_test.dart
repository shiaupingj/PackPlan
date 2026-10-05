import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/app/pack_plan_app.dart';
import 'package:packplan/data/pack_list_repository.dart';
import 'package:packplan/theme/app_colors.dart';
import 'package:packplan/theme/app_palette.dart';

void main() {
  Future<void> openDetail(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      PackPlanApp(repository: InMemoryPackListRepository()),
    );
    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();
  }

  /// Icon 實際畫出來的顏色(沒指定顏色時取自 IconTheme)。
  Color? iconColor(WidgetTester tester, Finder icon) => tester
      .widget<RichText>(
        find.descendant(of: icon, matching: find.byType(RichText)),
      )
      .text
      .style
      ?.color;

  AppPalette palette(WidgetTester tester) => Theme.of(
    tester.element(find.byType(Scaffold).last),
  ).extension<AppPalette>()!;

  testWidgets('按鈕 icon 與文字同色', (tester) async {
    await openDetail(tester);

    for (final (label, icon) in [
      ('新增項目', Icons.add),
      ('分類排序', Icons.swap_vert),
    ]) {
      final button = find.widgetWithText(FilledButton, label);
      final labelColor = tester
          .widget<RichText>(
            find.descendant(
              of: find.descendant(of: button, matching: find.text(label)),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style
          ?.color;
      expect(
        iconColor(
          tester,
          find.descendant(of: button, matching: find.byIcon(icon)),
        ),
        labelColor,
        reason: label,
      );
      expect(labelColor, isNot(AppColors.primary));
    }
  });

  testWidgets('App Bar 與分類卡右上的 icon 用 text-secondary', (tester) async {
    await openDetail(tester);
    final secondary = palette(tester).textSecondary;

    for (final tooltip in ['旅程設定', '更多', '新增工具項目']) {
      expect(
        iconColor(
          tester,
          find.descendant(
            of: find.byTooltip(tooltip),
            matching: find.byType(Icon),
          ),
        ),
        secondary,
        reason: tooltip,
      );
    }
    expect(iconColor(tester, find.byIcon(Icons.expand_more).first), secondary);
  });

  testWidgets('超輕量化收在重量卡最下方,開啟後點摘要看可刪減項目', (tester) async {
    await openDetail(tester);

    final weightCard = find.ancestor(
      of: find.byKey(const ValueKey('weight-header-total')),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(of: weightCard, matching: find.text('超輕量化')),
      findsOneWidget,
    );
    expect(find.text('超輕量化打包'), findsNothing);
    expect(find.byKey(const ValueKey('ul-mode-summary')), findsNothing);

    await tester.tap(
      find.descendant(of: weightCard, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();

    final summary = find.byKey(const ValueKey('ul-mode-summary'));
    expect(
      find.descendant(
        of: summary,
        matching: find.textContaining(RegExp(r'^最低可行 .+ · 可刪減 \d+ 項$')),
      ),
      findsOneWidget,
    );

    await tester.tap(summary);
    await tester.pumpAndSettle();
    expect(find.text('可刪減項目'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
  });

  testWidgets('放置位置不是卡片,分頁數字加括號、選中有底線', (tester) async {
    await openDetail(tester);

    expect(
      find.ancestor(of: find.text('放置位置'), matching: find.byType(Card)),
      findsNothing,
    );
    final all = find.byKey(const ValueKey('placement-tab-all'));
    expect(
      find.descendant(
        of: all,
        matching: find.textContaining(RegExp(r'^\(\d+\)$')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: all,
        matching: find.byKey(const ValueKey('placement-tab-indicator')),
      ),
      findsOneWidget,
    );
    expect(
      iconColor(tester, find.descendant(of: all, matching: find.text('全部'))),
      AppColors.primary,
      reason: '選中分頁文字用橘色主色',
    );
  });

  testWidgets('上限放在總重同一行的最右邊', (tester) async {
    await openDetail(tester);

    final total = tester.getRect(
      find.byKey(const ValueKey('weight-header-total')),
    );
    final limit = tester.getRect(
      find.byKey(const ValueKey('weight-header-limit')),
    );
    expect(limit.left, greaterThan(total.right));
    expect(limit.bottom, inInclusiveRange(total.top, total.bottom));
  });

  testWidgets('首頁清單卡:進度在左、總重在右,同一行', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      PackPlanApp(repository: InMemoryPackListRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('基重'), findsNothing);
    final progress = tester.getRect(find.textContaining('進度 ').first);
    final weight = tester.getRect(find.textContaining('總重 ').first);
    expect(weight.center.dy, closeTo(progress.center.dy, 1));
    expect(weight.left, greaterThan(progress.right));
  });

  testWidgets('建立清單:按鈕與「建立新清單」同高,選項不打勾只用顏色', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      PackPlanApp(repository: InMemoryPackListRepository()),
    );
    await tester.pumpAndSettle();
    final ctaHeight = tester
        .getSize(find.widgetWithText(FilledButton, '建立新清單'))
        .height;

    await tester.tap(find.text('建立新清單'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('基礎登山'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.widgetWithText(FilledButton, '下一步')).height,
      ctaHeight,
    );

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.widgetWithText(OutlinedButton, '上一步')).height,
      ctaHeight,
    );
    expect(find.byIcon(Icons.check), findsNothing, reason: '天氣選項不打勾');

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 / 4'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing, reason: '項目選項不打勾');
  });

  testWidgets('往下捲時,放置位置標題、分頁與說明固定在頂端', (tester) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      PackPlanApp(repository: InMemoryPackListRepository()),
    );
    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();

    final header = find.byKey(const ValueKey('placement-pinned-header'));
    final appBarBottom = tester.getRect(find.byType(AppBar)).bottom;
    final startTop = tester.getRect(header).top;
    expect(startTop, greaterThan(appBarBottom + 100), reason: '一開始在重量卡下方');

    final firstCategory = find.text('背包系統');
    final categoryBefore = tester.getRect(firstCategory).top;
    await tester.drag(
      find.byKey(const ValueKey('pack-detail-scroll')),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();

    final pinned = tester.getRect(header);
    expect(pinned.top, closeTo(appBarBottom, 1), reason: '捲到頂後停在 App Bar 下');
    for (final text in ['放置位置', '全部']) {
      final rect = tester.getRect(find.text(text));
      expect(rect.top, greaterThanOrEqualTo(pinned.top), reason: text);
      expect(rect.bottom, lessThanOrEqualTo(pinned.bottom), reason: text);
    }
    expect(
      find.descendant(of: header, matching: find.textContaining('點分頁')),
      findsOneWidget,
      reason: '分頁下方的說明/摘要也一起固定',
    );
    // 分類內容繼續往上捲(已捲出畫面或位置上移)。
    final categoryAfter = firstCategory.evaluate().isEmpty
        ? double.negativeInfinity
        : tester.getRect(firstCategory).top;
    expect(categoryAfter, lessThan(categoryBefore));
  });

  testWidgets('固定在頂端時切換分頁,仍維持固定並從新分頁開頭顯示', (tester) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      PackPlanApp(repository: InMemoryPackListRepository()),
    );
    await tester.tap(find.text('登山計劃'));
    await tester.pumpAndSettle();

    final header = find.byKey(const ValueKey('placement-pinned-header'));
    final appBarBottom = tester.getRect(find.byType(AppBar)).bottom;
    await tester.drag(
      find.byKey(const ValueKey('pack-detail-scroll')),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(header).top, closeTo(appBarBottom, 1));

    await tester.tap(find.byKey(const ValueKey('placement-tab-pack')));
    await tester.pumpAndSettle();

    final pinned = tester.getRect(header);
    expect(pinned.top, closeTo(appBarBottom, 1), reason: '沒有跳回頁面最上方');
    expect(
      find.descendant(of: header, matching: find.textContaining('本體')),
      findsOneWidget,
    );
    // 新分頁第一個分類緊接在固定區塊下方。
    final firstCategory = tester.getRect(find.text('背包系統'));
    expect(firstCategory.top, greaterThanOrEqualTo(pinned.bottom));
    expect(firstCategory.top, lessThan(pinned.bottom + 40));

    // 未固定時切換分頁不改捲動位置。
    await tester.drag(
      find.byKey(const ValueKey('pack-detail-scroll')),
      const Offset(0, 3000),
    );
    await tester.pumpAndSettle();
    final before = tester.getRect(header).top;
    await tester.tap(find.byKey(const ValueKey('placement-tab-all')));
    await tester.pumpAndSettle();
    expect(tester.getRect(header).top, before);
  });

  testWidgets('分類卡箭頭:展開時 v、收合時 ^', (tester) async {
    await openDetail(tester);

    final toggle = find.byKey(const ValueKey('category-toggle-背包系統'));
    expect(tester.widget<Icon>(toggle).icon, Icons.expand_more);
    expect(find.text('主背包 45L'), findsWidgets);

    await tester.tap(find.text('背包系統'));
    await tester.pumpAndSettle();
    expect(tester.widget<Icon>(toggle).icon, Icons.expand_less);

    await tester.tap(find.text('背包系統'));
    await tester.pumpAndSettle();
    expect(tester.widget<Icon>(toggle).icon, Icons.expand_more);
  });
}
