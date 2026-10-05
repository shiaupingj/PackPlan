import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// 使用者回報用的信箱與信件內容。
abstract final class SupportMail {
  static const address = 'appspdoit@gmail.com';

  /// 參考重量庫找不到物品時的回報信:主旨帶搜尋字,內文預留品牌/型號/重量欄位。
  static Uri missingWeightReference({
    required String query,
    String? categoryName,
  }) {
    final item = query.trim();
    final category = categoryName?.trim() ?? '';
    return _mailto(
      subject: 'PackPlan 參考重量找不到：$item',
      body: [
        '物品名稱：$item',
        if (category.isNotEmpty) '分類：$category',
        '品牌／型號：',
        '重量（知道的話）：',
        '',
        '其他說明：',
      ].join('\n'),
    );
  }

  /// 用系統預設的郵件 App 開啟;沒有可用的郵件 App 時回傳 false。
  static Future<bool> open(Uri uri) async {
    try {
      return await launcher(uri);
    } on Object {
      return false;
    }
  }

  /// 實際開啟連結的函式;測試替換成假的,不碰平台外掛。
  @visibleForTesting
  static Future<bool> Function(Uri uri) launcher = _launchExternal;

  static Future<bool> _launchExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  // mailto 的空白要編成 %20,不能用 Uri(queryParameters:) 產生的「+」。
  static Uri _mailto({required String subject, required String body}) {
    return Uri.parse(
      'mailto:$address'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );
  }
}
