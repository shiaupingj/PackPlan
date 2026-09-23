/// 間距、圓角、尺寸 tokens。
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// 浮動導覽膠囊的高度含底部留白，捲動內容底部保留此空間以免被擋住。
  static const double navBarClearance = 100;
}

abstract final class AppRadius {
  static const double sm = 2;
  static const double md = 3;
  static const double lg = 4; // 卡片
  static const double pill = 4; // CTA
}
