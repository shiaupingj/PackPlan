import 'package:flutter/material.dart';

import '../models/user_settings.dart';
import '../services/formatters.dart';
import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

class WeightText extends StatelessWidget {
  const WeightText({
    super.key,
    required this.gram,
    required this.unit,
    this.prefix = '',
    this.style,
    this.color,
    this.fontWeight,
  });

  final int gram;
  final WeightUnit unit;
  final String prefix;
  final TextStyle? style;
  final Color? color;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;

    return Text(
      '$prefix${WeightFormatters.gram(gram, unit: unit)}',
      style: (baseStyle ?? const TextStyle()).copyWith(
        fontFamily: AppTypography.fontFamily,
        fontFamilyFallback: AppTypography.fontFamilyFallback,
        color: color ?? baseStyle?.color ?? context.palette.textPrimary,
        fontWeight: fontWeight ?? baseStyle?.fontWeight,
      ),
    );
  }
}
