import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_palette.dart';
import 'app_typography.dart';

/// 組合 design tokens 成 Flutter ThemeData。
///
/// 中性色（背景/表面/文字/邊框…）由 [AppPalette] 依模式帶入，
/// 品牌橘色與語意色（primary / tier / ink）維持固定。
abstract final class AppTheme {
  static ThemeData get dark => _build(AppPalette.dark);
  static ThemeData get light => _build(AppPalette.light);

  static ThemeData _build(AppPalette p) {
    final scheme =
        (p.brightness == Brightness.dark
                ? const ColorScheme.dark()
                : const ColorScheme.light())
            .copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              secondary: AppColors.primary,
              surface: p.surface,
              onSurface: p.textPrimary,
              error: p.weightOver,
            );

    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      scaffoldBackgroundColor: p.background,
      colorScheme: scheme,
      extensions: [p],
    );

    final textTheme = AppTypography.textTheme(
      primary: p.textPrimary,
      secondary: p.textSecondary,
    );

    return base.copyWith(
      textTheme: textTheme,
      dividerColor: p.border,
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.border, width: 0.8),
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge, // H2
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.border, width: 0.8),
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primary),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontFamilyFallback: AppTypography.fontFamilyFallback,
          color: p.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surfaceMuted,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surfaceMuted,
        dragHandleColor: p.textTertiary,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.border, width: 0.8),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: p.textPrimary,
        subtitleTextStyle: TextStyle(color: p.textSecondary),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: AppColors.primary,
        collapsedIconColor: p.textSecondary,
        textColor: p.textPrimary,
        collapsedTextColor: p.textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceElevated,
        contentTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontFamilyFallback: AppTypography.fontFamilyFallback,
          color: p.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.onPrimary
                : p.textPrimary,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: p.border)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(p.textPrimary),
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? AppColors.primary : p.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
