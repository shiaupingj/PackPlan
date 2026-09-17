import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
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
import '../widgets/weight_bar.dart';

class PackDetailScreen extends StatefulWidget {
  const PackDetailScreen({super.key, required this.listId});

  final String listId;

  @override
  State<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends State<PackDetailScreen> {
  bool _ulMode = false;

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context);
    final list = repository.findById(widget.listId);
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
    final categoryNames = _categoryNames(list.items);
    final categoryIdByName = _categoryIdByName(list.items);

    return Scaffold(
      appBar: AppBar(
        title: Text(list.title),
        actions: [
          IconButton(
            tooltip: '重新命名',
            onPressed: () => _showRenameDialog(context, list),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: '旅程設定',
            onPressed: () => _showTripSettingsEditor(context, list),
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: '分享',
            onPressed: () =>
                _showShareSheet(context, list, settings.weightUnit),
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            TripFormatters.summary(list),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (list.showWeight) ...[
            _WeightHeader(
              summary: summary,
              unit: settings.weightUnit,
              heaviestItem: WeightCalculator.heaviestItem(list),
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
          _ContainerSummarySection(
            items: list.items,
            containers: containers,
            unit: settings.weightUnit,
            showWeight: list.showWeight,
          ),
          const SizedBox(height: AppSpacing.lg),
          _UlModePreview(
            enabled: _ulMode,
            minimumWeightGram: WeightCalculator.minimumViableWeightGram(list),
            unit: settings.weightUnit,
            suggestions: suggestions,
            showWeight: list.showWeight,
            onChanged: (value) => setState(() => _ulMode = value),
          ),
          const SizedBox(height: AppSpacing.md),
          ...groupedItems.entries.map(
            (entry) => _CategorySection(
              name: entry.key,
              items: entry.value,
              ulMode: _ulMode,
              unit: settings.weightUnit,
              showWeight: list.showWeight,
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
              containerNameById: {
                for (final container in containers)
                  container.id: container.name,
              },
              onAddItem: (categoryName) => _showItemEditor(
                context,
                list.id,
                containers: containers,
                categoryNames: categoryNames,
                categoryIdByName: categoryIdByName,
                initialCategoryName: categoryName,
              ),
              onReorder: (items) => repository.reorderItems(list.id, items),
              onRename: () =>
                  _showCategoryRenameDialog(context, list.id, entry.key),
            ),
          ),
        ],
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
          title: const Text('重新命名清單'),
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
        days: list.days,
        weatherConditions: list.weatherConditions,
        showWeight: list.showWeight,
      ),
    );
    if (result == null) return;
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
          title: Text(hasContents ? '行李內仍有項目' : '刪除項目？'),
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
  });

  final WeightSummary summary;
  final WeightUnit unit;
  final PackItem? heaviestItem;

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
            Text(
              '${WeightFormatters.gram(summary.packedGram, unit: unit)} / '
              '背包總重 ${WeightFormatters.gram(summary.totalGram, unit: unit)}',
              style: t.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (summary.wornGram > 0)
              Text(
                '穿戴 ${WeightFormatters.gram(summary.wornGram, unit: unit)}'
                '（不計背重）',
                style: t.bodySmall?.copyWith(color: AppColors.primary),
              ),
            Text(
              '上限 ${WeightFormatters.gram(summary.limitGram, unit: unit)}',
              style: t.bodySmall,
            ),
            if (heaviestItem case final item?) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '最重項目 ${item.name} · '
                '${WeightFormatters.gram(item.totalWeightGram, unit: unit)}',
                style: t.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            WeightBar(
              currentGram: summary.packedGram,
              limitGram: summary.limitGram,
              unit: unit,
            ),
          ],
        ),
      ),
    );
  }
}

