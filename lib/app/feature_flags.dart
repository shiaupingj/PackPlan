import 'package:flutter/foundation.dart';

import '../models/pack_template.dart';

/// 上架版本的功能開關。
abstract final class FeatureFlags {
  /// Pro(內購)尚未串接:1.0 隱藏 Pro 範本與升級卡,
  /// 避免審核看到「稍後開放」的付費入口。串好內購再改成 true。
  static const pro = false;

  /// debug 版預覽 Pro 範本:列出且可直接選用,方便開發測試;
  /// release 版一律為 false。測試預設關閉(見 test/flutter_test_config.dart)。
  @visibleForTesting
  static bool debugPreviewPro = kDebugMode;

  /// 設定頁上方的「升級至 Pro」卡片;debug 預覽時也顯示。
  static bool get showProUpgrade => pro || debugPreviewPro;

  /// 範本頁與建立流程要列出的範本;Pro 未開放時不列 Pro 範本。
  static Iterable<PackTemplate> visibleTemplates(
    Iterable<PackTemplate> templates,
  ) => showProUpgrade
      ? templates
      : templates.where((template) => !template.proOnly);

  /// 範本是否鎖住(顯示鎖頭、不能選)。debug 預覽時全部可選。
  static bool isLocked(PackTemplate template) =>
      template.proOnly && !debugPreviewPro;
}
