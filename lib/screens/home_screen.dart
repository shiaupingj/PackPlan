import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../services/trip_formatters.dart';
import '../theme/app_dimens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/pack_list_card.dart';
import 'create_pack_flow_screen.dart';
import 'pack_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context);
    final lists = repository.lists;
    final settings = repository.settings;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('打包清單')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
            ...lists.map((list) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: PackListCard(
                  title: list.title,
                  subtitle: TripFormatters.summary(list),
                  weightGram: list.baseWeightGram,
                  weightUnit: settings.weightUnit,
                  progress: list.progress,
                  showWeight: list.showWeight,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PackDetailScreen(listId: list.id),
                    ),
                  ),
                  onLongPress: () => _showListActions(context, list.id),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _openCreateFlow(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreatePackFlowScreen()),
    );
  }

  void _showListActions(BuildContext context, String listId) {
    final repository = AppScope.of(context);
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
                    final confirmed = await _confirmDelete(context);
                    if (!confirmed) return;
                    repository.deleteList(listId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('清單已刪除')));
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
          title: const Text('重新命名清單'),
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

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('刪除清單？'),
          content: const Text('刪除後目前版本無法復原。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('刪除'),
            ),
          ],
        );
      },
    );
    return result ?? false;
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
