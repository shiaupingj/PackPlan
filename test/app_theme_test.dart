import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:packplan/theme/app_colors.dart';
import 'package:packplan/theme/app_theme.dart';

void main() {
  for (final MapEntry(key: mode, value: theme) in {
    'light': AppTheme.light,
    'dark': AppTheme.dark,
  }.entries) {
    test('$mode 模式 Switch 對齊 Figma:白色圓鈕、關閉灰軌道、開關同尺寸', () {
      final s = theme.switchTheme;
      const on = {WidgetState.selected};
      const off = <WidgetState>{};

      expect(s.thumbColor!.resolve(on), AppColors.switchThumb);
      expect(s.thumbColor!.resolve(off), AppColors.switchThumb);
      expect(s.trackColor!.resolve(on), AppColors.primary);
      expect(s.trackColor!.resolve(off), AppColors.switchTrackOff);
      // 有圖示時 M3 關閉狀態圓鈕不會縮小
      expect(s.thumbIcon!.resolve(off), isNotNull);
    });
  }
}
