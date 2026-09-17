import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 字型方案：
/// - 主要字型：Roboto（本地打包 assets/fonts）
/// - 中文 fallback：Noto Sans TC（繁中子集，本地打包）
/// 中英混排時 Roboto 缺中文字元，fallback 到 Noto Sans TC。
/// 全系統只用兩種字重：400 (regular) / 500 (medium)。
abstract final class AppTypography {
  static const String fontFamily = 'Roboto';
  static const List<String> fontFamilyFallback = ['Noto Sans TC'];

  static TextStyle _heading(double size) => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w400,
    height: 1.08,
    color: AppColors.textPrimary,
  ).copyWith(fontSize: size);

  static TextStyle _body(double size, {FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: size,
        fontWeight: weight,
        height: 1.42,
        color: AppColors.textPrimary,
      );

  /// 套進 ThemeData 的 TextTheme。
  static TextTheme get textTheme => TextTheme(
    displayLarge: _heading(48),
    headlineMedium: _heading(34), // H1
    titleLarge: _heading(22), // H2
    titleMedium: _body(17, weight: FontWeight.w500),
    bodyLarge: _body(16),
    bodyMedium: _body(15),
    bodySmall: _body(13).copyWith(color: AppColors.textSecondary), // caption
    labelLarge: _body(15, weight: FontWeight.w500), // 按鈕文字
  );
}
