import 'pack_item.dart';

/// 「我的裝備」裡的一件裝備:使用者層級、跨清單共用。
///
/// 加入清單時把名稱、重量複製成 [PackItem](快照),之後改裝備庫不會回溯既有清單。
class GearItem {
  const GearItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.weightGram,
    required this.createdAt,
    required this.updatedAt,
    this.weightClass = WeightClass.packed,
    this.isContainer = false,
    this.catalogKey,
    this.usageCount = 0,
    this.lastUsedAt,
  });

  static const Object _unset = Object();

  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final int weightGram;

  /// 加入清單時的預設放置位置:背包內、身上穿戴或放車上。
  final WeightClass weightClass;
  final bool isContainer;

  /// 對應的範本項目(如 `sleeping-bag`),用來和範本精準配對;自訂裝備為 null。
  final String? catalogKey;

  /// 被加入清單的次數與最後一次加入的時間,用來排序「最常用 / 最近用」。
  final int usageCount;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  GearItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? categoryName,
    int? weightGram,
    WeightClass? weightClass,
    bool? isContainer,
    Object? catalogKey = _unset,
    int? usageCount,
    Object? lastUsedAt = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GearItem(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      weightGram: weightGram ?? this.weightGram,
      weightClass: weightClass ?? this.weightClass,
      isContainer: isContainer ?? this.isContainer,
      catalogKey: identical(catalogKey, _unset)
          ? this.catalogKey
          : catalogKey as String?,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: identical(lastUsedAt, _unset)
          ? this.lastUsedAt
          : lastUsedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
