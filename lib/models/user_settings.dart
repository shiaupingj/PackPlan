enum WeightUnit { kg, gram }

class UserSettings {
  const UserSettings({
    this.weightUnit = WeightUnit.kg,
    this.defaultWeightLimitGram = 7000,
  });

  final WeightUnit weightUnit;
  final int defaultWeightLimitGram;

  UserSettings copyWith({WeightUnit? weightUnit, int? defaultWeightLimitGram}) {
    return UserSettings(
      weightUnit: weightUnit ?? this.weightUnit,
      defaultWeightLimitGram:
          defaultWeightLimitGram ?? this.defaultWeightLimitGram,
    );
  }
}
