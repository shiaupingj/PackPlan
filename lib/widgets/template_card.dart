import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';

/// 範本卡(範本頁與建立清單 Step 1 共用)。
///
/// - 可用:反白(text-primary 底、背景色字),與主要按鈕同一套配色。
/// - 選中(Step 1):橘底 ink 字 + 勾。
/// - 鎖定(Pro):一般卡片底 + 鎖頭。
class TemplateCard extends StatelessWidget {
  const TemplateCard({
    super.key,
    required this.name,
    required this.description,
    required this.locked,
    this.selected = false,
    this.onTap,
  });

  final String name;
  final String description;
  final bool locked;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final palette = context.palette;
    final (background, foreground, secondary) = switch ((locked, selected)) {
      (true, _) => (
        palette.surface,
        palette.textPrimary,
        palette.textSecondary,
      ),
      (false, true) => (AppColors.primary, AppColors.ink, AppColors.ink),
      (false, false) => (
        palette.textPrimary,
        palette.onTextPrimary,
        palette.onTextPrimary,
      ),
    };

    return Card(
      color: background,
      // 反白卡片的框線與底色同色,不另外畫灰框。
      shape: locked
          ? null
          : RoundedRectangleBorder(
              side: BorderSide(color: background, width: 0.8),
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.lg),
              ),
            ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        title: Text(name, style: t.titleMedium?.copyWith(color: foreground)),
        subtitle: Text(
          description,
          style: t.bodySmall?.copyWith(color: secondary),
        ),
        trailing: Icon(
          locked
              ? Icons.lock_outline
              : selected
              ? Icons.check_circle
              : Icons.chevron_right,
          color: locked ? palette.textSecondary : foreground,
        ),
      ),
    );
  }
}
