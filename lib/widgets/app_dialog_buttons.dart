import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';

/// 對話框底部按鈕共用樣式(以「編輯項目」為準):
/// 圓角 [AppRadius.dialogButton];取消為灰底主文字色,確認為橘底實心。
RoundedRectangleBorder get _dialogButtonShape => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(AppRadius.dialogButton),
);

/// 對話框的「取消」:灰底(surfaceElevated)+ 主文字色。
class AppDialogCancelButton extends StatelessWidget {
  const AppDialogCancelButton({
    super.key,
    required this.onPressed,
    this.label = '取消',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: context.palette.surfaceElevated,
        foregroundColor: context.palette.textPrimary,
        shape: _dialogButtonShape,
      ),
      child: Text(label),
    );
  }
}

/// 對話框的主要動作(儲存、確認…);[destructive] 時改用紅底(刪除、重建等)。
class AppDialogConfirmButton extends StatelessWidget {
  const AppDialogConfirmButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.destructive = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: destructive ? AppColors.weightOver : null,
        foregroundColor: destructive ? AppColors.onWeightOver : null,
        shape: _dialogButtonShape,
      ),
      child: Text(label),
    );
  }
}

/// 對話框左側的次要文字按鈕(例如編輯框裡的「刪除」):橘色文字、無底色。
class AppDialogTextButton extends StatelessWidget {
  const AppDialogTextButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(shape: _dialogButtonShape),
      child: Text(label),
    );
  }
}
