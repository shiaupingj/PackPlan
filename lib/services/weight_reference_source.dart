import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/gear_weight.dart';

/// 可顯示給使用者的參考重量錯誤訊息。
class WeightReferenceException implements Exception {
  const WeightReferenceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 線上參考重量的資料來源;測試可注入 fake。
abstract interface class WeightReferenceSource {
  /// `meta/gear_weights.version`;線上尚無資料時回傳 null。
  Future<DateTime?> fetchVersion();

  /// [since] 之後有更新的資料(含已下架者);[since] 為 null 時回傳全部。
  Future<List<GearWeight>> fetchUpdatedSince(DateTime? since);
}

/// 沒有線上資料的來源:測試與未注入時的預設,避免意外連網。
class EmptyWeightReferenceSource implements WeightReferenceSource {
  const EmptyWeightReferenceSource();

  @override
  Future<DateTime?> fetchVersion() async => null;

  @override
  Future<List<GearWeight>> fetchUpdatedSince(DateTime? since) async => [];
}

/// 以 Firestore REST API 讀取(規則允許未登入讀取,不需金鑰或原生 SDK)。
class FirestoreWeightReferenceSource implements WeightReferenceSource {
  FirestoreWeightReferenceSource({
    http.Client? client,
    this.projectId = 'packplan-86e9d',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String projectId;

  static const _timeout = Duration(seconds: 15);

  String get _documentsUrl =>
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents';

  @override
  Future<DateTime?> fetchVersion() async {
    final response = await _send(
      () => _client.get(Uri.parse('$_documentsUrl/meta/gear_weights')),
    );
    if (response.statusCode == 404) return null;
    _ensureOk(response);
    final fields = _fieldsOf(_decodeObject(response.body));
    final version = fields['version'];
    return version is DateTime ? version : null;
  }

  @override
  Future<List<GearWeight>> fetchUpdatedSince(DateTime? since) async {
    final query = <String, Object?>{
      'from': [
        {'collectionId': 'gear_weights'},
      ],
      if (since != null)
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'updatedAt'},
            'op': 'GREATER_THAN',
            'value': {'timestampValue': since.toUtc().toIso8601String()},
          },
        },
    };
    final response = await _send(
      () => _client.post(
        Uri.parse('$_documentsUrl:runQuery'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'structuredQuery': query}),
      ),
    );
    _ensureOk(response);

    final rows = jsonDecode(response.body);
    if (rows is! List) throw const WeightReferenceException('線上參考重量格式錯誤');
    return [
      for (final row in rows)
        if (row is Map && row['document'] is Map)
          _parseDocument((row['document'] as Map).cast<String, Object?>()),
    ];
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw const WeightReferenceException('連線逾時，請稍後再試');
    } on http.ClientException {
      throw const WeightReferenceException('目前無法連線，請確認網路後再試');
    }
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode != 200) {
      throw WeightReferenceException('無法取得線上參考重量（HTTP ${response.statusCode}）');
    }
  }

  Map<String, Object?> _decodeObject(String body) {
    final json = jsonDecode(body);
    if (json is! Map) throw const WeightReferenceException('線上參考重量格式錯誤');
    return json.cast<String, Object?>();
  }

  GearWeight _parseDocument(Map<String, Object?> document) {
    final name = document['name'] as String? ?? '';
    final fields = _fieldsOf(document);
    try {
      return GearWeight(
        key: name.split('/').last,
        nameZh: fields['nameZh']! as String,
        parentKey: fields['parentKey'] as String?,
        brand: fields['brand'] as String?,
        aliases: (fields['aliases'] as List<Object?>? ?? const [])
            .whereType<String>()
            .toList(),
        categoryId: fields['categoryId'] as String?,
        weightGram: fields['weightGram']! as int,
        weightMin: fields['weightMin'] as int?,
        weightMax: fields['weightMax'] as int?,
        note: fields['note'] as String?,
        isActive: fields['isActive'] as bool? ?? true,
        updatedAt: fields['updatedAt']! as DateTime,
      );
    } on TypeError {
      throw WeightReferenceException('線上參考重量資料不完整：${name.split('/').last}');
    }
  }

  /// 把 Firestore 的型別包裝值(`{"stringValue": ...}` 等)轉成 Dart 值。
  static Map<String, Object?> _fieldsOf(Map<String, Object?> document) {
    final fields = document['fields'];
    if (fields is! Map) return const {};
    return {
      for (final entry in fields.entries)
        entry.key as String: _unwrap(entry.value),
    };
  }

  static Object? _unwrap(Object? value) {
    if (value is! Map) return null;
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('integerValue')) {
      return int.tryParse('${value['integerValue']}');
    }
    if (value.containsKey('doubleValue')) {
      return (value['doubleValue'] as num).round();
    }
    if (value.containsKey('booleanValue')) return value['booleanValue'];
    if (value.containsKey('timestampValue')) {
      return DateTime.tryParse('${value['timestampValue']}');
    }
    if (value.containsKey('arrayValue')) {
      final values = (value['arrayValue'] as Map?)?['values'];
      return values is List ? values.map(_unwrap).toList() : <Object?>[];
    }
    return null;
  }
}
