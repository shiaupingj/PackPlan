import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/widgets/weight_bar.dart';

void main() {
  testWidgets('near-limit weight shows remaining capacity', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WeightBar(currentGram: 9000, limitGram: 10000)),
      ),
    );

    expect(find.textContaining('接近重量上限'), findsOneWidget);
    expect(find.textContaining('1.0'), findsOneWidget);
  });

  testWidgets('over-limit weight shows the excess amount', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WeightBar(currentGram: 11000, limitGram: 10000)),
      ),
    );

    expect(find.textContaining('已超重'), findsOneWidget);
    expect(find.textContaining('1.0'), findsOneWidget);
  });
}
