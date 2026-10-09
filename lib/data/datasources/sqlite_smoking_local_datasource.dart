import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/smoking_record_model.dart';
import 'smoking_local_datasource.dart';

/// Реализация локального источника данных на базе SQLite.
class SqliteSmokingLocalDataSource implements SmokingLocalDataSource {
  /// Имя таблицы записей в базе данных.
  static const String tableName = 'smoking_records';

  /// Имя файла базы данных.
  static const String databaseFileName = 'smoking_habit.db';

  /// Версия схемы базы данных.
  static const int databaseVersion = 1;

  Database? _databaseInstance;
  final Future<Database> Function()? _customDbFactory;

  /// Конструктор с возможностью внедрения готового экземпляра БД (для тестов).
  SqliteSmokingLocalDataSource({
    Database? database,
    Future<Database> Function()? customDbProvider,
  })  : _databaseInstance = database,
        _customDbFactory = customDbProvider;

  /// Получение инициализированного экземпляра базы данных.
  Future<Database> get database async {
    if (_customDbFactory != null) {
      return await _customDbFactory();
    }
    if (_databaseInstance != null) {
      return _databaseInstance!;
    }
    _databaseInstance = await _initDatabase();
    return _databaseInstance!;
  }

  /// Инициализация подключения к БД.
  Future<Database> _initDatabase() async {
    // Для Windows, Linux и тестового окружения инициализируем FFI фабрику
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, databaseFileName);

    return await openDatabase(
      fullPath,
      version: databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// Создание таблиц и индексов базы данных.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        count INTEGER NOT NULL
      )
    ''');

    // Индекс для ускорения выборки по диапазону дат
    await db.execute('''
      CREATE INDEX idx_${tableName}_timestamp ON $tableName (timestamp)
    ''');
  }

  @override
  Future<List<SmokingRecordModel>> getAllRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'timestamp DESC',
    );

    return maps.map(SmokingRecordModel.fromMap).toList();
  }

  @override
  Future<List<SmokingRecordModel>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [startIso, endIso],
      orderBy: 'timestamp DESC',
    );

    return maps.map(SmokingRecordModel.fromMap).toList();
  }

  @override
  Future<SmokingRecordModel> insertRecord(SmokingRecordModel record) async {
    final db = await database;
    final id = await db.insert(
      tableName,
      record.toMap(includeId: false),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return record.copyWith(id: id);
  }

  @override
  Future<void> updateRecord(SmokingRecordModel record) async {
    if (record.id == null) {
      throw ArgumentError('Невозможно обновить запись без id');
    }

    final db = await database;
    await db.update(
      tableName,
      record.toMap(includeId: true),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  @override
  Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> insertAllRecords(List<SmokingRecordModel> records) async {
    if (records.isEmpty) return;
    final db = await database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final record in records) {
        batch.insert(
          tableName,
          record.toMap(includeId: false),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> clearAllRecords() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableName);
      // Сброс autoincrement последовательности
      await txn.rawDelete(
        "DELETE FROM sqlite_sequence WHERE name = ?",
        [tableName],
      );
    });
  }

  /// Закрытие соединения с БД.
  Future<void> close() async {
    if (_databaseInstance != null && _databaseInstance!.isOpen) {
      await _databaseInstance!.close();
      _databaseInstance = null;
    }
  }
}
