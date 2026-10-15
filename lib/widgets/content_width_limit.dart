import 'dart:math' as math;

import 'package:flutter/material.dart';

/// iPad 等寬螢幕上，把整個 App 限制在置中的一欄，兩側用頁面底色補滿。
///
/// 放在 MaterialApp.builder，導覽列、對話框、底部面板都會在這一欄裡；
/// MediaQuery 的寬度一併改成欄寬，內部版面照手機的寬度計算。
/// 手機寬度不到 [maxWidth]，原樣顯示。
class ContentWidthLimit extends StatelessWidget {
  const ContentWidthLimit({super.key, required this.child});

  static const double maxWidth = 720;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) return child;

        final media = MediaQuery.of(context);
        final sideGap = (constraints.maxWidth - maxWidth) / 2;
        // 兩側留白已經避開瀏海/圓角，左右安全邊距扣掉留白的部分。
        EdgeInsets narrow(EdgeInsets insets) => insets.copyWith(
          left: math.max(0, insets.left - sideGap),
          right: math.max(0, insets.right - sideGap),
        );

        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            // iOS 換頁動畫會在頁面左側外面畫陰影,平常在螢幕外;
            // 限寬後會露在左邊留白上,所以裁在這一欄裡。
            child: ClipRect(
              child: SizedBox(
                width: maxWidth,
                child: MediaQuery(
                  data: media.copyWith(
                    size: Size(maxWidth, media.size.height),
                    padding: narrow(media.padding),
                    viewPadding: narrow(media.viewPadding),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
