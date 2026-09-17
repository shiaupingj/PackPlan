import 'package:flutter/material.dart';

/// PackPlan 色彩 tokens — v5「黑底 / 橘色 / 深灰」。
///
/// 命名規則：色階以 50（最淺）→ 900（最深）為梯度，
/// 語意色（weight / tier）獨立命名，避免和品牌主色混用。
abstract final class AppColors {
  // ── Primary：橘色 action 色階 ─────────────────────────────
  static const Color orange50 = Color(0xFFFFF1E5);
  static const Color orange100 = Color(0xFFFFD4B0);
  static const Color orange300 = Color(0xFFFF9C3A);
  static const Color orange500 = Color(0xFFFF6B00);
  static const Color orange700 = Color(0xFFD65300);
  static const Color orange900 = Color(0xFF351500);

  static const Color primary = orange500;
  static const Color onPrimary = ink;

  // ── Ink / 中性色 ──────────────────────────────────────────
  static const Color ink = Color(0xFF050505);
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF252525);
  static const Color surfaceElevated = Color(0xFF303030);
  static const Color surfaceMuted = Color(0xFF171717);
  static const Color textPrimary = Color(0xFFF4F4F4);
  static const Color textSecondary = Color(0xFFB5B5B5);
  static const Color textTertiary = Color(0xFF777777);
  static const Color border = Color(0xFF3A3A3A);
  static const Color trackMuted = Color(0xFF5B5F60);

  // ── 重量狀態（語意色）────────────────────────────────────
  static const Color weightOk = orange500;
  static const Color weightNear = Color(0xFFFFA629); // 接近上限
  static const Color weightOver = Color(0xFFE5484D); // 超重
  static const Color onWeightOk = orange900;
  static const Color onWeightNear = Color(0xFF412402);
  static const Color onWeightOver = Color(0xFFFFFFFF);

  // ── UL 等級色階 ─────────────────────────────────────────
  static const Color tierBeginner = Color(0xFF6D6D6D);
  static const Color tierLight = Color(0xFFB46B2A);
  static const Color tierSmart = Color(0xFFFF8A1F);
  static const Color tierUL = orange500;
  static const Color tierMinimalist = Color(0xFFF4F4F4);

  // 舊命名保留給既有元件參照，實際色系已改為橘色。
  static const Color limE50 = orange50;
  static const Color lime100 = orange100;
  static const Color lime300 = orange300;
  static const Color lime500 = orange500;
  static const Color lime700 = orange700;
  static const Color lime900 = orange900;
}
