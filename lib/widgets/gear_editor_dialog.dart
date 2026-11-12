import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/weight_reference_scope.dart';
import '../data/seed_data.dart';
import '../models/gear_item.dart';
import '../models/gear_weight.dart';
import '../models/pack_item.dart';
import '../services/formatters.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';
import 'app_dialog_buttons.dart';
import 'app_dialog_title.dart';
import 'app_snack_bar.dart';
import 'category_picker_sheet.dart';
import 'weight_reference_sheets.dart';

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

  /// 這次編輯中從線上參考重量帶入的資料。
  GearWeight? _appliedReference;
  bool _lookingUpReference = false;

  /// 查不到參考值時顯示在按鈕旁(SnackBar 會被對話框遮住)。
  String? _referenceNotice;
  bool _referencesRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 開啟編輯就先備好線上資料,按「帶入參考值」時不用等。
    if (_referencesRequested) return;
    _referencesRequested = true;
    final references = WeightReferenceScope.of(context);
    references.load().then((_) {
      if (!references.hasData) references.syncQuietly();
    });
  }

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
            // 分類有十幾個,下拉選單太長,改成點開底部面板用標籤挑。
            InkWell(
              key: const ValueKey('gear-editor-category'),
              onTap: () async {
                final value = await showCategoryPicker(
                  context,
                  names: names,
                  selected: _categoryName,
                );
                if (value == null || !mounted) return;
                if (value == categoryPickerAddValue) {
                  setState(() => _isAddingCategory = true);
                  return;
                }
                _chooseCategory(value);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '分類',
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(_categoryName),
              ),
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
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: '重量 g'),
              keyboardType: TextInputType.number,
            ),
            // 「帶入參考值」右邊接著顯示剛帶入的線上參考值(或查詢結果提示)。
            Row(
              children: [
                TextButton.icon(
                  key: const ValueKey('gear-editor-weight-reference'),
                  onPressed: _lookingUpReference ? null : _pickReference,
                  icon: _lookingUpReference
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download_outlined, size: 18),
                  label: const Text('帶入參考值'),
                ),
                const SizedBox(width: AppSpacing.xs),
                if (_referenceHint(context) case final hint?) ...[
                  const Icon(
                    Icons.cloud_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      hint,
                      key: const ValueKey('gear-editor-reference-hint'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                    ),
                  ),
                ] else if (_referenceNotice case final notice?)
                  Expanded(
                    child: Text(
                      notice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
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

  /// 重量欄仍是剛帶入的參考值時,顯示「線上參考 90 g（範圍 …）」。
  String? _referenceHint(BuildContext context) {
    final reference = _appliedReference;
    if (reference == null ||
        _weightController.text.trim() != '${reference.weightGram}') {
      return null;
    }
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
    if (!references.hasData) {
      setState(() => _referenceNotice = '目前沒有可用的參考重量，請確認網路後再試');
      return;
    }

    // 比對到型號時,改列出它所屬的通用項目與同系列型號;比對不到就直接開搜尋。
    final catalogKey = _appliedReference?.key ?? widget.gear?.catalogKey;
    final match = references.match(catalogKey: catalogKey, name: name);
    final parentKey = match?.parentKey ?? match?.key ?? catalogKey;
    final generic = parentKey == null ? null : references.lookup(parentKey);
    final variants = parentKey == null
        ? const <GearWeight>[]
        : references.variantsOf(parentKey);
    final notFound = generic == null && variants.isEmpty;

    final current = _appliedReference;
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
      categoryId: _categoryIdOf(_categoryName),
      categoryName: _categoryName,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _appliedReference = picked;
      _weightController.text = '${picked.weightGram}';
      // 選了品牌型號,或名稱還沒填 → 名稱一併帶入。
      if (picked.isVariant || _nameController.text.trim().isEmpty) {
        _nameController.text = picked.nameZh;
      }
    });
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
      ).showSnackBar(appSnackBar('請輸入分類名稱', tone: AppSnackTone.error));
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
      ).showSnackBar(appSnackBar('請填寫名稱；重量不可小於 0', tone: AppSnackTone.error));
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
          // 帶入過參考值就記下對應的通用項目,之後和範本配對用。
          catalogKey: _appliedReference == null
              ? base.catalogKey
              : _appliedReference!.parentKey ?? _appliedReference!.key,
        ),
      ),
    );
  }
}
