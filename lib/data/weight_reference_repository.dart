import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/gear_weight.dart';
import '../models/pack_item.dart';
import '../services/weight_reference_source.dart';

/// 參考重量的本機快取;測試可用 [InMemoryWeightReferenceCacheStore]。
abstract interface class WeightReferenceCacheStore {
  Future<String?> read();
  Future<void> write(String contents);
}

/// 快取成 JSON 檔,放在 App 資料庫同一個資料夾。
class FileWeightReferenceCacheStore implements WeightReferenceCacheStore {
  static const _fileName = 'gear_weights_cache.json';

  Future<File> _file() async =>
      File(path.join(await getDatabasesPath(), _fileName));

  @override
  Future<String?> read() async {
    final file = await _file();
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String contents) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(contents);
  }
}

class InMemoryWeightReferenceCacheStore implements WeightReferenceCacheStore {
  InMemoryWeightReferenceCacheStore([this.contents]);

  String? contents;

  @override
  Future<String?> read() async => contents;

  @override
  Future<void> write(String contents) async => this.contents = contents;
}

/// 線上參考重量:本機快取 + 增量同步 + 項目比對。
///
/// 同步時先讀 `meta` 版本(1 次讀取),版本有變才抓 `updatedAt` 晚於快取中最新
/// 一筆的資料,所以離線時仍可用快取補重量。
class WeightReferenceRepository extends ChangeNotifier {
  WeightReferenceRepository({
    required WeightReferenceSource source,
    required WeightReferenceCacheStore cacheStore,
  }) : _source = source,
       _cacheStore = cacheStore;

  final WeightReferenceSource _source;
  final WeightReferenceCacheStore _cacheStore;

  final Map<String, GearWeight> _entries = {};
  Map<String, GearWeight> _byName = const {};
  DateTime? _version;
  DateTime? _syncedAt;
  bool _loaded = false;
  bool _syncing = false;
  Future<void>? _loading;

  /// 線上資料版本時間(顯示「更新於」用);尚未同步過為 null。
  DateTime? get version => _version;
  DateTime? get syncedAt => _syncedAt;
  bool get isSyncing => _syncing;
  bool get hasData => _entries.values.any((entry) => entry.isActive);

  Future<void> load() => _loading ??= _loadFromCache();

  Future<void> _loadFromCache() async {
    try {
      final contents = await _cacheStore.read();
      if (contents != null) {
        final json = (jsonDecode(contents) as Map).cast<String, Object?>();
        _version = _parseDate(json['version']);
        _syncedAt = _parseDate(json['syncedAt']);
        for (final raw in json['entries']! as List<Object?>) {
          final entry = GearWeight.fromJson(
            (raw! as Map).cast<String, Object?>(),
          );
          _entries[entry.key] = entry;
        }
      }
    } on Object catch (error) {
      // 快取損毀就當作沒有快取,下次同步會重新下載全部。
      debugPrint('Ignoring unreadable weight reference cache: $error');
      _entries.clear();
      _version = null;
      _syncedAt = null;
    }
    _rebuildIndex();
    _loaded = true;
    notifyListeners();
  }

  /// 與線上同步;有新資料回傳 true。失敗時丟 [WeightReferenceException],
  /// 快取維持原狀。
  Future<bool> sync() async {
    if (_syncing) return false;
    await load();
    _syncing = true;
    notifyListeners();
    try {
      final remoteVersion = await _source.fetchVersion();
      if (remoteVersion == null || remoteVersion == _version) {
        _syncedAt = DateTime.now();
        await _saveCache();
        return false;
      }

      final updates = await _source.fetchUpdatedSince(_latestUpdatedAt());
      for (final entry in updates) {
        _entries[entry.key] = entry;
      }
      _version = remoteVersion;
      _syncedAt = DateTime.now();
      _rebuildIndex();
      await _saveCache();
      return updates.isNotEmpty;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  GearWeight? lookup(String key) {
    final entry = _entries[key];
    return entry != null && entry.isActive ? entry : null;
  }

  /// 先用範本 key,再用正規化後的名稱/別名比對;都沒有回傳 null。
  GearWeight? matchItem(PackItem item) {
    assert(_loaded, 'Call load() before matching items.');
    final byKey = item.catalogKey == null ? null : lookup(item.catalogKey!);
    return byKey ?? _byName[normalizeName(item.name)];
  }

  /// 掛在 [key] 底下的品牌型號,依品牌、名稱排序。
  List<GearWeight> variantsOf(String key) {
    return _entries.values
        .where((entry) => entry.isActive && entry.parentKey == key)
        .toList()
      ..sort((a, b) {
        final byBrand = (a.brand ?? '').compareTo(b.brand ?? '');
        return byBrand != 0 ? byBrand : a.nameZh.compareTo(b.nameZh);
      });
  }

  /// 比對用:轉小寫並去掉所有空白,「Exos 58」與「exos58」視為相同。
  static String normalizeName(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'\s+'), '');

  void _rebuildIndex() {
    // 同名時通用項目優先於型號,其次依 key 排序,確保結果固定。
    final active = _entries.values.where((entry) => entry.isActive).toList()
      ..sort((a, b) {
        if (a.isVariant != b.isVariant) return a.isVariant ? 1 : -1;
        return a.key.compareTo(b.key);
      });
    final index = <String, GearWeight>{};
    for (final entry in active) {
      for (final name in [entry.nameZh, ...entry.aliases]) {
        index.putIfAbsent(normalizeName(name), () => entry);
      }
    }
    _byName = index;
  }

  DateTime? _latestUpdatedAt() {
    DateTime? latest;
    for (final entry in _entries.values) {
      if (latest == null || entry.updatedAt.isAfter(latest)) {
        latest = entry.updatedAt;
      }
    }
    return latest;
  }

  Future<void> _saveCache() {
    return _cacheStore.write(
      jsonEncode({
        'version': _version?.toUtc().toIso8601String(),
        'syncedAt': _syncedAt?.toUtc().toIso8601String(),
        'entries': _entries.values.map((entry) => entry.toJson()).toList(),
      }),
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
