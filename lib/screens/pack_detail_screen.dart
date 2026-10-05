import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../app/weight_reference_scope.dart';
import '../data/weight_reference_repository.dart';
import '../models/gear_weight.dart';
import '../models/pack_item.dart';
import '../models/pack_list.dart';
import '../models/user_settings.dart';
import '../services/formatters.dart';
import '../services/share_summary_builder.dart';
import '../services/system_share_service.dart';
import '../services/trip_formatters.dart';
import '../services/weight_calculator.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';
import '../widgets/app_buttons.dart';
import '../widgets/checklist_tile.dart';
import '../widgets/delete_list_dialog.dart';
import '../widgets/weight_reference_sheets.dart';
import '../widgets/weather_choice_chips.dart';
import '../widgets/weight_bar.dart';
import '../widgets/app_dialog_title.dart';

class PackDetailScreen extends StatefulWidget {
  const PackDetailScreen({super.key, required this.listId});

  final String listId;

  @override
  State<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends State<PackDetailScreen> {
  bool _ulMode = false;

  /// 放置位置分頁:null 為全部,否則是容器 id、[_unassignedTab] 或 [_wornTab]。
  String? _placement;
  WeightReferenceRepository? _references;

  /// 剛從「⋯」選單刪除的清單,只在返回首頁的轉場期間使用。
  PackList? _deletedList;

  final _scrollController = ScrollController();

  /// 「放置位置」區塊剛好固定在頂端時的捲動位置(= 它上方內容的總高度)。
  /// 每次排版時由區塊前的 [SliverLayoutBuilder] 更新。
  double _placementPinnedOffset = 0;

  bool get _placementPinned =>
      _scrollController.hasClients &&
      _scrollController.offset >= _placementPinnedOffset - 0.5;

  /// 切換放置位置分頁。區塊已固定在頂端時維持固定,並從新分頁的第一個分類開始看,
  /// 不因內容變少被拉回頁面最上方。
  void _selectPlacement(String? value) {
    final keepPinned = _placementPinned;
    setState(() => _placement = value);
    if (!keepPinned) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_placementPinnedOffset);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final references = WeightReferenceScope.of(context);
    if (!identical(references, _references)) {
      _references?.removeListener(_handleReferencesChanged);
      _references = references..addListener(_handleReferencesChanged);
      references.load();
    }
  }

