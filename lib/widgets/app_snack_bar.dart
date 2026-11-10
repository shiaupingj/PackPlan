import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// SnackBar 的語氣:決定底色與左側圖示。
enum AppSnackTone {
  /// 動作完成(橘底黑字 + 打勾)。
  success,

  /// 單純告知(橘底黑字 + 資訊圖示)。
  info,

  /// 失敗或輸入有誤(紅底白字 + 驚嘆號)。
  error,
}

/// 全 App 共用的整塊色底 SnackBar。
///
/// 給了 [actionLabel] 與 [onAction] 時右側多一顆文字按鈕(例如「復原」)。
SnackBar appSnackBar(
  String message, {
  AppSnackTone tone = AppSnackTone.success,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
  bool showCloseIcon = false,
}) {
  final isError = tone == AppSnackTone.error;
  final background = isError ? AppColors.weightOver : AppColors.primary;
  final foreground = isError ? Colors.white : AppColors.ink;
  final icon = switch (tone) {
    AppSnackTone.success => Icons.check_circle_outline,
    AppSnackTone.info => Icons.info_outline,
    AppSnackTone.error => Icons.error_outline,
  };
  return SnackBar(
    backgroundColor: background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: duration,
    showCloseIcon: showCloseIcon,
    closeIconColor: foreground,
    // 有動作按鈕時 Flutter 預設不會自動消失,這裡明確設成時間到就關。
    persist: false,
    action: actionLabel != null && onAction != null
        ? SnackBarAction(
            label: actionLabel,
            textColor: foreground,
            onPressed: onAction,
          )
        : null,
    content: Row(
      children: [
        Icon(icon, size: 20, color: foreground),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(message, style: TextStyle(color: foreground)),
        ),
      ],
    ),
  );
}
