import 'package:flutter/material.dart';

import '../data/weight_reference_repository.dart';
import '../models/gear_weight.dart';
import '../models/pack_item.dart';
import '../models/user_settings.dart';
import '../services/formatters.dart';
import '../services/weight_reference_source.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';

/// 參考重量的顯示文字(帶入值與範圍)。
abstract final class WeightReferenceLabels {
  /// 「700 g–1.5 kg」;沒有範圍,或兩端換算後顯示相同(如 1850/1890 g 都是 1.9 kg)時回傳空字串。
  static String range(GearWeight weight, WeightUnit unit) {
    if (!weight.hasRange) return '';
    final min = WeightFormatters.gram(weight.weightMin!, unit: unit);
    final max = WeightFormatters.gram(weight.weightMax!, unit: unit);
    return min == max ? '' : '$min–$max';
  }

  /// 「線上參考值 · 範圍 700 g–1.5 kg」;查不到資料時只顯示「線上參考值」。
  static String tooltip(GearWeight? weight, WeightUnit unit) {
    final text = weight == null ? '' : range(weight, unit);
    return text.isEmpty ? '線上參考值' : '線上參考值 · 範圍 $text';
  }

  /// 選單中的型號名稱:已有品牌分組標題或副標,去掉開頭重複的品牌名
  /// (「ISUKA Air 1000EX」→「Air 1000EX」)。選用後項目名稱仍用完整名稱。
  static String modelName(GearWeight weight) {
    final brand = weight.brand?.trim();
    final name = weight.nameZh;
    if (brand == null || brand.isEmpty) return name;
    if (!name.toLowerCase().startsWith(brand.toLowerCase())) return name;
    final rest = name.substring(brand.length).trim();
    return rest.isEmpty ? name : rest;
  }

  static String source(WeightReferenceRepository references) {
    final version = references.version?.toLocal();
    final date = version == null
        ? ''
        : ' · 更新於 ${version.month}/${version.day}';
    return '資料來源：PackPlan 線上重量庫$date';
  }

  /// 帶入參考重量後的項目:標記為線上資料並記下對應的資料 key。
  static PackItem apply(PackItem item, GearWeight weight) => item.copyWith(
    weightGram: weight.weightGram,
    weightSource: WeightSource.online,
    catalogKey: weight.key,
  );
}

/// 批次補重量:列出缺重量項目的比對結果,回傳要套用的新項目(取消回傳 null)。
Future<List<PackItem>?> showWeightFillSheet(
  BuildContext context, {
  required List<PackItem> items,
  required WeightReferenceRepository references,
  required WeightUnit unit,
}) {
  return showModalBottomSheet<List<PackItem>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _WeightFillSheet(items: items, references: references, unit: unit),
  );
}

class _WeightFillSheet extends StatefulWidget {
  const _WeightFillSheet({
    required this.items,
    required this.references,
    required this.unit,
  });

  final List<PackItem> items;
  final WeightReferenceRepository references;
  final WeightUnit unit;

  @override
  State<_WeightFillSheet> createState() => _WeightFillSheetState();
}

