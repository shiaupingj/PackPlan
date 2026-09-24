enum ItemNecessity { required, optional, luxury }

enum WeightClass { packed, worn }

/// 重量數值的來源:[unset] 尚未填(範本預設 0g)、[manual] 使用者自填、
/// [online] 由線上參考重量庫帶入。
enum WeightSource { unset, manual, online }

class PackItem {
  const PackItem({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.weightGram,
    required this.quantity,
    required this.checked,
    required this.necessity,
    required this.sortOrder,
    this.weightClass = WeightClass.packed,
    this.isContainer = false,
    this.containerItemId,
    this.weightSource = WeightSource.manual,
    this.catalogKey,
  });

  static const Object _unset = Object();

  final String id;
  final String categoryId;
  final String categoryName;
  final String name;
  final int weightGram;
  final int quantity;
  final bool checked;
  final ItemNecessity necessity;
  final int sortOrder;
  final WeightClass weightClass;
  final bool isContainer;
  final String? containerItemId;
  final WeightSource weightSource;

  /// 範本項目的穩定識別碼(如 `sleeping-bag`),用來對應線上參考重量;自訂項目為 null。
  final String? catalogKey;

  bool get isWeightMissing => weightSource == WeightSource.unset;

  int get totalWeightGram => weightGram * quantity;

  PackItem copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    String? name,
    int? weightGram,
    int? quantity,
    bool? checked,
    ItemNecessity? necessity,
    int? sortOrder,
    WeightClass? weightClass,
    bool? isContainer,
    Object? containerItemId = _unset,
    WeightSource? weightSource,
    Object? catalogKey = _unset,
  }) {
    return PackItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      weightGram: weightGram ?? this.weightGram,
      quantity: quantity ?? this.quantity,
      checked: checked ?? this.checked,
      necessity: necessity ?? this.necessity,
      sortOrder: sortOrder ?? this.sortOrder,
      weightClass: weightClass ?? this.weightClass,
      isContainer: isContainer ?? this.isContainer,
      containerItemId: identical(containerItemId, _unset)
          ? this.containerItemId
          : containerItemId as String?,
      weightSource: weightSource ?? this.weightSource,
      catalogKey: identical(catalogKey, _unset)
          ? this.catalogKey
          : catalogKey as String?,
    );
  }
}
