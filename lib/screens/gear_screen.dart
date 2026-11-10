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

/// 「我的裝備」分頁:個人裝備資產庫,建立清單時可以直接挑。
class GearScreen extends StatefulWidget {
  const GearScreen({super.key});

  @override
  State<GearScreen> createState() => _GearScreenState();
}

class _GearScreenState extends State<GearScreen> {
  GearSort _sort = GearSort.mostUsed;
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
    final visible = sortGear(
      library,
      _sort,
    ).where((gear) => gear.name.toLowerCase().contains(query)).toList();
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
            const SizedBox(height: AppSpacing.lg),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  '找不到「${_searchController.text.trim()}」',
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
            for (final entry in groupGearByCategory(visible).entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            AppSpacing.xs,
                          ),
                          child: Text(entry.key, style: t.titleMedium),
                        ),
                        for (final gear in entry.value)
                          _GearTile(
                            gear: gear,
                            unit: unit,
                            onTap: () => _edit(context, gear: gear),
                          ),
                      ],
                    ),
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
    return ListTile(
      key: ValueKey('gear-tile-${gear.id}'),
      onTap: onTap,
      title: Text(gear.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(gearSubtitle(gear)),
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
