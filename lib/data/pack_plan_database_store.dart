import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

abstract interface class PackPlanStateStore {
  Future<Uint8List?> load();
  Future<void> save(Uint8List bytes);
  Future<void> close();
}

class PackPlanDatabaseStore implements PackPlanStateStore {
  PackPlanDatabaseStore._(this._database);

  static const _databaseName = 'packplan.db';
  static const _databaseVersion = 1;
  static const _table = 'app_state';
  static const _stateId = 1;

  final Database _database;

  static Future<PackPlanDatabaseStore> open() async {
    final databasePath = await _path();
    final database = await openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE $_table ('
          'id INTEGER PRIMARY KEY, '
          'payload BLOB NOT NULL, '
          'updated_at TEXT NOT NULL'
          ')',
        );
      },
    );
    return PackPlanDatabaseStore._(database);
  }

  static Future<void> reset() async {
    await deleteDatabase(await _path());
  }

  static Future<String> _path() async {
    return path.join(await getDatabasesPath(), _databaseName);
  }

  @override
  Future<Uint8List?> load() async {
    final rows = await _database.query(
      _table,
      columns: const ['payload'],
      where: 'id = ?',
      whereArgs: const [_stateId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final payload = rows.single['payload'];
    if (payload is Uint8List) return payload;
    if (payload is List<int>) return Uint8List.fromList(payload);
    throw const FormatException('Invalid PackPlan database payload.');
  }

  @override
  Future<void> save(Uint8List bytes) async {
    await _database.insert(_table, {
      'id': _stateId,
      'payload': bytes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> close() => _database.close();
}
