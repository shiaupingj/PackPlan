import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/templates_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';
import 'app_scope.dart';

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
              foregroundColor: AppColors.onPrimary,
              elevation: 2,
              onPressed: () => _showHomeHelp(context),
              child: const Icon(Icons.info_outline_rounded),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            label: '清單',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_list_outlined),
            label: '範本',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '設定'),
        ],
      ),
    );
  }

  Future<void> _showHomeHelp(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('操作說明'),
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
