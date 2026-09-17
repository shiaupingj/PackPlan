import 'package:flutter/material.dart' show ThemeMode;

enum WeightUnit { kg, gram }

class UserSettings {
  const UserSettings({
    this.weightUnit = WeightUnit.kg,
    this.defaultWeightLimitGram = 7000,
    this.themeMode = ThemeMode.system,
  });

  final WeightUnit weightUnit;
  final int defaultWeightLimitGram;

  /// 外觀：淺色 / 深色 / 跟隨系統。
  final ThemeMode themeMode;

  UserSettings copyWith({
    WeightUnit? weightUnit,
    int? defaultWeightLimitGram,
    ThemeMode? themeMode,
  }) {
    return UserSettings(
      weightUnit: weightUnit ?? this.weightUnit,
      defaultWeightLimitGram:
          defaultWeightLimitGram ?? this.defaultWeightLimitGram,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
