import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';

/// [showCategoryPicker] 選了「新增分類」時回傳的值。
const categoryPickerAddValue = '__add_category__';

/// 從底部滑出的分類面板:用標籤挑分類,最後一顆是「新增分類」。
///
/// 回傳選到的分類名稱、[categoryPickerAddValue],或 null(沒選就關掉)。
/// 分類有十幾個時下拉選單太長,清單項目與我的裝備的編輯器都用這個面板。
Future<String?> showCategoryPicker(
  BuildContext context, {
  required List<String> names,
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final palette = sheetContext.palette;
      return SafeArea(
        child: SingleChildScrollView(
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
              Text('選擇分類', style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final name in names)
                    ChoiceChip(
                      key: ValueKey('category-chip-$name'),
                      label: Text(name),
                      selected: name == selected,
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: name == selected
                            ? AppColors.ink
                            : palette.textPrimary,
                      ),
                      side: BorderSide(
                        color: name == selected
                            ? AppColors.primary
                            : palette.border,
                      ),
                      onSelected: (_) => Navigator.of(sheetContext).pop(name),
                    ),
                  ActionChip(
                    key: const ValueKey('category-chip-add'),
                    avatar: Icon(
                      Icons.add,
                      size: 18,
                      color: palette.textPrimary,
                    ),
                    label: const Text('新增分類'),
                    side: BorderSide(color: palette.border),
                    onPressed: () =>
                        Navigator.of(sheetContext).pop(categoryPickerAddValue),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
