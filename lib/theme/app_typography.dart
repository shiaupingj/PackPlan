import 'package:flutter/material.dart';

/// 字型方案：
/// - 主要字型：Roboto（本地打包 assets/fonts）
/// - 中文 fallback：Noto Sans TC（繁中子集，本地打包）
/// 中英混排時 Roboto 缺中文字元，fallback 到 Noto Sans TC。
/// 全系統只用兩種字重：400 (regular) / 500 (medium)。
abstract final class AppTypography {
  static const String fontFamily = 'Roboto';
  static const List<String> fontFamilyFallback = ['Noto Sans TC'];

  static TextStyle _heading(double size, Color color) => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w400,
    height: 1.08,
    color: color,
    fontSize: size,
  );

  static TextStyle _body(
    double size,
    Color color, {
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: size,
    fontWeight: weight,
    height: 1.42,
    color: color,
  );

  /// 套進 ThemeData 的 TextTheme（依模式帶入主要/次要文字色）。
  /// Material 元件會用到的欄位都要帶顏色：沒定義的欄位只剩字級、沒有顏色，
  /// 會被畫成預設白字（例如對話框標題預設用 headlineSmall）。
  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) => TextTheme(
    displayLarge: _heading(48, primary),
    headlineMedium: _heading(34, primary), // H1
    headlineSmall: _heading(24, primary),
    titleLarge: _heading(22, primary), // H2
    titleMedium: _body(17, primary, weight: FontWeight.w500),
    titleSmall: _body(15, primary, weight: FontWeight.w500),
    bodyLarge: _body(16, primary),
    bodyMedium: _body(15, primary),
    bodySmall: _body(13, secondary), // caption
    labelLarge: _body(15, primary, weight: FontWeight.w500), // 按鈕文字
    labelMedium: _body(13, primary, weight: FontWeight.w500),
    labelSmall: _body(11, secondary, weight: FontWeight.w500),
  );
}
