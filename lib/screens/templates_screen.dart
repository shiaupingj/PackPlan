import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/pack_template.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';
import 'create_pack_flow_screen.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('範本')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.navBarClearance,
        ),
        children: [
          Text('選一種旅程，先產生可調整的清單。', style: t.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          ...repository.templates.map(
            (template) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _TemplateCard(
                template: template,
                onTap: () => _createFromTemplate(context, template),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createFromTemplate(BuildContext context, PackTemplate template) {
    if (template.proOnly) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pro 範本會在 1.1 版本開放')));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreatePackFlowScreen(initialTemplate: template),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final PackTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final active = !template.proOnly;

    return Card(
      color: active ? AppColors.primary : context.palette.surface,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        title: Text(
          template.name,
          style: t.titleMedium?.copyWith(
            color: active ? AppColors.ink : context.palette.textPrimary,
          ),
        ),
        subtitle: Text(
          template.description,
          style: TextStyle(
            color: active ? AppColors.orange900 : context.palette.textSecondary,
          ),
        ),
        trailing: template.proOnly
            ? Icon(Icons.lock_outline, color: context.palette.textSecondary)
            : const Icon(Icons.chevron_right, color: AppColors.ink),
      ),
    );
  }
}
