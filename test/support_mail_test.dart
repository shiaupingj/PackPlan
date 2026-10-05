import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/services/support_mail.dart';

void main() {
  test('找不到物品的回報信:收件人、主旨與內文', () {
    final uri = SupportMail.missingWeightReference(
      query: ' 健行雨傘 ',
      categoryName: '個人物品',
    );

    expect(uri.scheme, 'mailto');
    expect(uri.path, 'appspdoit@gmail.com');
    expect(uri.queryParameters['subject'], 'PackPlan 參考重量找不到：健行雨傘');
    final body = uri.queryParameters['body']!;
    expect(body, contains('物品名稱：健行雨傘'));
    expect(body, contains('分類：個人物品'));
    expect(body, contains('品牌／型號：'));
    // 郵件 App 不認得「+」當空白,要用 %20。
    expect(uri.toString(), isNot(contains('+')));
  });

  test('沒有分類時內文不放分類欄', () {
    final uri = SupportMail.missingWeightReference(query: '登山扣');
    expect(uri.queryParameters['body'], isNot(contains('分類：')));
  });
}