  @override
  void dispose() {
    _references?.removeListener(_handleReferencesChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleReferencesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context);
    // 從「⋯」刪除時,返回動畫期間仍畫刪除前的內容,不閃「找不到這份清單」。
    final list = repository.findById(widget.listId) ?? _deletedList;
    final settings = repository.settings;

    if (list == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('找不到這份清單')),
      );
    }

    final summary = WeightCalculator.summarize(list);
    final groupedItems = _groupItems(list.items);
    final suggestions = WeightCalculator.suggestions(list);
    final containers = _containerItems(list.items);
    final placement = _validPlacement(list.items, containers);
    final visibleGroups = {
      for (final entry in groupedItems.entries)
        if (entry.value.where((item) => _inPlacement(item, placement)).toList()
            case final items when items.isNotEmpty)
          entry.key: items,
    };
    final categoryNames = _categoryNames(list.items);
    final categoryIdByName = _categoryIdByName(list.items);
    final missingWeightItems = list.items
        .where((item) => item.isWeightMissing)
        .toList();
    final onlineWeightCount = list.items
        .where((item) => item.weightSource == WeightSource.online)
        .length;
    final ulModeRow = _UlModeRow(
      enabled: _ulMode,
      minimumWeightGram: WeightCalculator.minimumViableWeightGram(list),
      unit: settings.weightUnit,
      suggestions: suggestions,
      showWeight: list.showWeight,
      onChanged: (value) => setState(() => _ulMode = value),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(list.title),
        actions: [
          IconButton(
            tooltip: '旅程設定',
            onPressed: () => _showTripSettingsEditor(context, list),
            icon: const Icon(Icons.tune),
          ),
          PopupMenuButton<_ListMenuAction>(
            key: const ValueKey('list-more-menu'),
            tooltip: '更多',
            icon: const Icon(Icons.more_horiz),
            onSelected: (action) {
              switch (action) {
                case _ListMenuAction.share:
                  _showShareSheet(context, list, settings.weightUnit);
                case _ListMenuAction.rename:
                  _showRenameDialog(context, list);
                case _ListMenuAction.delete:
                  _requestDeleteList(context, list);
              }
            },
            itemBuilder: (menuContext) => [
              const PopupMenuItem(
                value: _ListMenuAction.share,
                child: _ListMenuRow(icon: Icons.ios_share, label: '分享'),
              ),
              const PopupMenuItem(
                value: _ListMenuAction.rename,
                child: _ListMenuRow(icon: Icons.edit_outlined, label: '重新命名'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _ListMenuAction.delete,
                child: _ListMenuRow(
                  icon: Icons.delete_outline,
                  label: '刪除清單',
                  color: menuContext.palette.weightOver,
                ),
              ),
            ],
          ),
        ],
      ),
      // 「放置位置」標題 + 分頁 + 說明/本體摘要捲到頂端時固定住,下方分類從底下捲過。
      body: CustomScrollView(
        key: const ValueKey('pack-detail-scroll'),
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverList.list(
              children: [
                Text(
                  TripFormatters.summary(list),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                if (list.showWeight)
                  _WeightHeader(
                    summary: summary,
                    unit: settings.weightUnit,
                    heaviestItem: WeightCalculator.heaviestItem(list),
                    onlineWeightCount: onlineWeightCount,
                    footer: ulModeRow,
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: ulModeRow,
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                if (list.showWeight && missingWeightItems.isNotEmpty) ...[
                  _MissingWeightBanner(
                    count: missingWeightItems.length,
                    onFill: () => _fillMissingWeights(
                      context,
                      list.id,
                      missingWeightItems,
                      settings.weightUnit,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: '新增項目',
                        icon: Icons.add,
                        onPressed: () => _showItemEditor(
                          context,
                          list.id,
                          containers: containers,
                          categoryNames: categoryNames,
                          categoryIdByName: categoryIdByName,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: PrimaryButton(
                        label: '分類排序',
                        icon: Icons.swap_vert,
                        onPressed: () => _showCategoryOrderDialog(
                          context,
                          list.id,
                          groupedItems.keys.toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          // 不佔空間,只記下「放置位置」區塊上方內容的總高度。
          SliverLayoutBuilder(
            builder: (context, constraints) {
              _placementPinnedOffset = constraints.precedingScrollExtent;
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
          PinnedHeaderSliver(
            child: ColoredBox(
              key: const ValueKey('placement-pinned-header'),
              // 不透明底色,下方內容捲到底下時不會透出來。
              color: context.palette.background,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: _ContainerSummarySection(
                  items: list.items,
                  containers: containers,
                  unit: settings.weightUnit,
                  showWeight: list.showWeight,
                  selected: placement,
                  onSelected: _selectPlacement,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            sliver: SliverList.list(
              children: [
                ...visibleGroups.entries.map(
                  (entry) => _CategorySection(
                    name: entry.key,
                    items: entry.value,
                    ulMode: _ulMode,
                    unit: settings.weightUnit,
                    showWeight: list.showWeight,
                    references: _references!,
                    onChanged: (item, checked) =>
                        repository.toggleItem(list.id, item.id, checked),
                    onEdit: (item) => _showItemEditor(
                      context,
                      list.id,
                      item: item,
                      containers: containers,
                      categoryNames: categoryNames,
                      categoryIdByName: categoryIdByName,
                    ),
                    onDelete: (item) =>
                        _requestDeleteItem(context, list, item, containers),
                    onAddItem: (categoryName) => _showItemEditor(
                      context,
                      list.id,
                      containers: containers,
                      categoryNames: categoryNames,
                      categoryIdByName: categoryIdByName,
                      initialCategoryName: categoryName,
                      initialContainerId: _isContainerTab(placement)
                          ? placement
                          : null,
                    ),
                    // 篩選某個放置位置時只看到部分項目,不開放拖曳排序。
                    canReorder: placement == null,
                    onReorder: (items) =>
                        repository.reorderItems(list.id, items),
                    onRename: () =>
                        _showCategoryRenameDialog(context, list.id, entry.key),
                  ),
                ),
              ],
            ),
          ),
          // 分頁內容很少時在底部補留白,讓頁面仍捲得到「放置位置」固定在頂端的位置。
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final needed =
                  _placementPinnedOffset +
                  constraints.viewportMainAxisExtent -
                  constraints.precedingScrollExtent;
              return SliverToBoxAdapter(
                child: SizedBox(height: needed > 0 ? needed : 0),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 目前的放置位置分頁;選到的容器被刪除或已無對應項目時回到全部。
  String? _validPlacement(List<PackItem> items, List<PackItem> containers) {
    return switch (_placement) {
      null => null,
      _unassignedTab => items.any(_isUnassigned) ? _unassignedTab : null,
      _wornTab =>
        items.any((item) => item.weightClass == WeightClass.worn)
            ? _wornTab
            : null,
      final id => containers.any((c) => c.id == id) ? id : null,
    };
  }

  Future<void> _fillMissingWeights(
    BuildContext context,
    String listId,
    List<PackItem> missingItems,
    WeightUnit unit,
  ) async {
    final repository = AppScope.of(context);
    final updated = await showWeightFillSheet(
      context,
      items: missingItems,
      references: _references!,
      unit: unit,
    );
    if (updated == null || updated.isEmpty || !context.mounted) return;

    final updatedIds = {for (final item in updated) item.id};
    final originals = missingItems
        .where((item) => updatedIds.contains(item.id))
        .toList();
    repository.upsertItems(listId, updated);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '已帶入 ${updated.length} 項參考重量',
            style: const TextStyle(color: AppColors.ink),
          ),
          backgroundColor: AppColors.primary,
          showCloseIcon: true,
          closeIconColor: AppColors.ink,
          // 有「復原」時 Flutter 預設不會自動消失,這裡明確設成時間到就關。
          persist: false,
          duration: const Duration(milliseconds: 2500),
          action: SnackBarAction(
            label: '復原',
            textColor: AppColors.ink,
            onPressed: () => repository.upsertItems(listId, originals),
          ),
        ),
      );
  }

  void _showShareSheet(BuildContext context, PackList list, WeightUnit unit) {
    final summary = ShareSummaryBuilder.text(list, unit: unit);
    final weightSummary = WeightCalculator.summarize(list);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('分享清單摘要', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _SharePreview(
                      list: list,
                      summary: weightSummary,
                      unit: unit,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await SystemShareService.shareText(
                        text: summary,
                        subject: 'PackPlan ${list.title}',
                      );
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('無法開啟系統分享，請稍後再試')),
                      );
                    }
                  },
                  icon: const Icon(Icons.ios_share),
                  label: const Text('使用系統分享'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: summary));
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('清單摘要已複製')));
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('複製摘要'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRenameDialog(BuildContext context, PackList list) async {
    final controller = TextEditingController(text: list.title);
    final repository = AppScope.of(context);
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: AppDialogTitle.padding,
          title: const AppDialogTitle('重新命名清單'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '清單名稱'),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('儲存'),
            ),
          ],
        );
      },
    );
    await _waitForDialogToClose();
    controller.dispose();
    if (!context.mounted || title == null || title.trim().isEmpty) return;
    repository.renameList(list.id, title);
  }

  Future<void> _requestDeleteList(BuildContext context, PackList list) async {
    final confirmed = await confirmDeleteList(context, list.title);
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _deletedList = list);
    AppScope.of(context).deleteList(list.id);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('清單已刪除')));
  }

  Future<void> _waitForDialogToClose() {
    return Future<void>.delayed(const Duration(milliseconds: 220));
  }

  Future<void> _showTripSettingsEditor(
    BuildContext context,
    PackList list,
  ) async {
    final repository = AppScope.of(context);
    final result = await showDialog<_TripSettingsResult>(
      context: context,
      builder: (_) => _TripSettingsDialog(
        title: list.title,
        days: list.days,
        weatherConditions: list.weatherConditions,
        showWeight: list.showWeight,
      ),
    );
    if (result == null) return;
    if (result.title.trim() != list.title) {
      repository.renameList(list.id, result.title);
    }
    repository.updateTripSettings(
      list.id,
      days: result.days,
      weatherConditions: result.weatherConditions,
      showWeight: result.showWeight,
    );
  }

  Map<String, List<PackItem>> _groupItems(List<PackItem> items) {
    final sorted = [...items]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final grouped = <String, List<PackItem>>{};
    for (final item in sorted) {
      grouped.putIfAbsent(item.categoryName, () => []).add(item);
    }
    return grouped;
  }

  List<PackItem> _containerItems(List<PackItem> items) {
    return items.where((item) => item.isContainer).toList();
  }

  List<String> _categoryNames(List<PackItem> items) {
    final categories = <String>[];
    for (final item in items) {
      final category = item.categoryName.trim();
      if (category.isEmpty || categories.contains(category)) continue;
      categories.add(category);
    }
    return categories;
  }

  Map<String, String> _categoryIdByName(List<PackItem> items) {
    return {for (final item in items) item.categoryName: item.categoryId};
  }

  Future<void> _showCategoryRenameDialog(
    BuildContext context,
    String listId,
    String currentName,
  ) async {
    final repository = AppScope.of(context);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryRenameDialog(currentName: currentName),
    );
    if (!context.mounted || newName == null) return;

    final trimmedName = newName.trim();
    if (trimmedName == currentName) return;
    final renamed = repository.renameCategory(listId, currentName, trimmedName);
    if (renamed) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('分類名稱不可空白或與現有分類重複')));
  }

  Future<void> _showCategoryOrderDialog(
    BuildContext context,
    String listId,
    List<String> categoryNames,
  ) async {
    final repository = AppScope.of(context);
    final orderedNames = await showDialog<List<String>>(
      context: context,
      builder: (_) => _CategoryOrderDialog(categoryNames: categoryNames),
    );
    if (orderedNames == null) return;
    repository.reorderCategories(listId, orderedNames);
  }

  Future<void> _showItemEditor(
    BuildContext context,
    String listId, {
    PackItem? item,
    required List<PackItem> containers,
    required List<String> categoryNames,
    required Map<String, String> categoryIdByName,
    String? initialCategoryName,
    String? initialContainerId,
  }) async {
    final repository = AppScope.of(context);
    final result = await showDialog<_ItemEditorResult>(
      context: context,
      builder: (_) => _ItemEditorDialog(
        item: item,
        containers: containers,
        categoryNames: categoryNames,
        categoryIdByName: categoryIdByName,
        initialCategoryName: initialCategoryName,
        initialContainerId: initialContainerId,
      ),
    );
    if (result == null) return;
    if (result.deleteItemId != null) {
      final list = repository.findById(listId);
      if (list == null) return;
      final item = list.items
          .where((current) => current.id == result.deleteItemId)
          .firstOrNull;
      if (item == null) return;
      await _requestDeleteItem(
        context,
        list,
        item,
        _containerItems(list.items),
      );
      return;
    }
    if (result.item != null) {
      repository.upsertItem(listId, result.item!);
    }
  }

  Future<void> _requestDeleteItem(
    BuildContext context,
    PackList list,
    PackItem item,
    List<PackItem> containers,
  ) async {
    if (item.isContainer && containers.length <= 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('至少需要保留一個背包或行李')));
      return;
    }

    final destination = _primaryContainerAfterDelete(containers, item.id);
    final contentCount = list.items
        .where((current) => current.containerItemId == item.id)
        .length;
    final confirmed = await _confirmDeleteItem(
      context,
      item,
      contentCount: contentCount,
      destinationName: destination?.name,
    );
    if (!confirmed || !context.mounted) return;
    AppScope.of(context).deleteItem(list.id, item.id);
  }

  PackItem? _primaryContainerAfterDelete(
    List<PackItem> containers,
    String deletedItemId,
  ) {
    final remaining = containers
        .where((container) => container.id != deletedItemId)
        .toList();
    if (remaining.isEmpty) return null;
    return remaining
            .where(
              (container) =>
                  container.categoryId == 'backpack' ||
                  container.name.contains('主背包'),
            )
            .firstOrNull ??
        remaining.first;
  }

  Future<bool> _confirmDeleteItem(
    BuildContext context,
    PackItem item, {
    required int contentCount,
    required String? destinationName,
  }) async {
    final hasContents = item.isContainer && contentCount > 0;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: AppDialogTitle.padding,
          title: AppDialogTitle(hasContents ? '行李內仍有項目' : '刪除項目？'),
          content: Text(
            hasContents
                ? '「${item.name}」內有 $contentCount 個項目，確定要刪除嗎？'
                      '刪除後，這些項目會移到「$destinationName」。'
                : '要刪除「${item.name}」嗎？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('確定刪除'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _SharePreview extends StatelessWidget {
  const _SharePreview({
    required this.list,
    required this.summary,
    required this.unit,
  });

  final PackList list;
  final WeightSummary summary;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PackPlan ${list.title}', style: t.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(TripFormatters.summary(list), style: t.bodySmall),
        const SizedBox(height: AppSpacing.md),
        if (list.showWeight) ...[
          Text(
            '背包總重 ${WeightFormatters.gram(summary.totalGram, unit: unit)}',
            style: t.bodyMedium,
          ),
          if (summary.wornGram > 0)
            Text(
              '穿戴 ${WeightFormatters.gram(summary.wornGram, unit: unit)}'
              '（不計背重）',
              style: t.bodyMedium,
            ),
          Text(
            '上限 ${WeightFormatters.gram(summary.limitGram, unit: unit)}',
            style: t.bodyMedium,
          ),
        ],
        Text(
          '進度 ${summary.checkedCount}/${summary.itemCount} 已打包',
          style: t.bodyMedium,
        ),
        if (list.showWeight && summary.isOverLimit) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '超重 ${WeightFormatters.gram(summary.overByGram, unit: unit)}',
            style: t.bodyMedium?.copyWith(
              color: AppColors.weightOver,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _WeightHeader extends StatelessWidget {
  const _WeightHeader({
    required this.summary,
    required this.unit,
    required this.heaviestItem,
    required this.onlineWeightCount,
    required this.footer,
  });

  final WeightSummary summary;
  final WeightUnit unit;
  final PackItem? heaviestItem;
  final int onlineWeightCount;

  /// 卡片最下方分隔線以下的內容(超輕量化開關)。
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('已打包重量', style: t.bodySmall),
                Text(
                  '${summary.checkedCount}/${summary.itemCount} 已打包',
                  style: t.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // 總重固定一行(數字變長或字級放大時縮小,不換行),上限靠右。
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FittedBox(
                    key: const ValueKey('weight-header-total'),
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${WeightFormatters.gram(summary.packedGram, unit: unit)} / '
                      '${WeightFormatters.gram(summary.totalGram, unit: unit)} 總重',
                      style: t.headlineMedium,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  // 對齊大字的底線(headlineMedium 行高下方留白)。
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '上限 ${WeightFormatters.gram(summary.limitGram, unit: unit)}',
                    key: const ValueKey('weight-header-limit'),
                    style: t.bodySmall,
                  ),
                ),
              ],
            ),
            if (summary.wornGram > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '穿戴 ${WeightFormatters.gram(summary.wornGram, unit: unit)}'
                '（不計背重）',
                style: t.bodySmall?.copyWith(color: AppColors.primary),
              ),
            ],
            if (heaviestItem case final item?
                when item.totalWeightGram > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '最重項目 ${item.name} · '
                '${WeightFormatters.gram(item.totalWeightGram, unit: unit)}',
                style: t.bodySmall,
              ),
            ],
            if (onlineWeightCount > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(
                    Icons.cloud_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text('含 $onlineWeightCount 項線上參考重量', style: t.bodySmall),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            WeightBar(
              currentGram: summary.packedGram,
              limitGram: summary.limitGram,
              unit: unit,
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: context.palette.border),
            const SizedBox(height: AppSpacing.sm),
            footer,
          ],
        ),
      ),
    );
  }
}

