enum ItemNecessity { required, optional, luxury }

enum WeightClass { packed, worn }

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
    );
  }
}