class _WeightFillSheetState extends State<_WeightFillSheet> {
  final Set<String> _deselected = {};
  String? _syncError;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      await widget.references.sync();
    } on WeightReferenceException catch (error) {
      if (mounted) setState(() => _syncError = error.message);
    } on Object catch (error) {
      debugPrint('Weight reference sync failed: $error');
      if (mounted) setState(() => _syncError = '無法更新線上參考重量');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: widget.references,
      builder: (context, _) {
        final references = widget.references;
        final matched = <(PackItem, GearWeight)>[];
        final unmatched = <PackItem>[];
        if (references.isLoaded) {
          for (final item in widget.items) {
            final weight = references.matchItem(item);
            if (weight == null) {
              unmatched.add(item);
            } else {
              matched.add((item, weight));
            }
          }
        }
        final selected = matched
            .where((pair) => !_deselected.contains(pair.$1.id))
            .toList();

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('帶入參考重量', style: t.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${widget.items.length} 項尚未填重量，'
                    '找到 ${matched.length} 項參考值',
                    style: t.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (references.isSyncing || !references.isLoaded)
                    const LinearProgressIndicator(color: AppColors.primary),
                  if (_syncError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        references.hasData
                            ? '$_syncError，先使用手機上的資料'
                            : _syncError!,
                        style: t.bodySmall?.copyWith(
                          color: context.palette.weightNear,
                        ),
                      ),
                    ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final (item, weight) in matched)
                          CheckboxListTile(
                            key: ValueKey('weight-fill-${item.id}'),
                            value: !_deselected.contains(item.id),
                            onChanged: (value) => setState(() {
                              if (value ?? false) {
                                _deselected.remove(item.id);
                              } else {
                                _deselected.add(item.id);
                              }
                            }),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name),
                            subtitle:
                                WeightReferenceLabels.range(
                                  weight,
                                  widget.unit,
                                ).isEmpty
                                ? null
                                : Text(
                                    '參考範圍 '
                                    '${WeightReferenceLabels.range(weight, widget.unit)}',
                                  ),
                            secondary: Text(
                              WeightFormatters.gram(
                                weight.weightGram,
                                unit: widget.unit,
                              ),
                              style: t.bodyMedium,
                            ),
                          ),
                        if (unmatched.isNotEmpty && references.hasData) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '查無參考資料（${unmatched.length}）',
                            style: t.bodySmall?.copyWith(
                              color: context.palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            unmatched.map((item) => item.name).join('、'),
                            style: t.bodySmall,
                          ),
                        ],
                        if (matched.isEmpty &&
                            references.isLoaded &&
                            !references.isSyncing &&
                            _syncError == null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            references.hasData
                                ? '這些項目目前都沒有參考重量，可以手動填寫。'
                                : '線上重量庫目前沒有資料。',
                            style: t.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    WeightReferenceLabels.source(references),
                    style: t.bodySmall?.copyWith(
                      color: context.palette.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    key: const ValueKey('weight-fill-apply'),
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.of(context).pop([
                            for (final (item, weight) in selected)
                              WeightReferenceLabels.apply(item, weight),
                          ]),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppRadius.dialogButton,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: Text('套用 ${selected.length} 項'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 單項帶入:列出通用值與品牌型號,回傳選中的一筆(取消回傳 null)。
/// [selectedKey] 是項目目前採用的參考值,會打勾並以底色標示。
/// 頂端搜尋框可用品牌、型號或名稱搜尋整個重量庫;[initialQuery] 有值時
/// 直接以搜尋模式開啟(比對不到項目時使用)。
Future<GearWeight?> showWeightReferencePicker(
  BuildContext context, {
  required GearWeight? generic,
  required List<GearWeight> variants,
  required WeightReferenceRepository references,
  required WeightUnit unit,
  String? selectedKey,
  String? initialQuery,
  String? categoryId,
  String? categoryName,
}) {
  return showModalBottomSheet<GearWeight>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _WeightReferencePicker(
      generic: generic,
      variants: variants,
      references: references,
      unit: unit,
      selectedKey: selectedKey,
      initialQuery: initialQuery ?? '',
      // 自訂分類等沒有任何參考資料的分類,直接搜全部。
      categoryId: categoryId != null && references.hasCategory(categoryId)
          ? categoryId
          : null,
      categoryName: categoryName,
    ),
  );
}

class _WeightReferencePicker extends StatefulWidget {
  const _WeightReferencePicker({
    required this.generic,
    required this.variants,
    required this.references,
    required this.unit,
    required this.selectedKey,
    required this.initialQuery,
    required this.categoryId,
    required this.categoryName,
  });

  final GearWeight? generic;
  final List<GearWeight> variants;
  final WeightReferenceRepository references;
  final WeightUnit unit;
  final String? selectedKey;
  final String initialQuery;

  /// 搜尋預設只找這個分類;null 表示沒有可限定的分類。
  final String? categoryId;
  final String? categoryName;

  @override
  State<_WeightReferencePicker> createState() => _WeightReferencePickerState();
}

class _WeightReferencePickerState extends State<_WeightReferencePicker> {
  late final TextEditingController _queryController = TextEditingController(
    text: widget.initialQuery,
  );

  String get _query => _queryController.text.trim();

  /// 搜尋範圍:預設限定項目所在分類,可切到全部分類。
  late bool _allCategories = widget.categoryId == null;

  String? get _scope => _allCategories ? null : widget.categoryId;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Widget _inset(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    child: child,
  );

  /// 搜尋結果的副標:品牌、所屬通用項目、範圍。
  String? _searchSubtitle(GearWeight weight) {
    final parts = [
      if (weight.brand case final brand?) brand,
      if (weight.parentKey case final parentKey?)
        if (widget.references.lookup(parentKey) case final parent?)
          '屬於「${parent.nameZh}」',
      if (WeightReferenceLabels.range(weight, widget.unit) case final range
          when range.isNotEmpty)
        '範圍 $range',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Widget _tile(GearWeight weight, {String? title, String? subtitle}) {
    final t = Theme.of(context).textTheme;
    final selected = weight.key == widget.selectedKey;
    return ListTile(
      key: ValueKey('weight-reference-${weight.key}'),
      selected: selected,
      selectedColor: AppColors.primary,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      title: Text(
        title ?? WeightReferenceLabels.modelName(weight),
        style: selected ? const TextStyle(fontWeight: FontWeight.w500) : null,
      ),
      subtitle: subtitle != null
          ? Text(subtitle)
          : switch (WeightReferenceLabels.range(weight, widget.unit)) {
              '' => null,
              final range => Text('參考範圍 $range'),
            },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            const Icon(
              Icons.check_circle,
              key: ValueKey('weight-reference-selected'),
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            WeightFormatters.gram(weight.weightGram, unit: widget.unit),
            style: t.bodyMedium?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
      onTap: () => Navigator.of(context).pop(weight),
    );
  }

  List<Widget> _browseChildren() {
    final t = Theme.of(context).textTheme;
    final byBrand = <String, List<GearWeight>>{};
    for (final variant in widget.variants) {
      byBrand.putIfAbsent(variant.brand ?? '其他', () => []).add(variant);
    }
    return [
      if (widget.generic case final generic?) ...[
        const SizedBox(height: AppSpacing.sm),
        _tile(generic, title: '通用值（${generic.nameZh}）'),
      ],
      for (final MapEntry(key: brand, value: models) in byBrand.entries) ...[
        const SizedBox(height: AppSpacing.md),
        _inset(
          Text(
            brand,
            style: t.bodySmall?.copyWith(color: context.palette.textSecondary),
          ),
        ),
        for (final model in models) _tile(model),
      ],
    ];
  }

  /// 搜尋範圍切換:「<分類>」/「全部分類」。
  Widget _scopeChips() {
    Widget chip(String label, bool all) {
      final selected = _allCategories == all;
      return ChoiceChip(
        key: ValueKey('weight-reference-scope-${all ? 'all' : 'category'}'),
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? AppColors.ink : context.palette.textPrimary,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : context.palette.border,
        ),
        onSelected: (_) => setState(() => _allCategories = all),
      );
    }

    return _inset(
      Wrap(
        spacing: AppSpacing.sm,
        children: [
          chip(widget.categoryName ?? '此分類', false),
          chip('全部分類', true),
        ],
      ),
    );
  }

  List<Widget> _searchChildren() {
    final results = widget.references.search(_query, categoryId: _scope);
    if (results.isEmpty) {
      final t = Theme.of(context).textTheme;
      return [
        const SizedBox(height: AppSpacing.md),
        _inset(
          Text(
            _scope == null
                ? '找不到「$_query」，試試品牌、型號或其他名稱'
                : '「${widget.categoryName}」找不到「$_query」',
            key: const ValueKey('weight-reference-search-empty'),
            style: t.bodySmall?.copyWith(color: context.palette.textSecondary),
          ),
        ),
        if (_scope != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('weight-reference-search-all'),
              onPressed: () => setState(() => _allCategories = true),
              child: const Text('改搜全部分類'),
            ),
          ),
      ];
    }
    return [
      const SizedBox(height: AppSpacing.sm),
      for (final result in results)
        _tile(result, subtitle: _searchSubtitle(result)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final searching = _query.isNotEmpty;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Padding(
          // 型號列有選取底色,左右只留 sm;標題等文字另補 sm,與列內文字對齊。
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sm,
            0,
            AppSpacing.sm,
            AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              _inset(Text('帶入參考值', style: t.titleLarge)),
              if (widget.variants.isNotEmpty || searching) ...[
                const SizedBox(height: AppSpacing.xs),
                _inset(Text('選品牌型號時，項目名稱會改成型號名。', style: t.bodySmall)),
              ],
              const SizedBox(height: AppSpacing.sm),
              _inset(
                TextField(
                  key: const ValueKey('weight-reference-search'),
                  controller: _queryController,
                  autofocus: widget.generic == null && widget.variants.isEmpty,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '搜尋品牌、型號或名稱',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searching
                        ? IconButton(
                            tooltip: '清除搜尋',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(_queryController.clear),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (searching && widget.categoryId != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _scopeChips(),
              ],
              ...(searching ? _searchChildren() : _browseChildren()),
              const SizedBox(height: AppSpacing.md),
              _inset(
                Text(
                  WeightReferenceLabels.source(widget.references),
                  style: t.bodySmall?.copyWith(
                    color: context.palette.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
