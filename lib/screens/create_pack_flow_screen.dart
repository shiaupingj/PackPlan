import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../data/pack_list_repository.dart';
import '../models/pack_item.dart';
import '../models/pack_list.dart';
import '../models/pack_template.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';
import '../widgets/template_card.dart';
import '../widgets/weather_choice_chips.dart';
import 'pack_detail_screen.dart';

class CreatePackFlowScreen extends StatefulWidget {
  const CreatePackFlowScreen({super.key, this.initialTemplate});

  final PackTemplate? initialTemplate;

  @override
  State<CreatePackFlowScreen> createState() => _CreatePackFlowScreenState();
}

class _CreatePackFlowScreenState extends State<CreatePackFlowScreen> {
  /// Step 3 預設不勾的項目(依範本)。不在名單內的項目預設全勾。
  /// 名稱也涵蓋依天氣動態加入的天氣裝備(背包防雨套等)。
  static const _defaultUnselectedNamesByTemplate = {
    'basic-hike': _basicHikeDefaultUnselectedNames,
    // 進階登山繼承基礎登山全部項目,沿用同一份預設不勾名單。
    'advanced-hike': _basicHikeDefaultUnselectedNames,
    'city-travel': _cityTravelDefaultUnselectedNames,
  };

  static const _cityTravelDefaultUnselectedNames = {
    '登機箱',
    '後背包',
    '正式服裝',
    '刮鬍刀',
    '隱形眼鏡/眼鏡',
    '化妝品',
    '保養品',
    '旅遊保險',
    '環保購物袋',
    '太陽眼鏡',
    '水瓶',
    '背包防雨套',
    '防風外套',
    '保暖中層',
    '防曬用品',
    '耳機',
    '相機',
    '毛巾',
    '睡衣',
    '圍巾配件',
    '洗面乳',
  };

  static const _basicHikeDefaultUnselectedNames = {
    '背包套',
    '小背包',
    '防水袋',
    '睡墊',
    '中層背心',
    '拖鞋',
    '綁腿',
    '護膝',
    '手套',
    '鳳梨穌',
    '巧克力',
    '香蕉',
    '沖泡飲',
    '保溫瓶',
    '溼紙巾',
    '貓鏟',
    '雨傘',
  };

  late PackTemplate? _template = widget.initialTemplate;
  int _step = 0;
  int _days = 3;
  Set<WeatherCondition> _weatherConditions = {WeatherCondition.sunny};
  bool _includeWornItems = false;
  final Set<String> _excludedItemKeys = {};
  final Set<String> _includedItemKeys = {};

  /// Step 2 的清單名稱。使用者沒自己輸入時,選範本會帶入該類型的預設名稱。
  /// 從範本分頁進來(跳過 Step 1)也一定會經過 Step 2,所以名稱放這裡。
  final _titleController = TextEditingController();
  bool _titleEdited = false;

