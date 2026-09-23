import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_scope.dart';
import '../app/cloud_backup_scope.dart';
import '../models/user_settings.dart';
import '../services/backup_codec.dart';
import '../services/cloud_backup_service.dart';
import '../services/formatters.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';

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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.navBarClearance,
        ),
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
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<WeightUnit>(
                      segments: const [
                        ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                        ButtonSegment(value: WeightUnit.gram, label: Text('g')),
                      ],
                      selected: {settings.weightUnit},
                      onSelectionChanged: (selection) {
                        repository.updateSettings(
                          settings.copyWith(weightUnit: selection.first),
                        );
                      },
                    ),
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
          const SizedBox(height: AppSpacing.md),
          const _CloudBackupCard(),
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
        // 對照 Figma 特別優惠卡（node 45:189）：
        // linear-gradient(148°, #838383 14%, #D65300 85%)。
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF838383), AppColors.orange700],
          stops: [0.14, 0.85],
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

/// 設定頁「資料管理」的雲端備份卡片(v1:手動備份 / 還原)。
///
/// Android 用 Google Drive、iOS 待接 iCloud;依 [CloudBackupService] 狀態
/// 顯示「連結帳號 / 備份 / 還原」。還原沿用「取代目前資料」確認框。
class _CloudBackupCard extends StatefulWidget {
  const _CloudBackupCard();

  @override
  State<_CloudBackupCard> createState() => _CloudBackupCardState();
}

class _CloudBackupCardState extends State<_CloudBackupCard> {
  bool _loading = true;
  bool _busy = false;
  bool _supported = false;
  bool _signedIn = false;
  DateTime? _lastBackup;

  CloudBackupService get _service => CloudBackupScope.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _refresh();
  }

  Future<void> _refresh() async {
    final service = _service;
    var signedIn = false;
    DateTime? last;
    final supported = service.isSupported;
    if (supported) {
      signedIn = await service.isSignedIn();
      if (signedIn) last = await service.lastBackupTime();
    }
    if (!mounted) return;
    setState(() {
      _supported = supported;
      _signedIn = signedIn;
      _lastBackup = last;
      _loading = false;
    });
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    try {
      final ok = await _service.signIn();
      if (!mounted) return;
      if (ok) {
        await _refresh();
      } else {
        ProfileScreen._showSnack(context, '未完成登入');
      }
    } on Object {
      if (mounted) ProfileScreen._showSnack(context, '登入失敗,請稍後再試');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backup() async {
    final repository = AppScope.of(context);
    setState(() => _busy = true);
    try {
      final bytes = BackupCodec.encode(
        lists: repository.lists,
        settings: repository.settings,
      );
      await _service.uploadBackup(bytes);
      final last = await _service.lastBackupTime();
      if (!mounted) return;
      setState(() => _lastBackup = last ?? DateTime.now());
      ProfileScreen._showSnack(context, '已備份到雲端');
    } on Object {
      if (mounted) ProfileScreen._showSnack(context, '雲端備份失敗,請稍後再試');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final backup = await _service.downloadBackup();
      if (!mounted) return;
      if (backup == null) {
        ProfileScreen._showSnack(context, '雲端沒有備份');
        return;
      }
      final decoded = BackupCodec.decode(backup.bytes);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('從雲端還原並取代目前資料？'),
          content: Text(
            '將以雲端備份的 ${decoded.lists.length} 份清單取代目前所有清單與偏好設定。'
            '此動作無法復原,建議先匯出目前資料。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('還原'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      AppScope.of(
        context,
      ).replaceAllData(lists: decoded.lists, settings: decoded.settings);
      ProfileScreen._showSnack(context, '已從雲端還原 ${decoded.lists.length} 份清單');
    } on BackupFormatException catch (error) {
      if (mounted) ProfileScreen._showSnack(context, error.message);
    } on Object {
      if (mounted) ProfileScreen._showSnack(context, '雲端還原失敗,請稍後再試');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(children: _buildRows(t)),
      ),
    );
  }

  List<Widget> _buildRows(TextTheme t) {
    if (_loading) {
      return const [
        ListTile(
          leading: Icon(Icons.cloud_outlined, color: AppColors.primary),
          title: Text('雲端備份'),
          subtitle: Text('載入中…'),
        ),
      ];
    }
    if (!_supported) {
      return [
        ListTile(
          leading: Icon(
            Icons.cloud_off_outlined,
            color: context.palette.textTertiary,
          ),
          title: const Text('雲端備份'),
          subtitle: const Text('此平台即將支援(iCloud 規劃中)'),
          enabled: false,
        ),
      ];
    }
    if (!_signedIn) {
      return [
        ListTile(
          leading: const Icon(Icons.cloud_outlined, color: AppColors.primary),
          title: const Text('連結雲端帳號'),
          subtitle: const Text('登入後即可備份與還原'),
          trailing: _busy
              ? const _MiniSpinner()
              : const Icon(Icons.chevron_right),
          onTap: _busy ? null : _connect,
        ),
      ];
    }
    return [
      ListTile(
        leading: const Icon(Icons.backup_outlined, color: AppColors.primary),
        title: const Text('備份到雲端'),
        subtitle: Text(
          _lastBackup == null ? '尚未備份' : '最後備份 ${_formatTime(_lastBackup!)}',
        ),
        trailing: _busy
            ? const _MiniSpinner()
            : const Icon(Icons.chevron_right),
        onTap: _busy ? null : _backup,
      ),
      const Divider(height: 1),
      ListTile(
        leading: const Icon(
          Icons.cloud_download_outlined,
          color: AppColors.primary,
        ),
        title: const Text('從雲端還原'),
        subtitle: const Text('以雲端備份取代目前資料'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _busy ? null : _restore,
      ),
    ];
  }
}

class _MiniSpinner extends StatelessWidget {
  const _MiniSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
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
