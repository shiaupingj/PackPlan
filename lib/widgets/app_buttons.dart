import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';

/// 主要 CTA：白底黑字，icon 與文字同色。
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: context.palette.textPrimary,
          foregroundColor: context.palette.onTextPrimary,
          disabledBackgroundColor: context.palette.surfaceElevated,
          disabledForegroundColor: context.palette.textTertiary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        child: _content(),
      ),
    );
  }

  Widget _content() {
    if (icon == null) return Text(label);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 不指定顏色:沿用按鈕的前景色(含停用狀態)。
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(label),
      ],
    );
  }
}

/// 次要 CTA：深灰底，適合次要操作。
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: context.palette.surfaceElevated,
          foregroundColor: context.palette.textPrimary,
          side: BorderSide(color: context.palette.border, width: 0.5),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        child: Text(label),
      ),
    );
  }
}
