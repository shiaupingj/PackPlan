import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/data/seed_data.dart';
import 'package:packplan/models/pack_list.dart';
import 'package:packplan/services/trip_formatters.dart';

void main() {
  test('summary separates title from trip metadata', () {
    final list = SeedData.lists().first;

    expect(TripFormatters.summary(list), '登山 · 3天2夜 · 雨天');
  });

  test('summary includes cloudy weather label', () {
    final list = SeedData.lists().first.copyWith(
      weatherConditions: {WeatherCondition.cloudy},
    );

    expect(TripFormatters.summary(list), '登山 · 3天2夜 · 陰天');
  });

  test('brief 只有類型與天數,不含天氣', () {
    final list = SeedData.lists().first;

    expect(TripFormatters.brief(list), '登山 · 3天2夜');
  });
}
