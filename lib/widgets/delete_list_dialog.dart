import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_dialog_title.dart';

/// 刪除整份清單前的確認框。首頁長按選單、首頁滑動刪除、清單內頁「⋯」選單共用。
///
/// 回傳 true 才代表使用者確認刪除；取消、點 × 或點外面都回傳 false。
Future<bool> confirmDeleteList(BuildContext context, String title) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        titlePadding: AppDialogTitle.padding,
        title: const AppDialogTitle('刪除清單？'),
        content: Text('「$title」刪除後無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.weightOver,
              foregroundColor: AppColors.onWeightOver,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('刪除'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
