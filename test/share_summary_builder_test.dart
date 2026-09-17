import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/data/seed_data.dart';
import 'package:packplan/models/user_settings.dart';
import 'package:packplan/services/share_summary_builder.dart';

void main() {
  const nbsp = '\u00A0';

  test('share summary includes core weight and progress details', () {
    final list = SeedData.lists().first;

    final summary = ShareSummaryBuilder.text(list, unit: WeightUnit.gram);

    expect(summary, contains('PackPlan 登山計劃'));
    expect(summary, contains('登山 · 3天2夜 · 雨天'));
    expect(summary, contains('總重 4120${nbsp}g'));
    expect(summary, contains('上限 7000${nbsp}g'));
    expect(summary, contains('進度 2/8 已打包'));
    expect(summary, contains('超輕量化打包建議'));
  });

  test('share summary omits weight details when the list hides weight', () {
    final list = SeedData.lists().first.copyWith(showWeight: false);

    final summary = ShareSummaryBuilder.text(list);

    expect(summary, isNot(contains('總重')));
    expect(summary, isNot(contains('上限')));
    expect(summary, isNot(contains('超輕量化打包建議')));
    expect(summary, contains('進度'));
  });
}