class _MissingWeightBanner extends StatelessWidget {
  const _MissingWeightBanner({required this.count, required this.onFill});

  final int count;
  final VoidCallback onFill;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(child: Text('$count 項尚未填重量', style: t.bodyMedium)),
          TextButton.icon(
            key: const ValueKey('fill-missing-weights'),
            onPressed: onFill,
            icon: const Icon(Icons.cloud_download_outlined, size: 18),
            label: const Text('帶入參考重量'),
          ),
        ],
      ),
    );
  }
}

/// 超輕量化開關:放在重量卡最下方一行,說明收進 (i)。
/// 開啟後多一行「最低可行 · 可刪減 N 項 ›」,點開底部面板看建議。
class _UlModeRow extends StatelessWidget {
  const _UlModeRow({
    required this.enabled,
    required this.minimumWeightGram,
    required this.unit,
    required this.suggestions,
    required this.showWeight,
    required this.onChanged,
  });

  final bool enabled;
  final int minimumWeightGram;
  final WeightUnit unit;
  final List<WeightSuggestion> suggestions;
  final bool showWeight;
  final ValueChanged<bool> onChanged;

  String _gram(int gram) => WeightFormatters.gram(gram, unit: unit);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final summary = [
      if (showWeight) '最低可行 ${_gram(minimumWeightGram)}',
      suggestions.isEmpty ? '沒有可刪減項目' : '可刪減 ${suggestions.length} 項',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text('超輕量化', style: t.bodyMedium),
            Tooltip(
              message: '開啟後會標記可刪減項目並估算最低可行重量。',
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 4),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: context.palette.textTertiary,
                ),
              ),
            ),
            const Spacer(),
            Switch(value: enabled, onChanged: onChanged),
          ],
        ),
        if (enabled)
          InkWell(
            key: const ValueKey('ul-mode-summary'),
            onTap: suggestions.isEmpty ? null : () => _showSuggestions(context),
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      summary,
                      style: t.bodySmall?.copyWith(color: AppColors.primary),
                    ),
                  ),
                  if (suggestions.isNotEmpty)
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showSuggestions(BuildContext context) {
    final t = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('可刪減項目', style: t.titleLarge),
            if (showWeight) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('最低可行重量 ${_gram(minimumWeightGram)}', style: t.bodySmall),
            ],
            const SizedBox(height: AppSpacing.md),
            for (final suggestion in suggestions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(suggestion.itemName),
                subtitle: Text(suggestion.reason),
                trailing: showWeight
                    ? Text(_gram(suggestion.weightGram), style: t.bodyMedium)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

const _unassignedTab = '__unassigned__';
const _wornTab = '__worn__';

bool _isContainerTab(String? placement) =>
    placement != null && placement != _unassignedTab && placement != _wornTab;

bool _isUnassigned(PackItem item) =>
    !item.isContainer &&
    item.weightClass != WeightClass.worn &&
    item.containerItemId == null;

/// 項目是否屬於目前的放置位置分頁(容器分頁包含容器本身)。
bool _inPlacement(PackItem item, String? placement) => switch (placement) {
  null => true,
  _unassignedTab => _isUnassigned(item),
  _wornTab => item.weightClass == WeightClass.worn,
  final id => item.id == id || item.containerItemId == id,
};

/// 放置位置:以分頁切換「全部 / 各容器 / 未放入 / 身上穿戴」,
/// 下方清單只列出該位置的項目,項目本身就不用再標示「放在哪」。
class _ContainerSummarySection extends StatelessWidget {
  const _ContainerSummarySection({
    required this.items,
    required this.containers,
    required this.unit,
    required this.showWeight,
    required this.selected,
    required this.onSelected,
  });

  final List<PackItem> items;
  final List<PackItem> containers;
  final WeightUnit unit;
  final bool showWeight;
  final String? selected;
  final ValueChanged<String?> onSelected;

  String _gram(int gram) => WeightFormatters.gram(gram, unit: unit);

  static int _totalWeight(Iterable<PackItem> items) =>
      items.fold(0, (total, item) => total + item.totalWeightGram);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final unassigned = items.where(_isUnassigned).toList();
    final worn = items
        .where((item) => item.weightClass == WeightClass.worn)
        .toList();
    List<PackItem> contentsOf(PackItem container) =>
        items.where((item) => item.containerItemId == container.id).toList();

    final tabs = <(String?, String, int)>[
      (null, '全部', items.length),
      for (final container in containers)
        (container.id, container.name, contentsOf(container).length),
      if (unassigned.isNotEmpty) (_unassignedTab, '未放入', unassigned.length),
      if (worn.isNotEmpty) (_wornTab, '身上穿戴', worn.length),
    ];

    final String detail;
    Color? detailColor;
    switch (selected) {
      case null:
        detail = containers.isEmpty ? '至少需要新增一個背包或行李容器。' : '點分頁只看放在該處的項目。';
      case _unassignedTab:
        detail = showWeight
            ? '未放入 ${unassigned.length} 項 · ${_gram(_totalWeight(unassigned))}'
            : '未放入 ${unassigned.length} 項';
        detailColor = AppColors.weightNear;
      case _wornTab:
        detail = showWeight
            ? '身上穿戴 ${worn.length} 項 · ${_gram(_totalWeight(worn))}（不計背重）'
            : '身上穿戴 ${worn.length} 項（不計背重）';
        detailColor = AppColors.primary;
      case final id:
        final container = containers.firstWhere((c) => c.id == id);
        final contents = contentsOf(container);
        final contentWeight = _totalWeight(contents);
        detail = showWeight
            ? '本體 ${_gram(container.totalWeightGram)} · '
                  '內容物 ${_gram(contentWeight)} · '
                  '合計 ${_gram(container.totalWeightGram + contentWeight)} · '
                  '${contents.length} 項'
            : '${contents.length} 項已放入';
    }

    // 不是卡片:標題 + 底線分頁列(Figma「放置位置」)。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('放置位置', style: t.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.palette.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, (value, label, count)) in tabs.indexed)
                    Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 0 : AppSpacing.xl,
                      ),
                      child: _PlacementTab(
                        key: ValueKey('placement-tab-${value ?? 'all'}'),
                        label: label,
                        count: count,
                        selected: value == selected,
                        onTap: () => onSelected(value),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          detail,
          key: const ValueKey('placement-detail'),
          style: t.bodySmall?.copyWith(color: detailColor),
        ),
      ],
    );
  }
}