class _UlModePreview extends StatelessWidget {
  const _UlModePreview({
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
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('超輕量化打包', style: t.titleMedium)),
                Switch(value: enabled, onChanged: onChanged),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (!enabled)
              Text('開啟後會標記可刪減項目並估算最低可行重量。', style: t.bodySmall)
            else if (showWeight) ...[
              Text(
                '最低可行重量 ${WeightFormatters.gram(minimumWeightGram, unit: unit)}',
                style: t.bodyMedium,
              ),
            ] else
              Text('重量資訊已在旅程設定中隱藏。', style: t.bodySmall),
            if (enabled && suggestions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              ...suggestions.map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    '可刪減「${suggestion.itemName}」'
                    '${showWeight ? '（${WeightFormatters.gram(suggestion.weightGram, unit: unit)}）' : ''}'
                    '：${suggestion.reason}',
                    style: t.bodySmall?.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContainerSummarySection extends StatelessWidget {
  const _ContainerSummarySection({
    required this.items,
    required this.containers,
    required this.unit,
    required this.showWeight,
  });

  final List<PackItem> items;
  final List<PackItem> containers;
  final WeightUnit unit;
  final bool showWeight;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final unassignedItems = items
        .where(
          (item) =>
              !item.isContainer &&
              item.weightClass != WeightClass.worn &&
              item.containerItemId == null,
        )
        .toList();
    final wornItems = items
        .where((item) => item.weightClass == WeightClass.worn)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('放置位置', style: t.titleMedium),
            const SizedBox(height: AppSpacing.md),
            if (containers.isEmpty)
              Text('至少需要新增一個背包或行李容器。', style: t.bodySmall)
            else
              ...containers.map((container) {
                final contentItems = items
                    .where((item) => item.containerItemId == container.id)
                    .toList();
                final contentWeight = contentItems.fold(
                  0,
                  (total, item) => total + item.totalWeightGram,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ContainerSummaryRow(
                    name: container.name,
                    containerWeight: container.totalWeightGram,
                    contentWeight: contentWeight,
                    itemCount: contentItems.length,
                    contentItems: contentItems,
                    unit: unit,
                    showWeight: showWeight,
                  ),
                );
              }),
            if (unassignedItems.isNotEmpty) ...[
              const Divider(height: AppSpacing.lg),
              Text(
                showWeight
                    ? '未放入 ${unassignedItems.length} 項 · '
                          '${WeightFormatters.gram(_totalWeight(unassignedItems), unit: unit)}'
                    : '未放入 ${unassignedItems.length} 項',
                style: t.bodySmall?.copyWith(color: AppColors.weightNear),
              ),
            ],
            if (wornItems.isNotEmpty) ...[
              const Divider(height: AppSpacing.lg),
              Text(
                showWeight
                    ? '身上穿戴 ${wornItems.length} 項 · '
                          '${WeightFormatters.gram(_totalWeight(wornItems), unit: unit)}'
                    : '身上穿戴 ${wornItems.length} 項',
                style: t.bodySmall?.copyWith(color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static int _totalWeight(List<PackItem> items) {
    return items.fold(0, (total, item) => total + item.totalWeightGram);
  }
}

class _ContainerSummaryRow extends StatelessWidget {
  const _ContainerSummaryRow({
    required this.name,
    required this.containerWeight,
    required this.contentWeight,
    required this.itemCount,
    required this.contentItems,
    required this.unit,
    required this.showWeight,
  });

  final String name;
  final int containerWeight;
  final int contentWeight;
  final int itemCount;
  final List<PackItem> contentItems;
  final WeightUnit unit;
  final bool showWeight;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final totalWeight = containerWeight + contentWeight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: t.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              if (showWeight)
                Text(
                  '本體 ${WeightFormatters.gram(containerWeight, unit: unit)} · '
                  '內容物 ${WeightFormatters.gram(contentWeight, unit: unit)} · '
                  '合計 ${WeightFormatters.gram(totalWeight, unit: unit)}',
                  style: t.bodySmall,
                ),
              Text('$itemCount 項已放入', style: t.bodySmall),
            ],
          ),
        ),
        if (contentItems.isNotEmpty)
          IconButton(
            tooltip: '查看 $name 內容物',
            icon: const Icon(Icons.search, size: 20),
            onPressed: () => _showContentsDialog(context),
          ),
      ],
    );
  }

