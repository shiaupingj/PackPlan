import 'pack_item.dart';

enum TripType { hiking, city, camping }

enum WeatherCondition { sunny, cloudy, rainy, cold }

class PackList {
  const PackList({
    required this.id,
    required this.title,
    required this.tripType,
    required this.days,
    required this.nights,
    required this.weatherConditions,
    required this.weightLimitGram,
    this.showWeight = true,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final TripType tripType;
  final int days;
  final int nights;
  final Set<WeatherCondition> weatherConditions;
  final int weightLimitGram;
  final bool showWeight;
  final List<PackItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeatherCondition get weather => weatherConditions.first;

  int get totalWeightGram => items
      .where((item) => item.weightClass != WeightClass.worn)
      .fold(0, (total, item) => total + item.totalWeightGram);

  int get baseWeightGram => items
      .where((item) => item.weightClass == WeightClass.packed)
      .fold(0, (total, item) => total + item.totalWeightGram);

  int get wornWeightGram => items
      .where((item) => item.weightClass == WeightClass.worn)
      .fold(0, (total, item) => total + item.totalWeightGram);

  int get skinOutWeightGram => totalWeightGram + wornWeightGram;

  int get packedWeightGram => items
      .where((item) => item.checked)
      .where((item) => item.weightClass != WeightClass.worn)
      .fold(0, (total, item) => total + item.totalWeightGram);

  int get checkedCount => items.where((item) => item.checked).length;

  double get progress => items.isEmpty ? 0 : checkedCount / items.length;

  double get baseWeightKg => baseWeightGram / 1000;

  PackList copyWith({
    String? id,
    String? title,
    TripType? tripType,
    int? days,
    int? nights,
    Set<WeatherCondition>? weatherConditions,
    int? weightLimitGram,
    bool? showWeight,
    List<PackItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PackList(
      id: id ?? this.id,
      title: title ?? this.title,
      tripType: tripType ?? this.tripType,
      days: days ?? this.days,
      nights: nights ?? this.nights,
      weatherConditions: weatherConditions ?? this.weatherConditions,
      weightLimitGram: weightLimitGram ?? this.weightLimitGram,
      showWeight: showWeight ?? this.showWeight,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
