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
    this.weightMissing = false,
    this.weightTooltip,
    required this.checked,
    this.onChanged,
    this.onEdit,
    this.onLongPress,
    this.dimmed = false,
    this.badgeLabel,
    this.badgeFilled = false,
  });

  final String label;
  final int weightGram;
  final String? weightLabel;
  final bool showWeight;

  /// 尚未填重量:以淡色「— g」取代 0 g。
  final bool weightMissing;

  /// 非 null 時在重量後加 ☁,點一下顯示此說明(線上參考值與範圍)。
  final String? weightTooltip;
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;
  final bool dimmed;
  final String? badgeLabel;
  final bool badgeFilled;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
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
          // 列高由 40pt 的勾選鈕撐開,上下只留 2pt,讓項目排得緊一點。
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
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
                // 不要撐到 Material 預設的 48 點擊區,列高才會是 40。
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: _circle(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名稱最多一行(過長以 … 截斷),重量與 ☁ 固定接在後面不被擠掉。
                    Builder(
                      builder: (context) {
                        final lineStyle = t.bodyMedium?.copyWith(
                          color: checked || dimmed
                              ? context.palette.textTertiary
                              : null,
                          decoration: checked
                              ? TextDecoration.lineThrough
                              : null,
                        );
                        return Row(
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                key: const ValueKey('checklist-tile-label'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: lineStyle,
                              ),
                            ),
                            if (showWeight) ...[
                              const SizedBox(width: 4),
                              Text(
                                weightMissing
                                    ? '—\u00A0g'
                                    : weightLabel ?? '${weightGram}g',
                                maxLines: 1,
                                style: lineStyle?.copyWith(
                                  fontFamily: AppTypography.fontFamily,
                                  fontFamilyFallback:
                                      AppTypography.fontFamilyFallback,
                                  color: weightMissing
                                      ? context.palette.textTertiary
                                      : null,
                                ),
                              ),
                              if (weightTooltip != null && !weightMissing)
                                Tooltip(
                                  message: weightTooltip,
                                  triggerMode: TooltipTriggerMode.tap,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.cloud_outlined,
                                      key: const ValueKey('weight-online-icon'),
                                      size: 16,
                                      color: checked || dimmed
                                          ? context.palette.textTertiary
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        );
                      },
                    ),
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