/// 底線分頁:選中為主文字色 + 橘色底線,未選為次要文字色。
class _PlacementTab extends StatelessWidget {
  const _PlacementTab({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(
                      color: selected
                          ? AppColors.primary
                          : palette.textSecondary,
                      fontWeight: selected ? FontWeight.w500 : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '($count)',
                  style: t.bodySmall?.copyWith(color: palette.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              key: selected ? const ValueKey('placement-tab-indicator') : null,
              height: 2,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.name,
    required this.items,
    required this.ulMode,
    required this.unit,
    required this.showWeight,
    required this.references,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onAddItem,
    required this.canReorder,
    required this.onReorder,
    required this.onRename,
  });

  final String name;
  final List<PackItem> items;
  final bool ulMode;
  final WeightUnit unit;
  final bool showWeight;
  final WeightReferenceRepository references;
  final void Function(PackItem item, bool checked) onChanged;
  final ValueChanged<PackItem> onEdit;
  final ValueChanged<PackItem> onDelete;
  final ValueChanged<String> onAddItem;
  final bool canReorder;
  final ValueChanged<List<PackItem>> onReorder;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final carriedGram = items
        .where((item) => item.weightClass != WeightClass.worn)
        .fold(0, (total, item) => total + item.totalWeightGram);
    final wornGram = items
        .where((item) => item.weightClass == WeightClass.worn)
        .fold(0, (total, item) => total + item.totalWeightGram);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: _ExpandedStateBuilder(
            storageId: 'category-expanded-$name',
            builder: (context, expanded, onExpansionChanged) => ExpansionTile(
              initiallyExpanded: expanded,
              onExpansionChanged: onExpansionChanged,
              title: Text(name, style: Theme.of(context).textTheme.titleMedium),
              trailing: SizedBox(
                height: 48,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: '重新命名$name分類',
                      icon: Icon(
                        Icons.edit_outlined,
                        color: context.palette.textSecondary,
                      ),
                      onPressed: onRename,
                    ),
                    IconButton(
                      tooltip: '新增$name項目',
                      icon: Icon(
                        Icons.add,
                        color: context.palette.textSecondary,
                      ),
                      onPressed: () => onAddItem(name),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // 展開時顯示 v、收合時顯示 ^。
                    Icon(
                      expanded ? Icons.expand_more : Icons.expand_less,
                      key: ValueKey('category-toggle-$name'),
                      color: context.palette.textSecondary,
                    ),
                  ],
                ),
              ),
              subtitle: showWeight
                  ? Text(
                      wornGram > 0
                          ? '背重 ${WeightFormatters.gram(carriedGram, unit: unit)} · '
                                '穿戴 ${WeightFormatters.gram(wornGram, unit: unit)}'
                          : WeightFormatters.gram(carriedGram, unit: unit),
                    )
                  : null,
              childrenPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              children: [
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: items.length,
                  onReorder: (oldIndex, newIndex) {
                    final reordered = [...items];
                    if (newIndex > oldIndex) newIndex -= 1;
                    final moved = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, moved);
                    onReorder(reordered);
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Row(
                      key: ValueKey(item.id),
                      children: [
                        Expanded(
                          child: ChecklistTile(
                            key: ValueKey('checklist-tile-${item.id}'),
                            label: item.quantity > 1
                                ? '${item.name} x${item.quantity}'
                                : item.name,
                            weightGram: item.totalWeightGram,
                            weightLabel: WeightFormatters.gram(
                              item.totalWeightGram,
                              unit: unit,
                            ),
                            showWeight: showWeight,
                            weightMissing: item.isWeightMissing,
                            weightTooltip:
                                item.weightSource == WeightSource.online
                                ? WeightReferenceLabels.tooltip(
                                    item.catalogKey == null
                                        ? null
                                        : references.lookup(item.catalogKey!),
                                    unit,
                                  )
                                : null,
                            checked: item.checked,
                            dimmed:
                                ulMode &&
                                item.weightClass == WeightClass.packed &&
                                item.necessity != ItemNecessity.required,
                            badgeLabel:
                                _weightClassBadge(item.weightClass) ??
                                (ulMode
                                    ? _reductionBadge(item.necessity)
                                    : null),
                            badgeFilled:
                                item.weightClass == WeightClass.worn ||
                                (item.weightClass == WeightClass.packed &&
                                    item.necessity == ItemNecessity.luxury),
                            onChanged: (checked) => onChanged(item, checked),
                            onEdit: () => onEdit(item),
                            onLongPress: () => _showItemActions(context, item),
                          ),
                        ),
                        if (canReorder)
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showItemActions(BuildContext context, PackItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('編輯項目'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await Future<void>.delayed(
                      const Duration(milliseconds: 180),
                    );
                    if (!context.mounted) return;
                    onEdit(item);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.weightOver,
                  ),
                  title: const Text('刪除項目'),
                  textColor: AppColors.weightOver,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await Future<void>.delayed(
                      const Duration(milliseconds: 180),
                    );
                    if (!context.mounted) return;
                    onDelete(item);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ItemEditorResult {
  const _ItemEditorResult.save(this.item) : deleteItemId = null;

  const _ItemEditorResult.delete(this.deleteItemId) : item = null;

  final PackItem? item;
  final String? deleteItemId;
}

class _TripSettingsResult {
  const _TripSettingsResult({
    required this.title,
    required this.days,
    required this.weatherConditions,
    required this.showWeight,
  });

  /// 空白代表不改名(renameList 會忽略空字串)。
  final String title;
  final int days;
  final Set<WeatherCondition> weatherConditions;
  final bool showWeight;
}

class _TripSettingsDialog extends StatefulWidget {
  const _TripSettingsDialog({
    required this.title,
    required this.days,
    required this.weatherConditions,
    required this.showWeight,
  });

  final String title;
  final int days;
  final Set<WeatherCondition> weatherConditions;
  final bool showWeight;

  @override
  State<_TripSettingsDialog> createState() => _TripSettingsDialogState();
}

class _TripSettingsDialogState extends State<_TripSettingsDialog> {
  late final _titleController = TextEditingController(text: widget.title);
  late int _days = widget.days;
  late Set<WeatherCondition> _weatherConditions = {...widget.weatherConditions};
  late bool _showWeight = widget.showWeight;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AlertDialog(
      titlePadding: AppDialogTitle.padding,
      title: const AppDialogTitle('旅程設定'),
      // 名稱欄位叫出鍵盤時內容可捲動,避免溢出。
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('trip-settings-title'),
              controller: _titleController,
              decoration: const InputDecoration(labelText: '清單名稱'),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('天數', style: t.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                IconButton(
                  tooltip: '減少天數',
                  onPressed: _days <= 1
                      ? null
                      : () => setState(() => _days -= 1),
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Text(
                    '$_days 天',
                    textAlign: TextAlign.center,
                    style: t.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '增加天數',
                  onPressed: _days >= 14
                      ? null
                      : () => setState(() => _days += 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('天氣', style: t.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            WeatherChoiceChips(
              selected: _weatherConditions,
              onChanged: (next) => setState(() => _weatherConditions = next),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('顯示重量'),
              value: _showWeight,
              onChanged: (value) => setState(() => _showWeight = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _TripSettingsResult(
              title: _titleController.text,
              days: _days,
              weatherConditions: _weatherConditions,
              showWeight: _showWeight,
            ),
          ),
          child: const Text('儲存'),
        ),
      ],
    );
  }
}

class _CategoryRenameDialog extends StatefulWidget {
  const _CategoryRenameDialog({required this.currentName});

  final String currentName;

  @override
  State<_CategoryRenameDialog> createState() => _CategoryRenameDialogState();
}

class _CategoryRenameDialogState extends State<_CategoryRenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: AppDialogTitle.padding,
      title: const AppDialogTitle('重新命名分類'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: '分類名稱'),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('儲存'),
        ),
      ],
    );
  }
}

class _CategoryOrderDialog extends StatefulWidget {
  const _CategoryOrderDialog({required this.categoryNames});

  final List<String> categoryNames;

  @override
  State<_CategoryOrderDialog> createState() => _CategoryOrderDialogState();
}

class _CategoryOrderDialogState extends State<_CategoryOrderDialog> {
  late final List<String> _categoryNames = [...widget.categoryNames];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: AppDialogTitle.padding,
      title: const AppDialogTitle('分類排序'),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          itemCount: _categoryNames.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final moved = _categoryNames.removeAt(oldIndex);
              _categoryNames.insert(newIndex, moved);
            });
          },
          itemBuilder: (context, index) {
            final name = _categoryNames[index];
            return ListTile(
              key: ValueKey('category-order-$name'),
              title: Text(name),
              trailing: ReorderableDragStartListener(
                key: ValueKey('category-order-handle-$name'),
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_categoryNames),
          child: const Text('儲存排序'),
        ),
      ],
    );
  }
}

