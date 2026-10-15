import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 當機回報(Sentry)。
///
/// 只在 release 版啟用;debug 與測試完全不連 Sentry,也不耗免費額度。
/// DSN 是公開的用戶端金鑰(不是密碼),直接寫在這裡;
/// 要換專案時可用 `--dart-define=SENTRY_DSN=...` 覆蓋,給空字串則停用。
///
/// 隱私:不送個資(sendDefaultPii=false)、不截圖、不送畫面結構,
/// 只送錯誤訊息、堆疊、機型/系統/App 版本。IP 另在 Sentry 專案設定關閉儲存。
abstract final class CrashReporting {
  static const _dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://5e78c64a5d53156635858225fe3bd217@o4512258093285376.ingest.us.sentry.io/4512258103967744',
  );

  static bool get enabled => kReleaseMode && _dsn.isNotEmpty;

  /// 包住 `runApp`:啟用時由 Sentry 接手未攔截的錯誤與原生當機。
  static Future<void> run(void Function() appRunner) async {
    if (!enabled) {
      appRunner();
      return;
    }
    await SentryFlutter.init((options) {
      options
        ..dsn = _dsn
        ..sendDefaultPii = false
        ..attachScreenshot = false
        ..attachViewHierarchy = false
        // 只要錯誤回報,不做效能追蹤,省額度。
        ..tracesSampleRate = 0;
    }, appRunner: appRunner);
  }

  /// 已被攔下、畫面有提示,但不該發生的錯誤(程式 bug 類)。
  /// 預期內的失敗(格式錯的備份檔、沒網路)不要丟進來,以免洗掉額度。
  static void report(Object error, StackTrace stackTrace) {
    if (!enabled) {
      debugPrint('PackPlan error: $error\n$stackTrace');
      return;
    }
    unawaited(Sentry.captureException(error, stackTrace: stackTrace));
  }
}
