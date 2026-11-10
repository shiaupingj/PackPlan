import 'package:flutter/material.dart';

import '../models/gear_item.dart';
import '../models/pack_item.dart';
import '../models/user_settings.dart';
import '../services/formatters.dart';
import '../services/gear_library.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';

/// 從「我的裝備」挑選的結果:要加入的裝備 id 與要放進的容器,或改用手動輸入。
class GearPickerResult {
  const GearPickerResult.add(this.gearIds, {this.containerItemId})
    : manual = false;
  const GearPickerResult.manual()
    : gearIds = const [],
      containerItemId = null,
      manual = true;

  final List<String> gearIds;

  /// 放背包內的裝備要放進的容器;穿戴、放車上的裝備不受影響。
  final String? containerItemId;
  final bool manual;
}

/// 清單「新增項目」:從我的裝備多選一次加入;已在清單中的裝備顯示「已加入」。
/// 清單有兩個以上容器時,底部可選這次要放進哪一個(預設 [initialContainerId]
/// 或第一個容器)。
Future<GearPickerResult?> showGearPicker(
  BuildContext context, {
  required List<GearItem> library,
  required Set<String> addedGearIds,
  required WeightUnit unit,
  List<PackItem> containers = const [],
  String? initialContainerId,
}) {
  return showModalBottomSheet<GearPickerResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _GearPickerSheet(
        library: library,
        addedGearIds: addedGearIds,
        unit: unit,
        containers: containers,
        initialContainerId: initialContainerId,
      ),
    ),
  );
}

class _GearPickerSheet extends StatefulWidget {
  const _GearPickerSheet({
    required this.library,
    required this.addedGearIds,
    required this.unit,
    required this.containers,
    required this.initialContainerId,
  });

  final List<GearItem> library;
  final Set<String> addedGearIds;
  final WeightUnit unit;
  final List<PackItem> containers;
  final String? initialContainerId;

  @override
  State<_GearPickerSheet> createState() => _GearPickerSheetState();
}

class _GearPickerSheetState extends State<_GearPickerSheet> {
  final _selected = <String>{};
  final _searchController = TextEditingController();
  late String? _containerItemId =
      widget.containers.any(
        (container) => container.id == widget.initialContainerId,
      )
      ? widget.initialContainerId
      : widget.containers.firstOrNull?.id;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final query = _searchController.text.trim().toLowerCase();
    final visible = sortGear(
      widget.library,
      GearSort.mostUsed,
    ).where((gear) => gear.name.toLowerCase().contains(query)).toList();
    final groups = groupGearByCategory(visible);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(child: Text('從我的裝備加入', style: t.titleLarge)),
                  TextButton.icon(
                    key: const ValueKey('gear-picker-manual'),
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const GearPickerResult.manual()),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('手動輸入'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                key: const ValueKey('gear-picker-search'),
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '搜尋我的裝備',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        '找不到「${_searchController.text.trim()}」',
                        style: t.bodyMedium?.copyWith(
                          color: context.palette.textSecondary,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final entry in groups.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.xs,
                            ),
                            child: Text(entry.key, style: t.titleSmall),
                          ),
                          for (final gear in entry.value) _tile(context, gear),
                        ],
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 只有一個容器時沒得選,不顯示。
                  if (widget.containers.length > 1) ...[
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        key: const ValueKey('gear-picker-container'),
                        value: _containerItemId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: '放進'),
                        items: [
                          for (final container in widget.containers)
                            DropdownMenuItem(
                              value: container.id,
                              child: Text(
                                container.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _containerItemId = value),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(flex: 3, child: _addButton()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton() {
    return FilledButton(
      key: const ValueKey('gear-picker-add'),
      onPressed: _selected.isEmpty
          ? null
          : () => Navigator.of(context).pop(
              GearPickerResult.add([
                // 照裝備庫順序加入,不受點選先後影響。
                for (final gear in widget.library)
                  if (_selected.contains(gear.id)) gear.id,
              ], containerItemId: _containerItemId),
            ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
      child: Text('加入所選 (${_selected.length})'),
    );
  }

  Widget _tile(BuildContext context, GearItem gear) {
    final added = widget.addedGearIds.contains(gear.id);
    final weight = WeightFormatters.gram(gear.weightGram, unit: widget.unit);
    return CheckboxListTile(
      key: ValueKey('gear-picker-${gear.id}'),
      value: added || _selected.contains(gear.id),
      onChanged: added
          ? null
          : (checked) => setState(() {
              if (checked == true) {
                _selected.add(gear.id);
              } else {
                _selected.remove(gear.id);
              }
            }),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.primary,
      title: Text(gear.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(added ? '已加入' : gearSubtitle(gear)),
      secondary: Text(
        weight,
        // ListTile 的 secondary 預設字較小,改用和項目名稱同級的字。
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: added ? context.palette.textTertiary : null,
        ),
      ),
    );
  }
}