  Future<void> _showContentsDialog(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$name 內容物'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showWeight)
                    Text(
                      '容器本體 ${WeightFormatters.gram(containerWeight, unit: unit)}',
                      style: t.bodySmall,
                    ),
                  Text(
                    showWeight
                        ? '內容物 $itemCount 項 · '
                              '${WeightFormatters.gram(contentWeight, unit: unit)}'
                        : '內容物 $itemCount 項',
                    style: t.bodySmall,
                  ),
                  const Divider(height: AppSpacing.lg),
                  ...contentItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.quantity > 1
                                      ? '${item.name} x${item.quantity}'
                                      : item.name,
                                  style: t.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  item.categoryName,
                                  style: t.bodySmall?.copyWith(
                                    color: context.palette.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (showWeight) ...[
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              WeightFormatters.gram(
                                item.totalWeightGram,
                                unit: unit,
                              ),
                              style: t.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('關閉'),
            ),
          ],
        );
      },
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
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
    required this.containerNameById,
    required this.onAddItem,
    required this.onReorder,
    required this.onRename,
  });

  final String name;
  final List<PackItem> items;
  final bool ulMode;
  final WeightUnit unit;
  final bool showWeight;
  final void Function(PackItem item, bool checked) onChanged;
  final ValueChanged<PackItem> onEdit;
  final ValueChanged<PackItem> onDelete;
  final Map<String, String> containerNameById;
  final ValueChanged<String> onAddItem;
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
          child: ExpansionTile(
            initiallyExpanded: true,
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
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    onPressed: () => onAddItem(name),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.expand_less, color: AppColors.primary),
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
                          checked: item.checked,
                          dimmed:
                              ulMode &&
                              item.weightClass == WeightClass.packed &&
                              item.necessity != ItemNecessity.required,
                          badgeLabel:
                              _weightClassBadge(item.weightClass) ??
                              (ulMode ? _reductionBadge(item.necessity) : null),
                          badgeFilled:
                              item.weightClass == WeightClass.worn ||
                              (item.weightClass == WeightClass.packed &&
                                  item.necessity == ItemNecessity.luxury),
                          containerLabel:
                              item.isContainer || item.containerItemId == null
                              ? null
                              : containerNameById[item.containerItemId],
                          onChanged: (checked) => onChanged(item, checked),
                          onEdit: () => onEdit(item),
                          onLongPress: () => _showItemActions(context, item),
                        ),
                      ),
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
    required this.days,
    required this.weatherConditions,
    required this.showWeight,
  });

  final int days;
  final Set<WeatherCondition> weatherConditions;
  final bool showWeight;
}

class _TripSettingsDialog extends StatefulWidget {
  const _TripSettingsDialog({
    required this.days,
    required this.weatherConditions,
    required this.showWeight,
  });

  final int days;
  final Set<WeatherCondition> weatherConditions;
  final bool showWeight;

  @override
  State<_TripSettingsDialog> createState() => _TripSettingsDialogState();
}

