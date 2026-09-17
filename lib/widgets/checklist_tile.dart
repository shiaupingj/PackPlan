import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';

/// 清單項目：未完成＝深灰框，完成＝橘色勾 + 淡化刪除線文字。
class ChecklistTile extends StatelessWidget {
  const ChecklistTile({
    super.key,
    required this.label,
    required this.weightGram,
    this.weightLabel,
    this.showWeight = true,
    required this.checked,
    this.onChanged,
    this.onEdit,
    this.onLongPress,
    this.containerLabel,
    this.dimmed = false,
    this.badgeLabel,
    this.badgeFilled = false,
  });

  final String label;
  final int weightGram;
  final String? weightLabel;
  final bool showWeight;
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;
  final String? containerLabel;
  final bool dimmed;
  final String? badgeLabel;
  final bool badgeFilled;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: dimmed ? context.palette.surfaceMuted : Colors.transparent,
        border: dimmed
            ? const Border(left: BorderSide(color: AppColors.primary, width: 3))
            : null,
      ),
      child: InkWell(
        onTap: onEdit,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: checked ? '取消完成' : '標記完成',
                onPressed: onChanged == null
                    ? null
                    : () => onChanged!(!checked),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 40,
                ),
                icon: _circle(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: label),
                          if (showWeight) ...[
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: weightLabel ?? '${weightGram}g',
                              style: t.bodyMedium?.copyWith(
                                fontFamily: AppTypography.fontFamily,
                                fontFamilyFallback:
                                    AppTypography.fontFamilyFallback,
                              ),
                            ),
                          ],
                        ],
                      ),
                      style: t.bodyMedium?.copyWith(
                        color: checked || dimmed
                            ? context.palette.textTertiary
                            : null,
                        decoration: checked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (containerLabel != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '放在：$containerLabel',
                        style: t.bodySmall?.copyWith(
                          color: context.palette.textTertiary,
                        ),
                      ),
                    ],
                    if (badgeLabel != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeFilled
                              ? AppColors.primary
                              : Colors.transparent,
                          border: Border.all(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          badgeLabel!,
                          style: t.bodySmall?.copyWith(
                            color: badgeFilled
                                ? AppColors.ink
                                : AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(BuildContext context) {
    if (!checked) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.palette.border, width: 2),
        ),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: const Icon(Icons.check, size: 14, color: AppColors.ink),
    );
  }
}
