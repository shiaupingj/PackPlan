import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/gear_item.dart';
import '../models/user_settings.dart';
import '../services/formatters.dart';
import '../services/gear_library.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_dialog_buttons.dart';
import '../widgets/app_dialog_title.dart';
import '../widgets/gear_editor_dialog.dart';
import '../widgets/underline_tab.dart';

/// 「我的裝備」分頁:個人裝備資產庫,建立清單時可以直接挑。
class GearScreen extends StatefulWidget {
  const GearScreen({super.key});

  @override
  State<GearScreen> createState() => _GearScreenState();
}

class _GearScreenState extends State<GearScreen> {
  GearSort _sort = GearSort.mostUsed;

  /// 目前的分類分頁;null 是「全部」。
  String? _category;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context);
    final unit = repository.settings.weightUnit;
    final library = repository.gear;
    final t = Theme.of(context).textTheme;
    final query = _searchController.text.trim().toLowerCase();
    // 分頁只列出有裝備的分類;選到的分類被清空(裝備刪掉或改分類)就回到「全部」。
    final groups = groupGearByCategory(library);
    final category = groups.containsKey(_category) ? _category : null;
    final visible = sortGear(library, _sort)
        .where(
          (gear) =>
              (category == null || gear.categoryName == category) &&
              gear.name.toLowerCase().contains(query),
        )
        .toList();
    final tabs = <(String?, String, int)>[
      (null, '全部', library.length),
      for (final entry in groups.entries)
        (entry.key, entry.key, entry.value.length),
    ];
    final totalGram = library.fold(0, (total, gear) => total + gear.weightGram);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的裝備'),
        actions: [
          if (library.isNotEmpty)
            PopupMenuButton<GearSort>(
              key: const ValueKey('gear-sort'),
              tooltip: '排序',
              icon: const Icon(Icons.sort),
              initialValue: _sort,
              onSelected: (sort) => setState(() => _sort = sort),
              itemBuilder: (_) => [
                for (final sort in GearSort.values)
                  PopupMenuItem(value: sort, child: Text(gearSortLabel(sort))),
              ],
            ),
          IconButton(
            key: const ValueKey('gear-add'),
            tooltip: '新增裝備',
            icon: const Icon(Icons.add),
            onPressed: () => _edit(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.navBarClearance,
        ),
        children: [
          if (library.isEmpty)
            _EmptyState(onAdd: () => _edit(context))
          else ...[
            Text(
              '共 ${library.length} 件 · ${WeightFormatters.gram(totalGram, unit: unit)}'
              ' · 依${gearSortLabel(_sort)}排序',
              style: t.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const ValueKey('gear-search'),
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '搜尋裝備',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清除搜尋',
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _searchController.clear()),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.palette.border),
                ),
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
                          child: UnderlineTab(
                            key: ValueKey('gear-tab-${value ?? 'all'}'),
                            label: label,
                            count: count,
                            selected: value == category,
                            onTap: () => setState(() => _category = value),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  query.isEmpty
                      ? '這個分類還沒有裝備'
                      : '找不到「${_searchController.text.trim()}」',
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    children: [
                      for (final gear in visible)
                        _GearTile(
                          gear: gear,
                          unit: unit,
                          onTap: () => _edit(context, gear: gear),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, {GearItem? gear}) async {
    final repository = AppScope.of(context);
    final result = await showGearEditor(
      context,
      gear: gear,
      library: repository.gear,
    );
    if (result == null || !context.mounted) return;
    if (result.gear case final saved?) {
      repository.upsertGear(saved);
      return;
    }
    if (result.deleteGearId case final id? when gear != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          titlePadding: AppDialogTitle.padding,
          title: const AppDialogTitle('刪除裝備？'),
          content: Text('要從我的裝備刪除「${gear.name}」嗎？已經加入的清單不受影響。'),
          actions: [
            AppDialogCancelButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppDialogConfirmButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              label: '確定刪除',
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        AppScope.of(context).deleteGear(id);
      }
    }
  }
}

class _GearTile extends StatelessWidget {
  const _GearTile({
    required this.gear,
    required this.unit,
    required this.onTap,
  });

  final GearItem gear;
  final WeightUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = gearSubtitle(gear);
    return ListTile(
      key: ValueKey('gear-tile-${gear.id}'),
      onTap: onTap,
      title: Text(gear.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: Text(
        WeightFormatters.gram(gear.weightGram, unit: unit),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(
            Icons.backpack_outlined,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('裝備庫是空的', style: t.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '在清單裡長按項目「收藏到我的裝備」，\n或手動新增第一件裝備。',
            textAlign: TextAlign.center,
            style: t.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: '新增裝備', icon: Icons.add, onPressed: onAdd),
        ],
      ),
    );
  }
}