class _TripSettingsDialogState extends State<_TripSettingsDialog> {
  late int _days = widget.days;
  late Set<WeatherCondition> _weatherConditions = {...widget.weatherConditions};
  late bool _showWeight = widget.showWeight;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('旅程設定'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('天數', style: t.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton(
                tooltip: '減少天數',
                onPressed: _days <= 1 ? null : () => setState(() => _days -= 1),
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
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: WeatherCondition.values.map((weather) {
              final selected = _weatherConditions.contains(weather);
              return FilterChip(
                selected: selected,
                showCheckmark: true,
                checkmarkColor: AppColors.ink,
                selectedColor: AppColors.primary,
                backgroundColor: context.palette.surface,
                side: BorderSide(
                  color: selected ? AppColors.primary : context.palette.border,
                  width: 0.8,
                ),
                labelStyle: TextStyle(
                  color: selected ? AppColors.ink : context.palette.textPrimary,
                ),
                label: Text(_weatherLabel(weather)),
                onSelected: (value) {
                  final next = {..._weatherConditions};
                  if (value) {
                    next.add(weather);
                  } else if (next.length > 1) {
                    next.remove(weather);
                  }
                  setState(() => _weatherConditions = next);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('顯示重量'),
            subtitle: const Text('套用於首頁、清單詳情與分享摘要'),
            value: _showWeight,
            onChanged: (value) => setState(() => _showWeight = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _TripSettingsResult(
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
      title: const Text('重新命名分類'),
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
      title: const Text('分類排序'),
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
  });

  final PackItem? item;
  final List<PackItem> containers;
  final List<String> categoryNames;
  final Map<String, String> categoryIdByName;
  final String? initialCategoryName;

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
      widget.item?.containerItemId ?? _defaultContainerItemId;
  late String _lastCategoryName;
  bool _isAddingCategory = false;

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

  @override
  void initState() {
    super.initState();
    _lastCategoryName = _normalizedCategory(_categoryController.text);
    _categoryController.addListener(_handleCategoryChanged);
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
      title: Text(widget.item == null ? '新增項目' : '編輯項目'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('名稱', style: _editorFieldLabelStyle(context)),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(),
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
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: '單件重量 g'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: '數量'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<WeightClass>(
              value: _weightClass,
              decoration: const InputDecoration(labelText: '重量類型'),
              items: WeightClass.values
                  .map(
                    (weightClass) => DropdownMenuItem(
                      value: weightClass,
                      enabled:
                          weightClass == WeightClass.packed ||
                          !(widget.item?.isContainer == true &&
                              widget.containers.length <= 1),
                      child: Text(
                        weightClass != WeightClass.packed &&
                                widget.item?.isContainer == true &&
                                widget.containers.length <= 1
                            ? '${_weightClassLabel(weightClass)}（需保留容器）'
                            : _weightClassLabel(weightClass),
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
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ItemNecessity>(
              value: _necessity,
              decoration: const InputDecoration(labelText: '必要性'),
              items: ItemNecessity.values
                  .map(
                    (necessity) => DropdownMenuItem(
                      value: necessity,
                      child: Text(_necessityLabel(necessity)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _necessity = value);
              },
            ),
            if (_weightClass == WeightClass.packed) ...[
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('設為背包/行李容器'),
                subtitle: const Text('容器本身會計入重量，其他項目可放入此處'),
                value: _isContainer,
                onChanged: (value) {
                  setState(() {
                    _isContainer = value;
                    if (value) _containerItemId = null;
                  });
                },
              ),
            ],
            if (_weightClass != WeightClass.worn &&
                !_isContainer &&
                _availableContainers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String?>(
                value:
                    _availableContainers.any(
                      (container) => container.id == _containerItemId,
                    )
                    ? _containerItemId
                    : null,
                decoration: const InputDecoration(labelText: '放置位置'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('未指定'),
                  ),
                  ..._availableContainers.map(
                    (container) => DropdownMenuItem<String?>(
                      value: container.id,
                      child: Text(container.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _containerItemId = value),
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
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('儲存')),
      ],
    );
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
            );

    Navigator.of(context).pop(_ItemEditorResult.save(item));
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

String _weatherLabel(WeatherCondition weather) {
  return switch (weather) {
    WeatherCondition.sunny => '晴天',
    WeatherCondition.cloudy => '陰天',
    WeatherCondition.rainy => '雨天',
    WeatherCondition.cold => '低溫',
  };
}