class _ItemEditorDialog extends StatefulWidget {
  const _ItemEditorDialog({
    this.item,
    required this.containers,
    required this.categoryNames,
    required this.categoryIdByName,
    this.initialCategoryName,
    this.initialContainerId,
  });

  final PackItem? item;
  final List<PackItem> containers;
  final List<String> categoryNames;
  final Map<String, String> categoryIdByName;
  final String? initialCategoryName;

  /// 新增項目的預設放置位置(從某個放置位置分頁新增時帶入)。
  final String? initialContainerId;

  @override
  State<_ItemEditorDialog> createState() => _ItemEditorDialogState();
}

class _ItemEditorDialogState extends State<_ItemEditorDialog> {
  static const _containerCategoryIds = {'backpack', 'luggage'};
  static const _addCategoryValue = '__add_category__';

  late final TextEditingController _nameController = TextEditingController(
    text: widget.item?.name ?? '',
  );
  late final TextEditingController _categoryController = TextEditingController(
    text: widget.item?.categoryName ?? widget.initialCategoryName ?? '自訂',
  );
  late final TextEditingController _newCategoryController =
      TextEditingController();
  late final TextEditingController _weightController = TextEditingController(
    text: (widget.item?.weightGram ?? 100).toString(),
  );
  late final TextEditingController _quantityController = TextEditingController(
    text: (widget.item?.quantity ?? 1).toString(),
  );
  late ItemNecessity _necessity =
      widget.item?.necessity ?? ItemNecessity.optional;
  late WeightClass _weightClass =
      widget.item?.weightClass ?? WeightClass.packed;
  late bool _isContainer = widget.item?.isContainer ?? false;
  late String? _containerItemId =
      widget.item?.containerItemId ??
      widget.initialContainerId ??
      _defaultContainerItemId;
  late String _lastCategoryName;
  bool _isAddingCategory = false;

