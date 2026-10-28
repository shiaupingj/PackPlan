import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/models/user_settings.dart';
import 'package:packplan/services/formatters.dart';

const nbsp = ' ';

void main() {
  test('kg 固定顯示 2 位小數,未滿 1 kg 顯示 g', () {
    expect(WeightFormatters.gram(1980), '1.98${nbsp}kg');
    expect(WeightFormatters.gram(4100), '4.10${nbsp}kg');
    expect(WeightFormatters.gram(2000), '2.00${nbsp}kg');
    expect(WeightFormatters.gram(1005), '1.00${nbsp}kg');
    expect(WeightFormatters.gram(999), '999${nbsp}g');
  });

  test('g 單位一律顯示整數克數', () {
    expect(WeightFormatters.gram(1980, unit: WeightUnit.gram), '1980${nbsp}g');
  });

  test('signedGram 正數加 +', () {
    expect(WeightFormatters.signedGram(1250), '+1.25${nbsp}kg');
    expect(WeightFormatters.signedGram(-300), '-300${nbsp}g');
  });
}
