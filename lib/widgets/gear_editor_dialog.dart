import 'package:flutter/material.dart';

import '../data/seed_data.dart';
import '../models/gear_item.dart';
import '../models/pack_item.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';
import 'app_dialog_buttons.dart';
import 'app_dialog_title.dart';

/// 新增 / 編輯「我的裝備」的結果:儲存的裝備,或要刪除的裝備 id。
class GearEditorResult {
  const GearEditorResult.save(GearItem this.gear) : deleteGearId = null;
  const GearEditorResult.delete(String this.deleteGearId) : gear = null;

  final GearItem? gear;
  final String? deleteGearId;
}

Future<GearEditorResult?> showGearEditor(
  BuildContext context, {
  GearItem? gear,
  required List<GearItem> library,
}) {
  return showDialog<GearEditorResult>(
    context: context,
    builder: (_) => _GearEditorDialog(gear: gear, library: library),
  );
}

/// 可選的分類:範本內建分類 + 裝備庫已用過的分類,依名稱去重。
List<({String id, String name})> gearCategoryOptions(List<GearItem> library) {
  final options = <({String id, String name})>[];
  void add(String id, String name) {
    if (options.any((option) => option.name == name)) return;
    options.add((id: id, name: name));
  }

  for (final template in SeedData.templates) {
    for (final item in SeedData.itemsForTemplate(template)) {
      add(item.categoryId, item.categoryName);
    }
  }
  for (final gear in library) {
    add(gear.categoryId, gear.categoryName);
  }
  return options;
}

class _GearEditorDialog extends StatefulWidget {
  const _GearEditorDialog({this.gear, required this.library});

  final GearItem? gear;
  final List<GearItem> library;

  @override
  State<_GearEditorDialog> createState() => _GearEditorDialogState();
}

class _GearEditorDialogState extends State<_GearEditorDialog> {
  static const _containerCategoryIds = {'backpack', 'luggage'};
  static const _addCategoryValue = '__add_category__';

  late final _categories = gearCategoryOptions(widget.library);
  late final _nameController = TextEditingController(
    text: widget.gear?.name ?? '',
  );
  late final _weightController = TextEditingController(
    text: widget.gear == null ? '' : '${widget.gear!.weightGram}',
  );
  final _newCategoryController = TextEditingController();
  late String _categoryName = widget.gear?.categoryName ?? '自訂';
  late WeightClass _weightClass =
      widget.gear?.weightClass ?? WeightClass.packed;
  late bool _isContainer =
      widget.gear?.isContainer ?? _isContainerCategory(_categoryName);
  bool _isAddingCategory = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  String _categoryIdOf(String name) {
    for (final option in _categories) {
      if (option.name == name) return option.id;
    }
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  }

  bool _isContainerCategory(String name) =>
      _containerCategoryIds.contains(_categoryIdOf(name));

  @override
  Widget build(BuildContext context) {
    final names = [
      for (final option in _categories) option.name,
      if (!_categories.any((option) => option.name == _categoryName))
        _categoryName,
    ];
    return AlertDialog(
      titlePadding: AppDialogTitle.padding,
      title: AppDialogTitle(widget.gear == null ? '新增裝備' : '編輯裝備'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('gear-editor-name'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: '名稱'),
              minLines: 1,
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              key: const ValueKey('gear-editor-category'),
              value: _categoryName,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '分類'),
              items: [
                for (final name in names)
                  DropdownMenuItem(value: name, child: Text(name)),
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
                child: FilledButton(
                  onPressed: _applyNewCategory,
                  child: const Text('加入分類'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const ValueKey('gear-editor-weight'),
              controller: _weightController,
              decoration: const InputDecoration(labelText: '重量 g'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<WeightClass>(
              key: const ValueKey('gear-editor-placement'),
              value: _weightClass,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: '加入清單時放在',
                helperText: _weightClass == WeightClass.packed ? null : '不計入背重',
              ),
              items: const [
                DropdownMenuItem(
                  value: WeightClass.packed,
                  child: Text('背包 / 行李內'),
                ),
                DropdownMenuItem(value: WeightClass.worn, child: Text('身上穿戴')),
                DropdownMenuItem(
                  value: WeightClass.vehicle,
                  child: Text('放車上'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _weightClass = value;
                  if (value != WeightClass.packed) _isContainer = false;
                });
              },
            ),
            if (_weightClass == WeightClass.packed)
              SwitchListTile(
                key: const ValueKey('gear-editor-container'),
                contentPadding: EdgeInsets.zero,
                title: const Text('設為容器'),
                subtitle: Text(
                  '背包、行李箱等可以放其他項目',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                value: _isContainer,
                onChanged: (value) => setState(() => _isContainer = value),
              ),
          ],
        ),
      ),
      actions: [
        if (widget.gear != null)
          AppDialogTextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(GearEditorResult.delete(widget.gear!.id)),
            label: '刪除',
          ),
        AppDialogCancelButton(onPressed: () => Navigator.of(context).pop()),
        AppDialogConfirmButton(onPressed: _save, label: '儲存'),
      ],
    );
  }

  void _chooseCategory(String name) {
    setState(() {
      _isAddingCategory = false;
      _newCategoryController.clear();
      // 換到背包、行李分類時順手設為容器;反向不自動關,避免蓋掉使用者的選擇。
      if (_categoryName != name &&
          _isContainerCategory(name) &&
          _weightClass == WeightClass.packed) {
        _isContainer = true;
      }
      _categoryName = name;
    });
  }

  void _applyNewCategory() {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請輸入分類名稱')));
      return;
    }
    _chooseCategory(name);
  }

  void _save() {
    final name = _nameController.text.trim();
    final weightText = _weightController.text.trim();
    final weight = weightText.isEmpty ? 0 : int.tryParse(weightText);
    if (name.isEmpty || weight == null || weight < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請填寫名稱；重量不可小於 0')));
      return;
    }

    final now = DateTime.now();
    final base =
        widget.gear ??
        GearItem(
          id: 'gear-${now.microsecondsSinceEpoch}',
          name: name,
          categoryId: _categoryIdOf(_categoryName),
          categoryName: _categoryName,
          weightGram: weight,
          createdAt: now,
          updatedAt: now,
        );
    Navigator.of(context).pop(
      GearEditorResult.save(
        base.copyWith(
          name: name,
          categoryId: _categoryIdOf(_categoryName),
          categoryName: _categoryName,
          weightGram: weight,
          weightClass: _weightClass,
          isContainer: _isContainer && _weightClass == WeightClass.packed,
        ),
      ),
    );
  }
}