  @override
  void initState() {
    super.initState();
    final template = _template;
    if (template != null) {
      _step = 1;
      _titleController.text = defaultPackListTitle(template.tripType);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _goToStep(int step) => setState(() => _step = step);

  @override
  Widget build(BuildContext context) {
    final canContinue = _step != 0 || _template != null;
    final actions = _step < 3
        ? PrimaryActionRow(
            primaryLabel: '下一步',
            onPrimary: canContinue ? () => _goToStep(_step + 1) : null,
            secondaryLabel: _step == 0 ? null : '上一步',
            onSecondary: _step == 0 ? null : () => _goToStep(_step - 1),
          )
        : PrimaryActionRow(
            primaryLabel: '生成清單',
            onPrimary: _createList,
            secondaryLabel: '上一步',
            onSecondary: () => _goToStep(_step - 1),
          );
    // Step 3 項目很長,上一步/下一步固定在頁面底部;其他步驟接在內容後面。
    final pinActions = _step == 2;

    return Scaffold(
      appBar: AppBar(title: const Text('建立清單')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Step ${_step + 1} / 4',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildStep(context),
          if (!pinActions) ...[const SizedBox(height: AppSpacing.xl), actions],
        ],
      ),
      bottomNavigationBar: pinActions
          ? DecoratedBox(
              key: const ValueKey('create-flow-pinned-actions'),
              decoration: BoxDecoration(
                color: context.palette.background,
                border: Border(top: BorderSide(color: context.palette.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: actions,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStep(BuildContext context) {
    return switch (_step) {
      0 => _TemplateStep(
        selected: _template,
        onSelected: (template) {
          setState(() {
            if (_template?.id != template.id) {
              _excludedItemKeys.clear();
              _includedItemKeys.clear();
            }
            _template = template;
            if (!_titleEdited) {
              _titleController.text = defaultPackListTitle(template.tripType);
            }
          });
        },
      ),
      1 => _TripSettingsStep(
        titleController: _titleController,
        // 清空名稱後回 Step 1 換範本,會重新帶入預設名稱。
        onTitleChanged: (value) => _titleEdited = value.trim().isNotEmpty,
        days: _days,
        weatherConditions: _weatherConditions,
        includeWornItems: _includeWornItems,
        onDaysChanged: (days) => setState(() => _days = days),
        onWeatherChanged: (weatherConditions) =>
            setState(() => _weatherConditions = weatherConditions),
        onIncludeWornItemsChanged: (value) =>
            setState(() => _includeWornItems = value),
      ),
      2 => _ItemSelectionStep(
        items: _previewItems(),
        selectedItemKeys: _selectedItemKeys(),
        onItemChanged: (item, selected) {
          setState(() {
            final key = packItemSelectionKey(item);
            if (selected) {
              _excludedItemKeys.remove(key);
              _includedItemKeys.add(key);
            } else {
              _excludedItemKeys.add(key);
              _includedItemKeys.remove(key);
            }
          });
        },
      ),
      _ => _ReviewStep(
        title: _titleController.text.trim().isEmpty
            ? defaultPackListTitle(_template!.tripType)
            : _titleController.text.trim(),
        template: _template!,
        days: _days,
        weatherConditions: _weatherConditions,
        includeWornItems: _includeWornItems,
        selectedItemCount: _selectedItemKeys().length,
      ),
    };
  }

  List<PackItem> _previewItems() {
    final template = _template;
    if (template == null) return const [];
    final items = AppScope.of(context).previewItemsForDraft(
      template: template,
      days: _days,
      weatherConditions: _weatherConditions,
    );
    if (_includeWornItems) return items;
    return items.where((item) => item.weightClass != WeightClass.worn).toList();
  }

  Set<String> _selectedItemKeys() {
    return _previewItems()
        .where(_isItemSelected)
        .map(packItemSelectionKey)
        .toSet();
  }

  bool _isItemSelected(PackItem item) {
    final key = packItemSelectionKey(item);
    if (_includedItemKeys.contains(key)) return true;
    if (_excludedItemKeys.contains(key)) return false;
    final unselected = _defaultUnselectedNamesByTemplate[_template?.id];
    return !(unselected?.contains(item.name) ?? false);
  }

  void _createList() {
    final template = _template;
    if (template == null) return;

    final repository = AppScope.of(context);
    final list = repository.createFromDraft(
      CreatePackListDraft(
        template: template,
        title: _titleController.text,
        days: _days,
        weatherConditions: _weatherConditions,
        selectedItemKeys: _selectedItemKeys(),
      ),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PackDetailScreen(listId: list.id),
      ),
    );
  }
}

class _ItemSelectionStep extends StatelessWidget {
  const _ItemSelectionStep({
    required this.items,
    required this.selectedItemKeys,
    required this.onItemChanged,
  });

  final List<PackItem> items;
  final Set<String> selectedItemKeys;
  final void Function(PackItem item, bool selected) onItemChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final itemsByCategory = <String, List<PackItem>>{};
    for (final item in items) {
      itemsByCategory.putIfAbsent(item.categoryName, () => []).add(item);
    }
    final selectedCount = items
        .where((item) => selectedItemKeys.contains(packItemSelectionKey(item)))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('選擇項目', style: t.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('依需求取消不需要的項目，建立後仍可調整。', style: t.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '已選 $selectedCount / ${items.length} 項',
          style: t.bodySmall?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xl),
        ...itemsByCategory.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: t.titleLarge),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth =
                        (constraints.maxWidth - AppSpacing.sm * 2) / 3;
                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: entry.value.map((item) {
                        final selected = selectedItemKeys.contains(
                          packItemSelectionKey(item),
                        );
                        return SizedBox(
                          width: itemWidth,
                          height: 52,
                          child: Material(
                            key: ValueKey(
                              'draft-item-${packItemSelectionKey(item)}',
                            ),
                            color: selected
                                ? AppColors.primary
                                : context.palette.surface,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: selected
                                    ? AppColors.primary
                                    : context.palette.border,
                                width: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => onItemChanged(item, !selected),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                ),
                                // 選取只用顏色區分,不加勾。
                                child: Center(
                                  child: Text(
                                    item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selected
                                          ? AppColors.ink
                                          : context.palette.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TemplateStep extends StatelessWidget {
  const _TemplateStep({required this.selected, required this.onSelected});

  final PackTemplate? selected;
  final ValueChanged<PackTemplate> onSelected;

  @override
  Widget build(BuildContext context) {
    final templates = AppScope.of(context).templates;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('選擇範本', style: t.headlineMedium),
        const SizedBox(height: AppSpacing.lg),
        ...templates.map((template) {
          final locked = template.proOnly;
          final active = selected?.id == template.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TemplateCard(
              name: template.name,
              description: locked
                  ? '${template.description} Pro 範本稍後開放。'
                  : template.description,
              locked: locked,
              selected: active,
              onTap: locked ? null : () => onSelected(template),
            ),
          );
        }),
      ],
    );
  }
}

class _TripSettingsStep extends StatelessWidget {
  const _TripSettingsStep({
    required this.titleController,
    required this.onTitleChanged,
    required this.days,
    required this.weatherConditions,
    required this.includeWornItems,
    required this.onDaysChanged,
    required this.onWeatherChanged,
    required this.onIncludeWornItemsChanged,
  });

  final TextEditingController titleController;
  final ValueChanged<String> onTitleChanged;
  final int days;
  final Set<WeatherCondition> weatherConditions;
  final bool includeWornItems;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<Set<WeatherCondition>> onWeatherChanged;
  final ValueChanged<bool> onIncludeWornItemsChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('旅程設定', style: t.headlineMedium),
        const SizedBox(height: AppSpacing.lg),
        // 標題字級同 Step 3 項目文字(bodyMedium 15),輸入文字 22(titleLarge)。
        // 浮動 label 會被縮成 0.75 倍,所以標題另外放 Text,不用 labelText。
        Text(
          '清單名稱',
          style: t.bodyMedium?.copyWith(color: context.palette.textSecondary),
        ),
        TextField(
          key: const ValueKey('create-list-title'),
          controller: titleController,
          onChanged: onTitleChanged,
          style: t.titleLarge,
          decoration: const InputDecoration(isDense: true),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('天數', style: t.titleMedium),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    IconButton(
                      tooltip: '減少天數',
                      onPressed: days <= 1
                          ? null
                          : () => onDaysChanged(days - 1),
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: Text(
                        '$days 天',
                        textAlign: TextAlign.center,
                        style: t.displayLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: '增加天數',
                      onPressed: days >= 14
                          ? null
                          : () => onDaysChanged(days + 1),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        WeatherChoiceChips(
          selected: weatherConditions,
          onChanged: onWeatherChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: SwitchListTile(
            key: const ValueKey('include-worn-items-switch'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            title: const Text('加入身上穿戴'),
            subtitle: const Text('獨立列出，重量不計入背包基重'),
            value: includeWornItems,
            onChanged: onIncludeWornItemsChanged,
          ),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.title,
    required this.template,
    required this.days,
    required this.weatherConditions,
    required this.includeWornItems,
    required this.selectedItemCount,
  });

  final String title;
  final PackTemplate template;
  final int days;
  final Set<WeatherCondition> weatherConditions;
  final bool includeWornItems;
  final int selectedItemCount;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('確認清單', style: t.headlineMedium),
        const SizedBox(height: AppSpacing.lg),
        // 滿版:Column 預設依內容寬度縮,卡片要撐滿整列。
        SizedBox(
          width: double.infinity,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    key: const ValueKey('review-list-title'),
                    style: t.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${template.name} · $days 天，${_weatherSummary(weatherConditions)}',
                    style: t.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('衣物與食物會依天數調整，天氣會加入對應裝備。', style: t.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text('已選 $selectedItemCount 個項目', style: t.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    includeWornItems ? '身上穿戴：已加入' : '身上穿戴：未加入',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PrimaryActionRow extends StatelessWidget {
  const PrimaryActionRow({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    // 高度與 PrimaryButton(如「建立新清單」)一致:同樣的上下留白與字級。
    const padding = EdgeInsets.symmetric(vertical: AppSpacing.lg);
    final textStyle = Theme.of(context).textTheme.labelLarge;
    return Row(
      children: [
        if (secondaryLabel != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onSecondary,
              style: OutlinedButton.styleFrom(
                backgroundColor: context.palette.surface,
                foregroundColor: context.palette.textPrimary,
                side: BorderSide(color: context.palette.border, width: 0.8),
                padding: padding,
                textStyle: textStyle,
              ),
              child: Text(secondaryLabel!),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: onPrimary,
            style: FilledButton.styleFrom(
              padding: padding,
              textStyle: textStyle,
            ),
            child: Text(primaryLabel),
          ),
        ),
      ],
    );
  }
}

String _weatherLabel(WeatherCondition weather) {
  return switch (weather) {
    WeatherCondition.sunny => '晴天',
    WeatherCondition.cloudy => '陰天',
    WeatherCondition.rainy => '雨天',
    WeatherCondition.cold => '低溫',
  };
}

String _weatherSummary(Set<WeatherCondition> weatherConditions) {
  return weatherConditions.map(_weatherLabel).join('、');
}
