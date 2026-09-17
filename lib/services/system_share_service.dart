import 'package:flutter/services.dart';

abstract final class SystemShareService {
  static const MethodChannel _channel = MethodChannel(
    'com.packplan.packplan/system_share',
  );

  static Future<void> shareText({
    required String text,
    required String subject,
  }) async {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'Share text cannot be empty.');
    }
    await _channel.invokeMethod<void>('shareText', {
      'text': text,
      'subject': subject,
    });
  }
}
