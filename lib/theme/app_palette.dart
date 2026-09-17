import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 會隨「深色 / 淺色」模式變動的語意色 tokens。
///
/// 對照 Figma「PackPlan Color」collection 的 Dark / Light 兩個 mode。
/// 品牌橘色、tier 色、ink 等在兩個模式相同的色，仍放在 [AppColors] 常數，
/// 不進這裡。透過 `context.palette.xxx` 取用，主題切換時自動生效。
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.trackMuted,
    required this.weightNear,
    required this.weightOver,
    required this.onTextPrimary,
    required this.brightness,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color trackMuted;
  final Color weightNear;
  final Color weightOver;

  /// 疊在 [textPrimary] 色塊上的前景色（例如白底黑字按鈕的文字）。
  /// 深色模式下 textPrimary 為亮色 → 前景用 ink；淺色模式反轉為白。
  final Color onTextPrimary;

  final Brightness brightness;

  /// 深色模式（Figma Dark mode）。
  static const AppPalette dark = AppPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceElevated: AppColors.surfaceElevated,
    surfaceMuted: AppColors.surfaceMuted,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    border: AppColors.border,
    trackMuted: AppColors.trackMuted,
    weightNear: AppColors.weightNear,
    weightOver: AppColors.weightOver,
    onTextPrimary: AppColors.ink,
    brightness: Brightness.dark,
  );

  /// 淺色模式（Figma Light mode）。
  static const AppPalette light = AppPalette(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    surfaceMuted: AppColors.lightSurfaceMuted,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    border: AppColors.lightBorder,
    trackMuted: AppColors.lightTrackMuted,
    weightNear: AppColors.lightWeightNear,
    weightOver: AppColors.lightWeightOver,
    onTextPrimary: AppColors.lightSurface,
    brightness: Brightness.light,
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? trackMuted,
    Color? weightNear,
    Color? weightOver,
    Color? onTextPrimary,
    Brightness? brightness,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      trackMuted: trackMuted ?? this.trackMuted,
      weightNear: weightNear ?? this.weightNear,
      weightOver: weightOver ?? this.weightOver,
      onTextPrimary: onTextPrimary ?? this.onTextPrimary,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      trackMuted: Color.lerp(trackMuted, other.trackMuted, t)!,
      weightNear: Color.lerp(weightNear, other.weightNear, t)!,
      weightOver: Color.lerp(weightOver, other.weightOver, t)!,
      onTextPrimary: Color.lerp(onTextPrimary, other.onTextPrimary, t)!,
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

/// 便捷取用：`context.palette.surface`。
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
