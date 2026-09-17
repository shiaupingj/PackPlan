import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_scope.dart';
import '../models/pack_template.dart';
import '../models/user_settings.dart';
import '../services/backup_codec.dart';
import '../services/formatters.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';
import 'create_pack_flow_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _appVersion = '1.0.0+1';
  static const _privacyUrl =
      'https://shiaupingj.github.io/appspdoit/legal/packplan-privacy.html';
  static const _termsUrl =
      'https://shiaupingj.github.io/appspdoit/legal/packplan-terms.html';

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context);
    final settings = repository.settings;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const _ProUpgradeCard(),
          const SizedBox(height: AppSpacing.lg),
          Text('偏好設定', style: t.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('單位設定', style: t.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<WeightUnit>(
                    segments: const [
                      ButtonSegment(
                        value: WeightUnit.kg,
                        label: Text('kg'),
                        icon: Icon(Icons.monitor_weight_outlined),
                      ),
                      ButtonSegment(
                        value: WeightUnit.gram,
                        label: Text('g'),
                        icon: Icon(Icons.scale_outlined),
                      ),
                    ],
                    selected: {settings.weightUnit},
                    onSelectionChanged: (selection) {
                      repository.updateSettings(
                        settings.copyWith(weightUnit: selection.first),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('預設重量上限', style: t.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '新登山/露營清單會使用 '
                    '${WeightFormatters.gram(settings.defaultWeightLimitGram, unit: settings.weightUnit)}',
                    style: t.bodySmall,
                  ),
                  Slider(
                    min: 4000,
                    max: 15000,
                    divisions: 22,
                    label: WeightFormatters.gram(
                      settings.defaultWeightLimitGram,
                      unit: settings.weightUnit,
                    ),
                    value: settings.defaultWeightLimitGram.toDouble(),
                    onChanged: (value) {
                      repository.updateSettings(
                        settings.copyWith(
                          defaultWeightLimitGram: (value / 500).round() * 500,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('外觀', style: t.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('淺色'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('深色'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('跟隨系統'),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (selection) {
                        repository.updateSettings(
                          settings.copyWith(themeMode: selection.first),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('資料管理', style: t.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('備份包含全部清單與偏好設定', style: t.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.file_upload_outlined,
                  title: '匯出備份',
                  subtitle: '將目前資料儲存為 JSON 檔案',
                  onTap: () => _exportBackup(context),
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.file_download_outlined,
                  title: '匯入備份',
                  subtitle: '從 PackPlan JSON 備份還原資料',
                  onTap: () => _importBackup(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('我的範本', style: t.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('${repository.templates.length} 個範本', style: t.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Column(
              children: _templateTiles(context, repository.templates),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('聯繫', style: t.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.feedback_outlined,
                  title: '建議與反饋',
                  subtitle: '提供使用建議或回報問題',
                  onTap: () => _showSnack(context, '建議與反饋會在 1.1 版本補上'),
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.ios_share_outlined,
                  title: '分享給朋友',
                  subtitle: '邀請朋友一起建立打包清單',
                  onTap: () => _showSnack(context, '分享功能會在 1.1 版本補上'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('關於', style: t.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.new_releases_outlined,
                  title: '版本資訊',
                  subtitle: 'PackPlan $_appVersion',
                  onTap: () => _showSnack(context, '目前版本 $_appVersion'),
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: '隱私權政策',
                  subtitle: '資料使用與隱私說明',
                  onTap: () => _openUrl(context, _privacyUrl),
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.description_outlined,
                  title: '使用條款',
                  subtitle: '服務條款與免責聲明',
                  onTap: () => _openUrl(context, _termsUrl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _templateTiles(
    BuildContext context,
    List<PackTemplate> templates,
  ) {
    final tiles = <Widget>[];
    for (var index = 0; index < templates.length; index += 1) {
      final template = templates[index];
      final locked = template.proOnly;
      if (index > 0) tiles.add(const Divider(height: 1));
      tiles.add(
        ListTile(
          leading: Icon(
            locked ? Icons.lock_outline : Icons.view_list_outlined,
            color: locked ? context.palette.textTertiary : AppColors.primary,
          ),
          title: Text(template.name),
          subtitle: Text(locked ? 'Pro 範本，升級後可使用' : '免費範本，可建立清單'),
          trailing: Icon(locked ? Icons.lock_outline : Icons.chevron_right),
          onTap: () => locked
              ? _showSnack(context, '${template.name} 是 Pro 範本，會在 1.1 版本開放')
              : _openTemplate(context, template),
        ),
      );
    }
    return tiles;
  }

  static void _openTemplate(BuildContext context, PackTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreatePackFlowScreen(initialTemplate: template),
      ),
    );
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showSnack(context, '無法開啟連結');
      }
    } on Object {
      if (context.mounted) _showSnack(context, '無法開啟連結');
    }
  }

  static Future<void> _exportBackup(BuildContext context) async {
    final repository = AppScope.of(context);
    final bytes = BackupCodec.encode(
      lists: repository.lists,
      settings: repository.settings,
    );
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    try {
      final path = await FilePicker.saveFile(
        dialogTitle: '匯出 PackPlan 備份',
        fileName: 'packplan-backup-$date.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
      if (path != null && context.mounted) {
        _showSnack(context, '備份已匯出');
      }
    } on Object {
      if (context.mounted) {
        _showSnack(context, '無法匯出備份，請稍後再試');
      }
    }
  }

  static Future<void> _importBackup(BuildContext context) async {
    try {
      // 不帶 withData：先用檔案大小 metadata 擋掉超大檔，
      // 通過後才把內容讀進記憶體，避免誤選大檔案直接撐爆 App。
      final result = await FilePicker.pickFiles(
        dialogTitle: '選擇 PackPlan 備份',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (result == null || !context.mounted) return;

      final file = result.files.single;
      if (file.size > BackupCodec.maxFileBytes) {
        throw const BackupFormatException('備份檔超過 10 MB');
      }
      final path = file.path;
      if (path == null) {
        throw const BackupFormatException('無法讀取選取的備份檔');
      }
      final bytes = await File(path).readAsBytes();
      final backup = BackupCodec.decode(bytes);
      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('匯入並取代目前資料？'),
          content: Text(
            '將匯入 ${backup.lists.length} 份清單，並取代目前所有清單與偏好設定。'
            '此動作無法復原，建議先匯出目前資料。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('匯入'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      AppScope.of(
        context,
      ).replaceAllData(lists: backup.lists, settings: backup.settings);
      _showSnack(context, '已匯入 ${backup.lists.length} 份清單');
    } on BackupFormatException catch (error) {
      if (context.mounted) _showSnack(context, error.message);
    } on Object {
      if (context.mounted) _showSnack(context, '無法匯入備份，請確認檔案內容');
    }
  }
}

class _ProUpgradeCard extends StatelessWidget {
  const _ProUpgradeCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            Color(0xFF263313),
            AppColors.orange700,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.78),
                    border: Border.all(color: AppColors.textPrimary, width: 1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '特別優惠',
                    style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '升級至 Pro 版',
              style: t.headlineMedium?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '解鎖 Pro 範本 + 更多智慧打包功能',
              style: t.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                onPressed: () =>
                    ProfileScreen._showSnack(context, 'Pro 會在 1.1 版本開放'),
                child: const Text('NT\$ 150 一次性買斷'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
