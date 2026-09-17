import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' show ThemeMode;

import '../models/pack_item.dart';
import '../models/pack_list.dart';
import '../models/user_settings.dart';

class PackPlanBackup {
  const PackPlanBackup({
    required this.lists,
    required this.settings,
    required this.exportedAt,
  });

  final List<PackList> lists;
  final UserSettings settings;
  final DateTime exportedAt;
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupCodec {
  static const int currentVersion = 1;
  static const int maxFileBytes = 10 * 1024 * 1024;

  static Uint8List encode({
    required List<PackList> lists,
    required UserSettings settings,
    DateTime? exportedAt,
  }) {
    final payload = <String, Object?>{
      'format': 'packplan-backup',
      'version': currentVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'settings': {
        'weightUnit': settings.weightUnit.name,
        'defaultWeightLimitGram': settings.defaultWeightLimitGram,
        'themeMode': settings.themeMode.name,
      },
      'lists': lists.map(_encodeList).toList(),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  static PackPlanBackup decode(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const BackupFormatException('備份檔是空的');
    }
    if (bytes.length > maxFileBytes) {
      throw const BackupFormatException('備份檔超過 10 MB');
    }

    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      final root = _map(decoded, '備份內容');
      if (root['format'] != 'packplan-backup') {
        throw const BackupFormatException('這不是 PackPlan 備份檔');
      }
      final version = _integer(root['version'], '備份版本');
      if (version != currentVersion) {
        throw BackupFormatException('不支援的備份版本：$version');
      }

      final settingsJson = _map(root['settings'], '偏好設定');
      final unitName = _string(settingsJson['weightUnit'], '重量單位');
      final weightUnit = WeightUnit.values
          .where((unit) => unit.name == unitName)
          .firstOrNull;
      if (weightUnit == null) {
        throw BackupFormatException('無效的重量單位：$unitName');
      }
      final limit = _positiveInteger(
        settingsJson['defaultWeightLimitGram'],
        '預設重量上限',
      );
      // 舊備份沒有 themeMode 欄位時，預設跟隨系統。
      final themeName = settingsJson['themeMode'];
      final themeMode = ThemeMode.values
              .where((mode) => mode.name == themeName)
              .firstOrNull ??
          ThemeMode.system;

      final listJson = _list(root['lists'], '清單');
      final lists = listJson
          .map((entry) => _decodeList(_map(entry, '清單項目')))
          .toList();
      final ids = lists.map((list) => list.id).toSet();
      if (ids.length != lists.length) {
        throw const BackupFormatException('備份內含重複的清單識別碼');
      }

      return PackPlanBackup(
        lists: lists,
        settings: UserSettings(
          weightUnit: weightUnit,
          defaultWeightLimitGram: limit,
          themeMode: themeMode,
        ),
        exportedAt: DateTime.parse(_string(root['exportedAt'], '匯出時間')),
      );
    } on BackupFormatException {
      rethrow;
    } on FormatException {
      throw const BackupFormatException('備份檔不是有效的 JSON 格式');
    } on Object {
      throw const BackupFormatException('備份檔內容不完整或已損壞');
    }
  }

  static Map<String, Object?> _encodeList(PackList list) => {
    'id': list.id,
    'title': list.title,
    'tripType': list.tripType.name,
    'days': list.days,
    'nights': list.nights,
    'weatherConditions': list.weatherConditions
        .map((condition) => condition.name)
        .toList(),
    'weightLimitGram': list.weightLimitGram,
    'showWeight': list.showWeight,
    'createdAt': list.createdAt.toUtc().toIso8601String(),
    'updatedAt': list.updatedAt.toUtc().toIso8601String(),
    'items': list.items
        .map(
          (item) => {
            'id': item.id,
            'categoryId': item.categoryId,
            'categoryName': item.categoryName,
            'name': item.name,
            'weightGram': item.weightGram,
            'quantity': item.quantity,
            'checked': item.checked,
            'necessity': item.necessity.name,
            'sortOrder': item.sortOrder,
            'weightClass': item.weightClass.name,
            'isContainer': item.isContainer,
            'containerItemId': item.containerItemId,
          },
        )
        .toList(),
  };

  static PackList _decodeList(Map<String, Object?> json) {
    final tripTypeName = _string(json['tripType'], '行程類型');
    final tripType = TripType.values
        .where((type) => type.name == tripTypeName)
        .firstOrNull;
    if (tripType == null) {
      throw BackupFormatException('無效的行程類型：$tripTypeName');
    }

    final weather = _list(json['weatherConditions'], '天氣').map((entry) {
      final name = _string(entry, '天氣');
      return WeatherCondition.values
          .where((condition) => condition.name == name)
          .firstOrNull;
    }).toSet();
    if (weather.isEmpty || weather.contains(null)) {
      throw const BackupFormatException('清單的天氣設定無效');
    }

    final items = _list(
      json['items'],
      '裝備項目',
    ).map((entry) => _decodeItem(_map(entry, '裝備項目'))).toList();
    final itemIds = items.map((item) => item.id).toSet();
    if (itemIds.length != items.length) {
      throw const BackupFormatException('同一清單內含重複的裝備識別碼');
    }
    if (items.any(
      (item) =>
          item.containerItemId != null &&
          !itemIds.contains(item.containerItemId),
    )) {
      throw const BackupFormatException('裝備的放置位置不存在');
    }
    if (items.any(
      (item) =>
          (item.weightClass != WeightClass.packed && item.isContainer) ||
          (item.weightClass == WeightClass.worn &&
              item.containerItemId != null),
    )) {
      throw const BackupFormatException('重量類型與容器設定不相容');
    }

    return PackList(
      id: _nonEmptyString(json['id'], '清單識別碼'),
      title: _nonEmptyString(json['title'], '清單名稱'),
      tripType: tripType,
      days: _positiveInteger(json['days'], '天數'),
      nights: _nonNegativeInteger(json['nights'], '晚數'),
      weatherConditions: weather.cast<WeatherCondition>(),
      weightLimitGram: _positiveInteger(json['weightLimitGram'], '重量上限'),
      showWeight: json['showWeight'] == null
          ? true
          : _boolean(json['showWeight'], '顯示重量'),
      items: items,
      createdAt: DateTime.parse(_string(json['createdAt'], '建立時間')),
      updatedAt: DateTime.parse(_string(json['updatedAt'], '更新時間')),
    );
  }

  static PackItem _decodeItem(Map<String, Object?> json) {
    final necessityName = _string(json['necessity'], '必要性');
    final necessity = ItemNecessity.values
        .where((value) => value.name == necessityName)
        .firstOrNull;
    if (necessity == null) {
      throw BackupFormatException('無效的必要性：$necessityName');
    }
    final containerItemId = json['containerItemId'];
    if (containerItemId != null && containerItemId is! String) {
      throw const BackupFormatException('裝備的放置位置格式無效');
    }

    final weightClassName = json['weightClass'];
    final weightClass =
        weightClassName == null || weightClassName == 'consumable'
        ? WeightClass.packed
        : WeightClass.values
              .where((value) => value.name == weightClassName)
              .firstOrNull;
    if (weightClass == null) {
      throw BackupFormatException('無效的重量類型：$weightClassName');
    }

    return PackItem(
      id: _nonEmptyString(json['id'], '裝備識別碼'),
      categoryId: _nonEmptyString(json['categoryId'], '分類識別碼'),
      categoryName: _nonEmptyString(json['categoryName'], '分類名稱'),
      name: _nonEmptyString(json['name'], '裝備名稱'),
      weightGram: _nonNegativeInteger(json['weightGram'], '裝備重量'),
      quantity: _positiveInteger(json['quantity'], '裝備數量'),
      checked: _boolean(json['checked'], '打包狀態'),
      necessity: necessity,
      sortOrder: _nonNegativeInteger(json['sortOrder'], '排序'),
      weightClass: weightClass,
      isContainer: _boolean(json['isContainer'], '容器狀態'),
      containerItemId: containerItemId as String?,
    );
  }

  static Map<String, Object?> _map(Object? value, String field) {
    if (value is! Map) throw BackupFormatException('$field 格式無效');
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  static List<Object?> _list(Object? value, String field) {
    if (value is! List) throw BackupFormatException('$field 格式無效');
    return value;
  }

  static String _string(Object? value, String field) {
    if (value is! String) throw BackupFormatException('$field 格式無效');
    return value;
  }

  static String _nonEmptyString(Object? value, String field) {
    final result = _string(value, field).trim();
    if (result.isEmpty) throw BackupFormatException('$field 不可空白');
    return result;
  }

  static int _integer(Object? value, String field) {
    if (value is! int) throw BackupFormatException('$field 格式無效');
    return value;
  }

  static int _positiveInteger(Object? value, String field) {
    final result = _integer(value, field);
    if (result <= 0) throw BackupFormatException('$field 必須大於 0');
    return result;
  }

  static int _nonNegativeInteger(Object? value, String field) {
    final result = _integer(value, field);
    if (result < 0) throw BackupFormatException('$field 不可小於 0');
    return result;
  }

  static bool _boolean(Object? value, String field) {
    if (value is! bool) throw BackupFormatException('$field 格式無效');
    return value;
  }
}
