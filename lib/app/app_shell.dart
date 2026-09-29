import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/templates_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';
import 'app_scope.dart';
import '../widgets/app_dialog_title.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context);
    return Scaffold(
      // 內容延伸到浮動膠囊底下，讓導覽列版位透明、不再出現滿寬灰色橫條。
      extendBody: true,
      body: Column(
        children: [
          if (repository.hasSaveError) const _SaveErrorBanner(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                HomeScreen(),
                TemplatesScreen(),
                ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.small(
              key: const ValueKey('home-help-button'),
              heroTag: 'home-help-button',
              tooltip: '操作說明',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              onPressed: () => _showHomeHelp(context),
              child: const Icon(Icons.info_outline_rounded),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Future<void> _showHomeHelp(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: AppDialogTitle.padding,
          title: const AppDialogTitle('操作說明'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('長按首頁中的任一清單卡片，即可開啟清單操作選單。'),
                const SizedBox(height: AppSpacing.lg),
                const _HelpAction(
                  icon: Icons.edit_outlined,
                  title: '重新命名',
                  description: '修改清單名稱',
                ),
                const SizedBox(height: AppSpacing.md),
                const _HelpAction(
                  icon: Icons.copy_outlined,
                  title: '複製清單',
                  description: '建立一份相同內容的副本',
                ),
                const SizedBox(height: AppSpacing.md),
                const _HelpAction(
                  icon: Icons.delete_outline,
                  title: '刪除清單',
                  description: '確認後刪除整份清單',
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: const Text('知道了'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// LINE 風「浮動膠囊」導覽列。取代 Material `NavigationBar`。
///
/// 樣式對照 Figma Bottom Nav component set（node 32:62）：
/// dock 用 `palette.surface` + `StadiumBorder`，選中膠囊用 `palette.border`，
/// 選中前景橘、未選 `palette.textTertiary`；選中=實心圖示、未選=線條圖示。
/// 寬度包住內容並置中，深/淺色隨主題自動切換。
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _tabs = <_NavTabData>[
    _NavTabData(
      label: '主頁',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _NavTabData(
      label: '範本',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
    ),
    _NavTabData(
      label: '設定',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        // heightFactor: 1.0 → 高度只包住膠囊，避免在 bottomNavigationBar
        // 版位垂直撐滿而把內文區壓扁；水平置中不寫死寬度。
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: palette.surface,
              shape: const StadiumBorder(),
              shadows: const [
                BoxShadow(
                  color: Color(0x2E000000), // 黑 18%
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _tabs.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    _NavTab(
                      data: _tabs[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTabData {
  const _NavTabData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavTabData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = selected ? AppColors.primary : palette.textTertiary;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? palette.border : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            // 所有 tab 尺寸一致 → 切換時不位移。
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? data.selectedIcon : data.icon,
                  size: 24,
                  color: foreground,
                ),
                const SizedBox(height: 3),
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpAction extends StatelessWidget {
  const _HelpAction({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 本機寫入失敗時的持續性警示。寫入恢復成功後自動消失。
class _SaveErrorBanner extends StatelessWidget {
  const _SaveErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.weightOver,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: AppColors.onWeightOver,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '無法寫入本機儲存，最新變更可能遺失。請確認裝置空間。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onWeightOver,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