  /// 在這次編輯中從線上參考重量帶入的資料;重量沒再被改動就記為線上來源。
  GearWeight? _appliedReference;
  bool _lookingUpReference = false;

  /// 查不到參考值時顯示在按鈕下方(SnackBar 會被對話框遮住)。
  String? _referenceNotice;

  String? get _defaultContainerItemId {
    for (final container in widget.containers) {
      if (container.id != widget.item?.id) return container.id;
    }
    return null;
  }

  List<PackItem> get _availableContainers {
    return widget.containers
        .where((container) => container.id != widget.item?.id)
        .toList();
  }

  bool get _categoryCanBeContainer {
    return _isContainerCategory(_categoryController.text);
  }

  List<String> get _availableCategoryNames {
    final categories = <String>[];
    for (final category in widget.categoryNames) {
      final normalized = _normalizedCategory(category);
      if (normalized.isEmpty || categories.contains(normalized)) continue;
      categories.add(normalized);
    }
    final currentCategory = _normalizedCategory(_categoryController.text);
    if (currentCategory.isNotEmpty && !categories.contains(currentCategory)) {
      categories.insert(0, currentCategory);
    }
    return categories;
  }

  bool _referencesRequested = false;

  @override
  void initState() {
    super.initState();
    _lastCategoryName = _normalizedCategory(_categoryController.text);
    _categoryController.addListener(_handleCategoryChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 「帶入參考值」只在比對得到時顯示,所以開啟編輯就先備好線上資料。
    if (_referencesRequested) return;
    _referencesRequested = true;
    final references = WeightReferenceScope.of(context);
    references.load().then((_) {
      if (!references.hasData) references.syncQuietly();
    });
  }

  @override
  void dispose() {
    _categoryController.removeListener(_handleCategoryChanged);
    _nameController.dispose();
    _categoryController.dispose();
    _newCategoryController.dispose();
    _weightController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _normalizedCategory(_categoryController.text);

    return AlertDialog(
      titlePadding: AppDialogTitle.padding,
      title: AppDialogTitle(widget.item == null ? '新增項目' : '編輯項目'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('名稱', style: _editorFieldLabelStyle(context)),
            // 名稱過長時最多換到 2 行,再長就在框內捲動(編輯中的文字無法用「…」截斷)。
            TextField(
              key: const ValueKey('item-editor-name'),
              controller: _nameController,
              decoration: const InputDecoration(),
              minLines: 1,
              maxLines: 2,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              key: const ValueKey('item-editor-category-dropdown'),
              value: selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '分類'),
              items: [
                ..._availableCategoryNames.map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
                ),
                const DropdownMenuItem(
                  value: _addCategoryValue,
                  child: Text('＋ 新增分類'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                if (value == _addCategoryValue) {
                  setState(() => _isAddingCategory = true);
                  return;
                }
                _chooseCategory(value);
              },
            ),
            if (_isAddingCategory) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _newCategoryController,
                decoration: const InputDecoration(labelText: '新增分類名稱'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _applyNewCategory(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isAddingCategory = false;
                          _newCategoryController.clear();
                        });
                      },
                      child: const Text('取消新增'),
                    ),
                    FilledButton(
                      onPressed: _applyNewCategory,
                      child: const Text('加入分類'),
                    ),
                  ],
                ),
              ),
            ],
            if (_categoryCanBeContainer) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '此分類可作為放置位置，其他項目可以放入這裡。',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: '單件重量 g'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: '數量'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            // 「帶入參考值」右邊接著顯示目前的線上參考值(或查詢結果提示)。
            // 項目比對不到任何線上參考值時整列不顯示;名稱改了或資料同步完會重算。
            ListenableBuilder(
              listenable: Listenable.merge([
                WeightReferenceScope.of(context),
                _nameController,
              ]),
              builder: (context, _) => !_hasReferenceMatch
                  ? const SizedBox.shrink()
                  : Row(
                      children: [
                        TextButton.icon(
                          key: const ValueKey('item-editor-weight-reference'),
                          onPressed: _lookingUpReference
                              ? null
                              : _pickReference,
                          icon: _lookingUpReference
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.cloud_download_outlined,
                                  size: 18,
                                ),
                          label: const Text('帶入參考值'),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (_referenceHint(context) case final hint?) ...[
                          const Icon(
                            Icons.cloud_outlined,
                            key: ValueKey('item-editor-reference-icon'),
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              hint,
                              key: const ValueKey('item-editor-reference-hint'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ] else if (_referenceNotice case final notice?)
                          Expanded(
                            child: Text(
                              notice,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: context.palette.textSecondary,
                                  ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<WeightClass>(
                    value: _weightClass,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '重量類型'),
                    items: WeightClass.values
                        .map(
                          (weightClass) => DropdownMenuItem(
                            value: weightClass,
                            enabled:
                                weightClass == WeightClass.packed ||
                                !_mustStayContainer,
                            child: Text(
                              weightClass != WeightClass.packed &&
                                      _mustStayContainer
                                  ? '${_weightClassLabel(weightClass)}（需保留容器）'
                                  : _weightClassLabel(weightClass),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _weightClass = value;
                        if (value != WeightClass.packed) {
                          _isContainer = false;
                          if (value == WeightClass.worn) {
                            _containerItemId = null;
                          }
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<ItemNecessity>(
                    value: _necessity,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '必要性'),
                    items: ItemNecessity.values
                        .map(
                          (necessity) => DropdownMenuItem(
                            value: necessity,
                            child: Text(
                              _necessityLabel(necessity),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _necessity = value);
                    },
                  ),
                ),
              ],
            ),
            if (_weightClass == WeightClass.packed) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _placementField(context)),
                  const SizedBox(width: AppSpacing.md),
                  _containerToggle(context),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.item != null &&
            !(widget.item!.isContainer && widget.containers.length <= 1))
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(_ItemEditorResult.delete(widget.item!.id)),
            child: const Text('刪除'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            backgroundColor: context.palette.surfaceElevated,
            foregroundColor: context.palette.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.dialogButton),
            ),
          ),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.dialogButton),
            ),
          ),
          child: const Text('儲存'),
        ),
      ],
    );
  }

  /// 清單中唯一的容器:重量類型不能改成穿戴。
  bool get _mustStayContainer =>
      widget.item?.isContainer == true && widget.containers.length <= 1;

  /// 放置位置;本身是容器時不能再放進別的容器,只顯示說明。
  Widget _placementField(BuildContext context) {
    if (_isContainer || _availableContainers.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(labelText: '放置位置', enabled: false),
        child: Text(
          _isContainer ? '本身為容器' : '尚無容器',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.palette.textTertiary),
        ),
      );
    }
    return DropdownButtonFormField<String?>(
      key: const ValueKey('item-editor-placement'),
      value:
          _availableContainers.any(
            (container) => container.id == _containerItemId,
          )
          ? _containerItemId
          : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: '放置位置'),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('未指定')),
        ..._availableContainers.map(
          (container) => DropdownMenuItem<String?>(
            value: container.id,
            child: Text(container.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) => setState(() => _containerItemId = value),
    );
  }

  /// 「設為容器」開關;完整說明點 (i) 顯示。
  Widget _containerToggle(BuildContext context) {
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: context.palette.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('設為容器', style: labelStyle),
            // 點一下就顯示說明;圖示只有 18,外面留 36×36 的點擊範圍。
            Tooltip(
              key: const ValueKey('item-editor-container-info'),
              message: '設為背包/行李容器：容器本身會計入重量，其他項目可放入此處',
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 4),
              child: SizedBox.square(
                dimension: 36,
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: context.palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
        Switch(
          key: const ValueKey('item-editor-container-switch'),
          value: _isContainer,
          onChanged: (value) {
            setState(() {
              _isContainer = value;
              if (value) _containerItemId = null;
            });
          },
        ),
      ],
    );
  }

  /// 這個項目(依範本 key 或目前名稱)在線上參考重量裡找得到通用值或型號。
  /// 已帶入過參考值時一律顯示,才能看到「線上參考」提示並重新選。
  bool get _hasReferenceMatch {
    if (_currentReference != null) return true;
    final references = WeightReferenceScope.of(context);
    if (!references.isLoaded || !references.hasData) return false;
    final catalogKey = _appliedReference?.key ?? widget.item?.catalogKey;
    final match = references.match(
      catalogKey: catalogKey,
      name: _nameController.text.trim(),
    );
    final parentKey = match?.parentKey ?? match?.key ?? catalogKey;
    if (parentKey == null) return false;
    return references.lookup(parentKey) != null ||
        references.variantsOf(parentKey).isNotEmpty;
  }

  GearWeight? get _currentReference {
    if (_appliedReference != null) return _appliedReference;
    final item = widget.item;
    if (item?.weightSource != WeightSource.online || item?.catalogKey == null) {
      return null;
    }
    return WeightReferenceScope.of(context).lookup(item!.catalogKey!);
  }

  String? _referenceHint(BuildContext context) {
    final reference = _currentReference;
    if (reference == null) return null;
    final unit = AppScope.of(context).settings.weightUnit;
    final rangeText = WeightReferenceLabels.range(reference, unit);
    final range = rangeText.isNotEmpty ? '（範圍 $rangeText）' : '';
    return '線上參考 '
        '${WeightFormatters.gram(reference.weightGram, unit: unit)}$range';
  }

  Future<void> _pickReference() async {
    final references = WeightReferenceScope.of(context);
    final unit = AppScope.of(context).settings.weightUnit;
    final name = _nameController.text.trim();

    setState(() {
      _lookingUpReference = true;
      _referenceNotice = null;
    });
    await references.load();
    if (!references.hasData) await references.syncQuietly();
    if (!mounted) return;
    setState(() => _lookingUpReference = false);

    // 比對到型號時,改列出它所屬的通用項目與同系列型號。
    // 通用項目沒有線上資料(沒填重量不會上傳)時,仍用範本 key 找掛在底下的型號。
    final catalogKey = _appliedReference?.key ?? widget.item?.catalogKey;
    final match = references.match(catalogKey: catalogKey, name: name);
    final parentKey = match?.parentKey ?? match?.key ?? catalogKey;
    final generic = parentKey == null ? null : references.lookup(parentKey);
    final variants = parentKey == null
        ? const <GearWeight>[]
        : references.variantsOf(parentKey);
    if (!references.hasData) {
      setState(() => _referenceNotice = '目前沒有可用的參考重量，請確認網路後再試');
      return;
    }
    // 比對不到時直接開搜尋,先用項目名稱當關鍵字。
    final notFound = generic == null && variants.isEmpty;

    // 目前重量欄仍是某筆參考值時,在選單中標示為已選。
    final current = _currentReference;
    final picked = await showWeightReferencePicker(
      context,
      generic: generic,
      variants: variants,
      references: references,
      unit: unit,
      selectedKey:
          current != null &&
              _weightController.text.trim() == '${current.weightGram}'
          ? current.key
          : null,
      initialQuery: notFound ? name : null,
      categoryId: _categoryController.text.trim().isEmpty
          ? null
          : _resolvedCategoryId(_categoryController.text),
      categoryName: _categoryController.text.trim(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _appliedReference = picked;
      _weightController.text = '${picked.weightGram}';
      if (picked.isVariant) _nameController.text = picked.nameZh;
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final weight = int.tryParse(_weightController.text.trim()) ?? 0;
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (name.isEmpty || category.isEmpty || weight < 0 || quantity < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請填寫名稱與分類；重量、數量不可小於 0')));
      return;
    }

    final existing = widget.item;
    final reference = _appliedReference;
    // 剛帶入且沒再改 → 線上;重量沒動 → 保留原來源(如尚未填);其餘算使用者自填。
    final weightSource = reference != null && reference.weightGram == weight
        ? WeightSource.online
        : existing != null && existing.weightGram == weight
        ? existing.weightSource
        : WeightSource.manual;

    final nowId = DateTime.now().microsecondsSinceEpoch;
    final item =
        (widget.item ??
                PackItem(
                  id: 'item-$nowId',
                  categoryId: _resolvedCategoryId(category),
                  categoryName: category,
                  name: name,
                  weightGram: weight,
                  quantity: quantity,
                  checked: false,
                  necessity: _necessity,
                  sortOrder: 0,
                  weightClass: _weightClass,
                  isContainer: _isContainer,
                  containerItemId:
                      _isContainer || _weightClass == WeightClass.worn
                      ? null
                      : _containerItemId,
                ))
            .copyWith(
              categoryId: _resolvedCategoryId(category),
              categoryName: category,
              name: name,
              weightGram: weight,
              quantity: quantity,
              necessity: _necessity,
              weightClass: _weightClass,
              isContainer: _isContainer,
              containerItemId: _isContainer || _weightClass == WeightClass.worn
                  ? null
                  : _containerItemId,
              weightSource: weightSource,
            );
    final saved = reference == null
        ? item
        : item.copyWith(catalogKey: reference.key);

    Navigator.of(context).pop(_ItemEditorResult.save(saved));
  }

  void _handleCategoryChanged() {
    final category = _normalizedCategory(_categoryController.text);
    if (category == _lastCategoryName) return;
    setState(() {
      _lastCategoryName = category;
      if (_isContainerCategory(category) && !_isContainer) {
        _isContainer = true;
        _containerItemId = null;
      }
    });
  }

  bool _isContainerCategory(String category) {
    return _containerCategoryIds.contains(_resolvedCategoryId(category));
  }

  String _resolvedCategoryId(String category) {
    final normalized = _normalizedCategory(category);
    return widget.categoryIdByName[normalized] ?? _categoryId(normalized);
  }

  static String _normalizedCategory(String category) {
    return category.trim();
  }

  TextStyle? _editorFieldLabelStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: context.palette.textTertiary);
  }

  void _chooseCategory(String category) {
    if (_isAddingCategory) {
      setState(() {
        _isAddingCategory = false;
        _newCategoryController.clear();
      });
    }
    _categoryController
      ..text = category
      ..selection = TextSelection.collapsed(offset: category.length);
  }

  void _applyNewCategory() {
    final category = _normalizedCategory(_newCategoryController.text);
    if (category.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請輸入分類名稱')));
      return;
    }
    _chooseCategory(category);
  }
}

