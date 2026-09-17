import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// UL 等級。color/onColor 由等級決定。
enum UlTier {
  beginner('偏重', AppColors.tierBeginner, Colors.white),
  light('輕量', AppColors.tierLight, Colors.white),
  smart('聰明打包', AppColors.tierSmart, AppColors.ink),
  ul('超輕量', AppColors.tierUL, AppColors.ink),
  minimalist('極簡', AppColors.tierMinimalist, AppColors.ink);

  const UlTier(this.label, this.color, this.onColor);

  final String label;
  final Color color;
  final Color onColor;
}

/// 膠囊形等級標籤，用於清單卡 / 分享卡 / 等級頁。
class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.tier, this.icon = '🪶'});

  final UlTier tier;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tier.color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$icon ${tier.label}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: tier.onColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
