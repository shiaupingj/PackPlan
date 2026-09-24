import 'package:flutter/material.dart';

import '../data/pack_list_repository.dart';
import '../data/weight_reference_repository.dart';
import '../theme/app_dimens.dart';
import '../theme/app_theme.dart';
import 'pack_plan_app.dart';

typedef RepositoryInitializer = Future<PackListRepository> Function();
typedef LocalDataResetter = Future<void> Function();

class PackPlanBootstrap extends StatefulWidget {
  const PackPlanBootstrap({
    super.key,
    required this.initialize,
    required this.resetLocalData,
    this.weightReferenceRepository,
  });

  final RepositoryInitializer initialize;
  final LocalDataResetter resetLocalData;
  final WeightReferenceRepository? weightReferenceRepository;

  @override
  State<PackPlanBootstrap> createState() => _PackPlanBootstrapState();
}

class _PackPlanBootstrapState extends State<PackPlanBootstrap> {
  late Future<PackListRepository> _initialization;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _initialization = widget.initialize();
  }

  void _retry() {
    setState(() {
      _initialization = widget.initialize();
    });
  }

  Future<void> _confirmReset(BuildContext hostContext) async {
    final messenger = ScaffoldMessenger.of(hostContext);
    final confirmed =
        await showDialog<bool>(
          context: hostContext,
          builder: (dialogContext) => AlertDialog(
            title: const Text('重建本機資料？'),
            content: const Text(
              '這會刪除目前裝置中無法讀取的資料，並重新建立範例清單。'
              '如果你有 PackPlan 備份，可在重新進入 App 後從「設定」匯入。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('重建資料'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _resetting = true);
    try {
      await widget.resetLocalData();
      if (!mounted) return;
      setState(() {
        _resetting = false;
        _initialization = widget.initialize();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _resetting = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('無法重建本機資料，請重新啟動 App 後再試')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackListRepository>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return PackPlanApp(
            repository: snapshot.requireData,
            weightReferenceRepository: widget.weightReferenceRepository,
          );
        }
        return MaterialApp(
          title: 'PackPlan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: snapshot.hasError
              ? _StartupRecoveryScreen(
                  resetting: _resetting,
                  onRetry: _retry,
                  onReset: _confirmReset,
                )
              : const _StartupLoadingScreen(),
        );
      },
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.lg),
              Text('正在讀取你的打包資料…'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupRecoveryScreen extends StatelessWidget {
  const _StartupRecoveryScreen({
    required this.resetting,
    required this.onRetry,
    required this.onReset,
  });

  final bool resetting;
  final VoidCallback onRetry;
  final void Function(BuildContext hostContext) onReset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storage_outlined, size: 64),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '無法讀取本機資料',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '資料庫可能暫時無法使用，或儲存內容已損毀。'
                    '你可以先重新嘗試；若仍無法開啟，再重建本機資料。',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: resetting ? null : onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新嘗試'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: resetting ? null : () => onReset(context),
                      icon: resetting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restart_alt),
                      label: Text(resetting ? '正在重建…' : '重建本機資料'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '重建會清除這台裝置的本機資料。已有備份的話，之後可從「設定」匯入還原。',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
