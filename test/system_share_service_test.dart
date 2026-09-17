import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/services/system_share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.packplan.packplan/system_share');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'shareText sends text and subject to the native share channel',
    () async {
      MethodCall? receivedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            receivedCall = call;
            return null;
          });

      await SystemShareService.shareText(
        text: 'PackPlan 測試清單',
        subject: '測試清單',
      );

      expect(receivedCall?.method, 'shareText');
      expect(receivedCall?.arguments, {
        'text': 'PackPlan 測試清單',
        'subject': '測試清單',
      });
    },
  );

  test('shareText rejects empty content before calling the platform', () async {
    await expectLater(
      SystemShareService.shareText(text: '  ', subject: '測試'),
      throwsArgumentError,
    );
  });
}
