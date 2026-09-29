import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:packplan/data/weight_reference_repository.dart';
import 'package:packplan/models/gear_weight.dart';
import 'package:packplan/models/pack_item.dart';
import 'package:packplan/services/weight_reference_source.dart';

Map<String, Object?> _doc(String key, Map<String, Object?> fields) => {
  'name':
      'projects/packplan-86e9d/databases/(default)/documents/gear_weights/$key',
  'fields': fields,
};

GearWeight _weight(
  String key, {
  String? name,
  int grams = 100,
  String? parentKey,
  String? brand,
  List<String> aliases = const [],
  bool isActive = true,
  DateTime? updatedAt,
}) => GearWeight(
  key: key,
  nameZh: name ?? key,
  weightGram: grams,
  parentKey: parentKey,
  brand: brand,
  aliases: aliases,
  isActive: isActive,
  updatedAt: updatedAt ?? DateTime.utc(2026, 9, 1),
);

PackItem _item(String name, {String? catalogKey}) => PackItem(
  id: 'item-$name',
  categoryId: 'misc',
  categoryName: '其他',
  name: name,
  weightGram: 0,
  quantity: 1,
  checked: false,
  necessity: ItemNecessity.optional,
  sortOrder: 0,
  weightSource: WeightSource.unset,
  catalogKey: catalogKey,
);

class _FakeSource implements WeightReferenceSource {
  DateTime? version;
  List<GearWeight> rows = [];
  final List<DateTime?> sinceCalls = [];

  @override
  Future<DateTime?> fetchVersion() async => version;

  @override
  Future<List<GearWeight>> fetchUpdatedSince(DateTime? since) async {
    sinceCalls.add(since);
    return rows
        .where((row) => since == null || row.updatedAt.isAfter(since))
        .toList();
  }
}

