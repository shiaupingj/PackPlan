import '../models/pack_template.dart';

/// 上架版本的功能開關。
abstract final class FeatureFlags {
  /// Pro(內購)尚未串接:1.0 隱藏 Pro 範本與升級卡,
  /// 避免審核看到「稍後開放」的付費入口。串好內購再改成 true。
  static const pro = false;

  /// 範本頁與建立流程要列出的範本;Pro 未開放時不列 Pro 範本。
  static Iterable<PackTemplate> visibleTemplates(
    Iterable<PackTemplate> templates,
  ) => pro ? templates : templates.where((template) => !template.proOnly);
}
