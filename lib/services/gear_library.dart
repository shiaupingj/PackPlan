import '../models/gear_item.dart';
import '../models/pack_item.dart';

enum GearSort { custom, mostUsed, recentlyUsed, heaviest, name }

/// 依排序方式排好裝備(不改動原清單)。
List<GearItem> sortGear(List<GearItem> gear, GearSort sort) {
  int byRecent(GearItem a, GearItem b) {
    final aTime = a.lastUsedAt ?? a.createdAt;
    final bTime = b.lastUsedAt ?? b.createdAt;
    return bTime.compareTo(aTime);
  }

  // 自訂順序就是裝備庫本身的順序(拖曳調整、新裝備排最後)。
  if (sort == GearSort.custom) return [...gear];
  return [...gear]..sort(
    (a, b) => switch (sort) {
      GearSort.custom => 0,
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
  GearSort.custom => '自訂順序',
  GearSort.mostUsed => '最常用',
  GearSort.recentlyUsed => '最近用',
  GearSort.heaviest => '重量高→低',
  GearSort.name => '名稱',
};

/// 裝備的副標:放置位置與容器標記;都沒有時是空字串。
String gearSubtitle(GearItem gear) => [
  if (gear.weightClass == WeightClass.worn) '穿戴',
  if (gear.weightClass == WeightClass.vehicle) '車上',
  if (gear.isContainer) '容器',
].join(' · ');
