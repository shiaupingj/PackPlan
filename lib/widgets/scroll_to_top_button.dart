import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// 捲動超過 [threshold] 後出現的「回到頂端」按鈕。
///
/// 放在 Scaffold 的 floatingActionButton,位置與外觀和首頁的 (i) 說明按鈕一致
/// (右下、導覽列上方;卡片底色 + 邊框的圓角方塊)。
class ScrollToTopButton extends StatefulWidget {
  const ScrollToTopButton({
    super.key,
    required this.controller,
    this.threshold = 300,
    this.bottomLift = 0,
  });

  /// 分頁內的頁面(底部被外殼的浮動導覽列蓋住)要把按鈕往上推多少,
  /// 才會停在導覽列上方 16 的位置,和首頁 (i) 一樣。
  ///
  /// 外殼用 extendBody,導覽列高度只反映在 padding、不在 viewPadding,
  /// Scaffold 不會自己把浮動按鈕往上推。要用頁面自己的 [context] 算
  /// (Scaffold 給浮動按鈕的 context 已經把 padding 清掉了)。
  static double liftAboveNavBar(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.padding.bottom <= media.viewPadding.bottom) return 0;
    final defaultMargin = math.max(
      kFloatingActionButtonMargin,
      media.viewPadding.bottom,
    );
    return math.max(
      0,
      media.padding.bottom + kFloatingActionButtonMargin - defaultMargin,
    );
  }

  final ScrollController controller;

  /// 往下捲超過這個距離才顯示。
  final double threshold;

  /// 按鈕額外往上推的距離,見 [liftAboveNavBar]。
  final double bottomLift;

  @override
  State<ScrollToTopButton> createState() => _ScrollToTopButtonState();
}

class _ScrollToTopButtonState extends State<ScrollToTopButton> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(ScrollToTopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handleScroll);
    widget.controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    final controller = widget.controller;
    final visible =
        controller.hasClients && controller.offset > widget.threshold;
    if (visible != _visible) setState(() => _visible = visible);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomLift),
      child: SizedBox.square(
        dimension: 48,
        child: FloatingActionButton(
          key: const ValueKey('scroll-to-top'),
          // 清單內頁是另外推上來的頁面,不要和其他頁的浮動按鈕做 Hero 轉場。
          heroTag: null,
          tooltip: '回到頂端',
          backgroundColor: context.palette.surface,
          foregroundColor: context.palette.textPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: context.palette.border, width: 0.8),
          ),
          onPressed: () => widget.controller.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
          child: const Icon(Icons.arrow_upward_rounded, size: 26),
        ),
      ),
    );
  }
}