void main() {
  group('FirestoreWeightReferenceSource', () {
    test('meta 不存在時版本為 null', () async {
      final source = FirestoreWeightReferenceSource(
        client: MockClient((_) async => http.Response('{}', 404)),
      );
      expect(await source.fetchVersion(), isNull);
    });

    test('解析 meta 版本時間', () async {
      final source = FirestoreWeightReferenceSource(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'fields': {
                'version': {'timestampValue': '2026-09-20T01:02:03Z'},
              },
            }),
            200,
          ),
        ),
      );
      expect(await source.fetchVersion(), DateTime.utc(2026, 9, 20, 1, 2, 3));
    });

    test('解析 Firestore 型別包裝值,並在 since 時帶 where 條件', () async {
      late Map<String, Object?> sentQuery;
      final source = FirestoreWeightReferenceSource(
        client: MockClient((request) async {
          sentQuery =
              (jsonDecode(request.body) as Map)['structuredQuery']
                  as Map<String, Object?>;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode([
                {
                  'document': _doc('osprey-exos-58', {
                    'nameZh': {'stringValue': 'Osprey Exos 58'},
                    'parentKey': {'stringValue': 'large-backpack'},
                    'brand': {'stringValue': 'Osprey'},
                    'aliases': {
                      'arrayValue': {
                        'values': [
                          {'stringValue': 'Exos 58'},
                        ],
                      },
                    },
                    'categoryId': {'nullValue': null},
                    'weightGram': {'integerValue': '1200'},
                    'weightMin': {'integerValue': '1100'},
                    'weightMax': {'integerValue': '1300'},
                    'note': {'nullValue': null},
                    'isActive': {'booleanValue': true},
                    'updatedAt': {'timestampValue': '2026-09-20T00:00:00Z'},
                  }),
                },
                {'readTime': '2026-09-24T00:00:00Z'},
              ]),
            ),
            200,
          );
        }),
      );

      final rows = await source.fetchUpdatedSince(DateTime.utc(2026, 9, 1));

      expect(sentQuery['where'], isNotNull);
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.key, 'osprey-exos-58');
      expect(row.nameZh, 'Osprey Exos 58');
      expect(row.parentKey, 'large-backpack');
      expect(row.aliases, ['Exos 58']);
      expect(row.categoryId, isNull);
      expect(row.weightGram, 1200);
      expect(row.hasRange, isTrue);
      expect(row.updatedAt, DateTime.utc(2026, 9, 20));
    });

    test('首次同步不帶 where', () async {
      late Map<String, Object?> sentQuery;
      final source = FirestoreWeightReferenceSource(
        client: MockClient((request) async {
          sentQuery =
              (jsonDecode(request.body) as Map)['structuredQuery']
                  as Map<String, Object?>;
          return http.Response('[{"readTime":"2026-09-24T00:00:00Z"}]', 200);
        }),
      );
      expect(await source.fetchUpdatedSince(null), isEmpty);
      expect(sentQuery.containsKey('where'), isFalse);
    });

    test('HTTP 錯誤轉成可顯示的例外', () async {
      final source = FirestoreWeightReferenceSource(
        client: MockClient((_) async => http.Response('', 403)),
      );
      expect(
        source.fetchUpdatedSince(null),
        throwsA(isA<WeightReferenceException>()),
      );
    });

    test('連線失敗轉成可顯示的例外', () async {
      final source = FirestoreWeightReferenceSource(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(source.fetchVersion(), throwsA(isA<WeightReferenceException>()));
    });
  });

  group('WeightReferenceRepository', () {
    late _FakeSource source;
    late InMemoryWeightReferenceCacheStore cache;
    late WeightReferenceRepository repository;

    setUp(() {
      source = _FakeSource();
      cache = InMemoryWeightReferenceCacheStore();
      repository = WeightReferenceRepository(source: source, cacheStore: cache);
    });

    test('首次同步抓全部,版本沒變就不再抓', () async {
      source
        ..version = DateTime.utc(2026, 9, 20)
        ..rows = [_weight('sleeping-bag', grams: 900)];

      expect(await repository.sync(), isTrue);
      expect(await repository.sync(), isFalse);

      expect(source.sinceCalls, [null]);
      expect(repository.lookup('sleeping-bag')?.weightGram, 900);
      expect(repository.version, DateTime.utc(2026, 9, 20));
    });

    test('版本更新時只抓快取中最新一筆之後的資料,並套用下架', () async {
      source
        ..version = DateTime.utc(2026, 9, 20)
        ..rows = [
          _weight('cup', updatedAt: DateTime.utc(2026, 9, 1)),
          _weight('stove', updatedAt: DateTime.utc(2026, 9, 5)),
        ];
      await repository.sync();

      source
        ..version = DateTime.utc(2026, 9, 22)
        ..rows = [
          ...source.rows,
          _weight('cup', isActive: false, updatedAt: DateTime.utc(2026, 9, 22)),
        ];
      await repository.sync();

      expect(source.sinceCalls.last, DateTime.utc(2026, 9, 5));
      expect(repository.lookup('cup'), isNull);
      expect(repository.lookup('stove'), isNotNull);
    });

    test('線上尚無資料時不會清掉快取', () async {
      source
        ..version = DateTime.utc(2026, 9, 20)
        ..rows = [_weight('cup')];
      await repository.sync();

      source.version = null;
      expect(await repository.sync(), isFalse);
      expect(repository.hasData, isTrue);
    });

    test('快取可被新的實例讀回(離線可用)', () async {
      source
        ..version = DateTime.utc(2026, 9, 20)
        ..rows = [_weight('sleeping-bag', grams: 900)];
      await repository.sync();

      final offline = WeightReferenceRepository(
        source: _FakeSource(),
        cacheStore: cache,
      );
      await offline.load();

      expect(offline.lookup('sleeping-bag')?.weightGram, 900);
      expect(offline.version, DateTime.utc(2026, 9, 20));
    });

    test('損毀的快取視為空白', () async {
      final broken = WeightReferenceRepository(
        source: source,
        cacheStore: InMemoryWeightReferenceCacheStore('not json'),
      );
      await broken.load();
      expect(broken.hasData, isFalse);
    });

    test('比對:範本 key 優先,再用正規化名稱/別名', () async {
      source
        ..version = DateTime.utc(2026, 9, 20)
        ..rows = [
          _weight('large-backpack', name: '大背包', grams: 1500),
          _weight(
            'osprey-exos-58',
            name: 'Osprey Exos 58',
            grams: 1200,
            parentKey: 'large-backpack',
            brand: 'Osprey',
            aliases: ['Exos 58'],
          ),
          _weight('headlamp', name: '頭燈', grams: 90, aliases: ['頭燈 LED']),
        ];
      await repository.sync();

      expect(
        repository.matchItem(_item('我的背包', catalogKey: 'large-backpack'))?.key,
        'large-backpack',
      );
      expect(
        repository.matchItem(_item('osprey exos58'))?.key,
        'osprey-exos-58',
      );
      expect(repository.matchItem(_item('EXOS 58'))?.key, 'osprey-exos-58');
      expect(repository.matchItem(_item('頭燈led'))?.key, 'headlamp');
      expect(repository.matchItem(_item('登山杖')), isNull);
    });

    test('search:多個關鍵字都要符合,可搜品牌/別名/所屬通用項目,已下架不列', () async {
      source
        ..version = DateTime.utc(2026, 9, 20)
        ..rows = [
          _weight('large-backpack', name: '大背包'),
          _weight(
            'osprey-exos-58',
            name: 'Osprey Exos 58',
            parentKey: 'large-backpack',
            brand: 'Osprey',
            aliases: ['Exos58'],
          ),
          _weight(
            'gregory-focal-48',
            name: 'Gregory Focal 48',
            parentKey: 'large-backpack',
            brand: 'Gregory',
          ),
          _weight('thermos', name: '保溫瓶', aliases: ['保溫杯']),
          _weight('old-pack', name: 'Osprey Old', isActive: false),
        ];
      await repository.sync();

      List<String> keys(String q) => [
        for (final hit in repository.search(q)) hit.key,
      ];

      expect(keys('osprey'), ['osprey-exos-58']);
      expect(keys('exos58'), ['osprey-exos-58']);
      expect(keys('osprey 58'), ['osprey-exos-58']);
      expect(keys('osprey 48'), isEmpty);
      // 所屬通用項目名稱也搜得到;名稱完全相符的通用項目排第一
      expect(keys('大背包'), [
        'large-backpack',
        'gregory-focal-48',
        'osprey-exos-58',
      ]);
      expect(keys('保溫杯'), ['thermos']);
      expect(keys('  '), isEmpty);
    });

    test('search:英數字從單字開頭比對,中文任何位置都算', () async {
      source
        ..version = DateTime.utc(2026, 9, 20)
        ..rows = [
          _weight('hydration-bladder', name: '水袋'),
          _weight(
            'hydrapak-seeker-3l',
            name: 'HydraPak Seeker 3L',
            parentKey: 'hydration-bladder',
            brand: 'HydraPak',
          ),
          _weight(
            'gregory-paragon-48',
            name: 'Gregory Paragon 48',
            brand: 'Gregory',
          ),
          _weight(
            'snowpeak-gst-120r',
            name: 'Snow Peak GP鈦金屬超輕量迷你瓦斯爐 GST-120R',
            brand: 'Snow Peak',
          ),
        ];
      await repository.sync();

      List<String> keys(String q) => [
        for (final hit in repository.search(q)) hit.key,
      ];

      // 「p」只找單字開頭是 p 的,不會找到 HydraPak(p 在字中間)
      expect(keys('p'), ['gregory-paragon-48', 'snowpeak-gst-120r']);
      expect(keys('hydra'), ['hydrapak-seeker-3l']);
      expect(keys('seeker 3l'), ['hydrapak-seeker-3l']);
      // 符號後也算單字開頭;中文字接英數也算
      expect(keys('120r'), ['snowpeak-gst-120r']);
      expect(keys('gst-120r'), ['snowpeak-gst-120r']);
      expect(keys('瓦斯爐'), ['snowpeak-gst-120r']);
      // 中文任何位置都算(所屬通用項目名稱也搜得到)
      expect(keys('袋'), ['hydration-bladder', 'hydrapak-seeker-3l']);
    });

    test('同名時通用項目優先於型號', () async {
      source
        ..version = DateTime.utc(2026, 9, 20)
        ..rows = [
          _weight('a-variant', name: '睡墊', parentKey: 'sleeping-pad'),
          _weight('sleeping-pad', name: '睡墊'),
        ];
      await repository.sync();

      expect(repository.matchItem(_item('睡墊'))?.key, 'sleeping-pad');
    });

    test('variantsOf 只列出上架的型號,依品牌排序', () async {
      source
        ..version = DateTime.utc(2026, 9, 20)
        ..rows = [
          _weight('large-backpack', name: '大背包'),
          _weight(
            'osprey-exos-58',
            name: 'Osprey Exos 58',
            parentKey: 'large-backpack',
            brand: 'Osprey',
          ),
          _weight(
            'gossamer-mariposa-60',
            name: 'Gossamer Mariposa 60',
            parentKey: 'large-backpack',
            brand: 'Gossamer',
          ),
          _weight(
            'old-model',
            parentKey: 'large-backpack',
            brand: 'Aaa',
            isActive: false,
          ),
        ];
      await repository.sync();

      expect(repository.variantsOf('large-backpack').map((w) => w.key), [
        'gossamer-mariposa-60',
        'osprey-exos-58',
      ]);
    });
  });
}
