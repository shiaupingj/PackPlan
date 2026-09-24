/// 線上參考重量庫的一筆資料(Firestore `gear_weights/{key}`)。
///
/// 通用項目的 [key] 對應範本 key(如 `sleeping-bag`);品牌型號以 [parentKey]
/// 掛在通用項目下,[nameZh] 為完整型號名。
class GearWeight {
  const GearWeight({
    required this.key,
    required this.nameZh,
    required this.weightGram,
    required this.updatedAt,
    this.parentKey,
    this.brand,
    this.aliases = const [],
    this.categoryId,
    this.weightMin,
    this.weightMax,
    this.note,
    this.isActive = true,
  });

  final String key;
  final String nameZh;
  final String? parentKey;
  final String? brand;
  final List<String> aliases;
  final String? categoryId;

  /// 帶入值(典型值,公克)。
  final int weightGram;
  final int? weightMin;
  final int? weightMax;
  final String? note;
  final bool isActive;
  final DateTime updatedAt;

  bool get isVariant => parentKey != null;
  bool get hasRange => weightMin != null && weightMax != null;

  Map<String, Object?> toJson() => {
    'key': key,
    'nameZh': nameZh,
    'parentKey': parentKey,
    'brand': brand,
    'aliases': aliases,
    'categoryId': categoryId,
    'weightGram': weightGram,
    'weightMin': weightMin,
    'weightMax': weightMax,
    'note': note,
    'isActive': isActive,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory GearWeight.fromJson(Map<String, Object?> json) => GearWeight(
    key: json['key']! as String,
    nameZh: json['nameZh']! as String,
    parentKey: json['parentKey'] as String?,
    brand: json['brand'] as String?,
    aliases: (json['aliases'] as List<Object?>? ?? const [])
        .cast<String>()
        .toList(),
    categoryId: json['categoryId'] as String?,
    weightGram: json['weightGram']! as int,
    weightMin: json['weightMin'] as int?,
    weightMax: json['weightMax'] as int?,
    note: json['note'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    updatedAt: DateTime.parse(json['updatedAt']! as String),
  );
}