String _categoryId(String category) {
  return category.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
}

String _necessityLabel(ItemNecessity necessity) {
  return switch (necessity) {
    ItemNecessity.required => '必要',
    ItemNecessity.optional => '可選',
    ItemNecessity.luxury => '享受型',
  };
}

String _weightClassLabel(WeightClass weightClass) {
  return switch (weightClass) {
    WeightClass.packed => '計入背重',
    WeightClass.worn => '不計入背重',
  };
}

String? _weightClassBadge(WeightClass weightClass) {
  return switch (weightClass) {
    WeightClass.packed => null,
    WeightClass.worn => '穿戴',
  };
}

String? _reductionBadge(ItemNecessity necessity) {
  return switch (necessity) {
    ItemNecessity.required => null,
    ItemNecessity.optional => '可刪減',
    ItemNecessity.luxury => '優先刪減',
  };
}

/// 記住分類卡片的展開狀態,讓右上箭頭跟著切換。
/// 存在頁面的 PageStorage:分類捲出畫面再回來,展開/收合不會被重設。
class _ExpandedStateBuilder extends StatefulWidget {
  const _ExpandedStateBuilder({required this.storageId, required this.builder});

  final String storageId;
  final Widget Function(
    BuildContext context,
    bool expanded,
    ValueChanged<bool> onExpansionChanged,
  )
  builder;

  @override
  State<_ExpandedStateBuilder> createState() => _ExpandedStateBuilderState();
}

class _ExpandedStateBuilderState extends State<_ExpandedStateBuilder> {
  late bool _expanded =
      PageStorage.maybeOf(
            context,
          )?.readState(context, identifier: widget.storageId)
          as bool? ??
      true;

  void _handleChanged(bool expanded) {
    setState(() => _expanded = expanded);
    PageStorage.maybeOf(
      context,
    )?.writeState(context, expanded, identifier: widget.storageId);
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _expanded, _handleChanged);
}

/// 清單內頁右上「⋯」選單的項目。
enum _ListMenuAction { share, rename, delete }

class _ListMenuRow extends StatelessWidget {
  const _ListMenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;

  /// 不指定時沿用選單預設文字色;刪除用警示紅。
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? context.palette.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: color == null ? null : TextStyle(color: color)),
      ],
    );
  }
}
