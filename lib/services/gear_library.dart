import '../models/gear_item.dart';
import '../models/pack_item.dart';

enum GearSort { mostUsed, recentlyUsed, heaviest, name }

/// 依排序方式排好裝備(不改動原清單)。
List<GearItem> sortGear(List<GearItem> gear, GearSort sort) {
  int byRecent(GearItem a, GearItem b) {
    final aTime = a.lastUsedAt ?? a.createdAt;
    final bTime = b.lastUsedAt ?? b.createdAt;
    return bTime.compareTo(aTime);
  }

  return [...gear]..sort(
    (a, b) => switch (sort) {
      GearSort.mostUsed => switch (b.usageCount.compareTo(a.usageCount)) {
        0 => byRecent(a, b),
        final result => result,
      },
      GearSort.recentlyUsed => byRecent(a, b),
      GearSort.heaviest => b.weightGram.compareTo(a.weightGram),
      GearSort.name => a.name.compareTo(b.name),
    },
  );
}

/// 依分類分組;分類順序照排序後第一次出現的位置。
Map<String, List<GearItem>> groupGearByCategory(List<GearItem> gear) {
  final groups = <String, List<GearItem>>{};
  for (final item in gear) {
    groups.putIfAbsent(item.categoryName, () => []).add(item);
  }
  return groups;
}

String gearSortLabel(GearSort sort) => switch (sort) {
  GearSort.mostUsed => '最常用',
  GearSort.recentlyUsed => '最近用',
  GearSort.heaviest => '重量高→低',
  GearSort.name => '名稱',
};

/// 裝備的副標:使用次數、放置位置與容器標記。
String gearSubtitle(GearItem gear) => [
  gear.usageCount == 0 ? '還沒用過' : '用過 ${gear.usageCount} 次',
  if (gear.weightClass == WeightClass.worn) '穿戴',
  if (gear.weightClass == WeightClass.vehicle) '車上',
  if (gear.isContainer) '容器',
].join(' · ');
