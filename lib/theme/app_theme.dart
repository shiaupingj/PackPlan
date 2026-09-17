import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// 組合 design tokens 成 Flutter ThemeData（黑底橘色版）。
abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.weightOver,
      ),
    );

    return base.copyWith(
      textTheme: AppTypography.textTheme,
      dividerColor: AppColors.border,
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border, width: 0.8),
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border, width: 0.8),
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.primary),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontFamilyFallback: AppTypography.fontFamilyFallback,
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceMuted,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surfaceMuted,
        dragHandleColor: AppColors.textTertiary,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border, width: 0.8),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimary,
        subtitleTextStyle: TextStyle(color: AppColors.textSecondary),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        collapsedTextColor: AppColors.textPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        elevation: 0,
        indicatorColor: AppColors.surfaceElevated,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textTertiary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontFamilyFallback: AppTypography.fontFamilyFallback,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontFamilyFallback: AppTypography.fontFamilyFallback,
          color: AppColors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.textPrimary),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
