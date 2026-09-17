import '../services/weight_calculator.dart';
import '../widgets/tier_badge.dart';

extension PackWeightTierMapper on PackWeightTier {
  UlTier get uiTier {
    return switch (this) {
      PackWeightTier.beginner => UlTier.beginner,
      PackWeightTier.light => UlTier.light,
      PackWeightTier.smart => UlTier.smart,
      PackWeightTier.ul => UlTier.ul,
      PackWeightTier.minimalist => UlTier.minimalist,
    };
  }
}
