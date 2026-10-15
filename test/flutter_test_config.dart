import 'dart:async';

import 'package:packplan/app/feature_flags.dart';

/// 所有測試共用的設定(flutter_test 會自動套用)。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // 測試跑在 debug 模式;預設關掉 Pro 預覽,讓測試照 release 版的行為跑。
  // 要測預覽的測試自己打開(見 feature_flags_test.dart)。
  FeatureFlags.debugPreviewPro = false;
  await testMain();
}
