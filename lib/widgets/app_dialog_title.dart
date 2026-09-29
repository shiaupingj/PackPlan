import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// 對話框標題列：左邊標題、右上角關閉（×）。
///
/// 關閉等同「取消」：以 null 關掉對話框，呼叫端照取消處理。
/// 搭配 [AppDialogTitle.padding] 當 AlertDialog 的 titlePadding，讓 × 貼齊右上角。
class AppDialogTitle extends StatelessWidget {
  const AppDialogTitle(this.title, {super.key});

  final String title;

  static const padding = EdgeInsets.fromLTRB(24, 12, 8, 0);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title)),
        IconButton(
          key: const ValueKey('dialog-close'),
          tooltip: '關閉',
          icon: const Icon(Icons.close),
          color: context.palette.textSecondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
