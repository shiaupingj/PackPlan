import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/pack_list.dart';
import '../services/trip_formatters.dart';
import '../theme/app_dimens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_dialog_title.dart';
import '../widgets/delete_list_dialog.dart';
import '../widgets/pack_list_card.dart';
import 'create_pack_flow_screen.dart';
import 'pack_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context);
    final lists = repository.lists;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('打包清單')),
      body: ListView(
        // 底部多留白，讓最後一張卡片不被浮動導覽膠囊擋住。
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.navBarClearance,
        ),
        children: [
          Text(
            '聰明打包，輕鬆出遊~',
            style: t.headlineMedium?.copyWith(fontSize: 30, height: 1.12),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('先從一份清單開始，重量會即時幫你看著。', style: t.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: '建立新清單',
            icon: Icons.add,
            onPressed: () => _openCreateFlow(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (lists.isEmpty)
            _EmptyState(onCreate: () => _openCreateFlow(context))
          else
            // 2 欄排列;奇數時最後一列右邊留空。
            for (var i = 0; i < lists.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCard(context, lists[i])),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: i + 1 < lists.length
                          ? _buildCard(context, lists[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, PackList list) {
    return PackListCard(
      key: ValueKey('pack-list-${list.id}'),
      title: list.title,
      subtitle: TripFormatters.brief(list),
      weightGram: list.totalWeightGram,
      weightUnit: AppScope.of(context).settings.weightUnit,
      progress: list.progress,
      showWeight: list.showWeight,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PackDetailScreen(listId: list.id),
        ),
      ),
      onLongPress: () => _showListActions(context, list),
      onMore: () => _showListActions(context, list),
    );
  }

  void _openCreateFlow(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreatePackFlowScreen()),
    );
  }

  void _deleteList(BuildContext context, String listId) {
    AppScope.of(context).deleteList(listId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('清單已刪除')));
  }

  void _showListActions(BuildContext context, PackList list) {
    final repository = AppScope.of(context);
    final listId = list.id;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('清單操作', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('重新命名'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _waitForSheetToClose();
                    if (!context.mounted) return;
                    await _showRenameDialog(context, listId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: const Text('複製清單'),
                  onTap: () async {
                    final copy = repository.duplicateList(listId);
                    Navigator.of(sheetContext).pop();
                    if (copy == null) return;
                    await _waitForSheetToClose();
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PackDetailScreen(listId: copy.id),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('刪除清單'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _waitForSheetToClose();
                    if (!context.mounted) return;
                    final confirmed = await confirmDeleteList(
                      context,
                      list.title,
                    );
                    if (!confirmed || !context.mounted) return;
                    _deleteList(context, listId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('取消'),
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _waitForSheetToClose() {
    return Future<void>.delayed(const Duration(milliseconds: 180));
  }

  Future<void> _waitForDialogToClose() {
    return Future<void>.delayed(const Duration(milliseconds: 220));
  }

  Future<void> _showRenameDialog(BuildContext context, String listId) async {
    final repository = AppScope.of(context);
    final list = repository.findById(listId);
    if (list == null) return;

    final controller = TextEditingController(text: list.title);
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: AppDialogTitle.padding,
          title: const AppDialogTitle('重新命名清單'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '清單名稱'),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('儲存'),
            ),
          ],
        );
      },
    );
    await _waitForDialogToClose();
    controller.dispose();
    if (!context.mounted || title == null || title.trim().isEmpty) return;
    repository.renameList(listId, title);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(Icons.backpack_outlined, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              '還沒準備？我們幫你開始。',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SecondaryButton(label: '建立第一個清單', onPressed: onCreate),
          ],
        ),
      ),
    );
  }
}
