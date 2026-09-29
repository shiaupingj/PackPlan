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
  static String range(GearWeight weight, WeightUnit unit) {
    if (!weight.hasRange) return '';
    return '${WeightFormatters.gram(weight.weightMin!, unit: unit)}–'
        '${WeightFormatters.gram(weight.weightMax!, unit: unit)}';
  }

  /// 「線上參考值 · 範圍 700 g–1.5 kg」;查不到資料時只顯示「線上參考值」。
  static String tooltip(GearWeight? weight, WeightUnit unit) {
    if (weight == null || !weight.hasRange) return '線上參考值';
    return '線上參考值 · 範圍 ${range(weight, unit)}';
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
                            subtitle: weight.hasRange
                                ? Text(
                                    '參考範圍 '
                                    '${WeightReferenceLabels.range(weight, widget.unit)}',
                                  )
                                : null,
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
Future<GearWeight?> showWeightReferencePicker(
  BuildContext context, {
  required GearWeight? generic,
  required List<GearWeight> variants,
  required WeightReferenceRepository references,
  required WeightUnit unit,
  String? selectedKey,
}) {
  return showModalBottomSheet<GearWeight>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final t = Theme.of(sheetContext).textTheme;
      final byBrand = <String, List<GearWeight>>{};
      for (final variant in variants) {
        byBrand.putIfAbsent(variant.brand ?? '其他', () => []).add(variant);
      }

      Widget inset(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: child,
      );

      Widget tile(GearWeight weight, {String? title}) {
        final selected = weight.key == selectedKey;
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
            title ?? weight.nameZh,
            style: selected
                ? const TextStyle(fontWeight: FontWeight.w500)
                : null,
          ),
          subtitle: weight.hasRange
              ? Text('參考範圍 ${WeightReferenceLabels.range(weight, unit)}')
              : null,
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
                WeightFormatters.gram(weight.weightGram, unit: unit),
                style: t.bodyMedium?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          onTap: () => Navigator.of(sheetContext).pop(weight),
        );
      }

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: Padding(
            // 型號列有選取底色,左右只留 sm;標題等文字另補 sm,與列內文字對齊。
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              0,
              AppSpacing.sm,
              AppSpacing.lg,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                inset(Text('帶入參考值', style: t.titleLarge)),
                if (variants.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  inset(Text('選品牌型號時，項目名稱會改成型號名。', style: t.bodySmall)),
                ],
                if (generic != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  tile(generic, title: '通用值（${generic.nameZh}）'),
                ],
                for (final MapEntry(key: brand, value: models)
                    in byBrand.entries) ...[
                  const SizedBox(height: AppSpacing.md),
                  inset(
                    Text(
                      brand,
                      style: t.bodySmall?.copyWith(
                        color: sheetContext.palette.textSecondary,
                      ),
                    ),
                  ),
                  for (final model in models) tile(model),
                ],
                const SizedBox(height: AppSpacing.md),
                inset(
                  Text(
                    WeightReferenceLabels.source(references),
                    style: t.bodySmall?.copyWith(
                      color: sheetContext.palette.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
