import 'package:flutter_test/flutter_test.dart';
import 'package:smoking_habit/data/datasources/sqlite_smoking_local_datasource.dart';
import 'package:smoking_habit/data/models/smoking_record_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SqliteSmokingLocalDataSource dataSource;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ${SqliteSmokingLocalDataSource.tableName} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp TEXT NOT NULL,
              count INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE INDEX idx_${SqliteSmokingLocalDataSource.tableName}_timestamp 
            ON ${SqliteSmokingLocalDataSource.tableName} (timestamp)
          ''');
        },
      ),
    );

    dataSource = SqliteSmokingLocalDataSource(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SqliteSmokingLocalDataSource In-Memory SQLite Test', () {
    final t1 = DateTime(2026, 10, 9, 10, 0);
    final t2 = DateTime(2026, 10, 9, 12, 0);

    test('insertRecord и getAllRecords работают корректно', () async {
      final model1 = SmokingRecordModel(timestamp: t1, count: 1);
      final model2 = SmokingRecordModel(timestamp: t2, count: 2);

      final inserted1 = await dataSource.insertRecord(model1);
      final inserted2 = await dataSource.insertRecord(model2);

      expect(inserted1.id, isNotNull);
      expect(inserted2.id, isNotNull);

      final all = await dataSource.getAllRecords();
      expect(all.length, equals(2));
      // Проверка сортировки DESC: сначала более новая запись t2
      expect(all.first.timestamp, equals(t2));
      expect(all.first.count, equals(2));
    });

    test('getRecordsByDateRange фильтрует записи по датам', () async {
      await dataSource.insertRecord(SmokingRecordModel(timestamp: t1, count: 1));
      await dataSource.insertRecord(SmokingRecordModel(timestamp: t2, count: 2));

      final rangeResults = await dataSource.getRecordsByDateRange(
        DateTime(2026, 10, 9, 11, 0),
        DateTime(2026, 10, 9, 13, 0),
      );

      expect(rangeResults.length, equals(1));
      expect(rangeResults.first.count, equals(2));
    });

    test('updateRecord обновляет существующую запись', () async {
      final inserted = await dataSource.insertRecord(
        SmokingRecordModel(timestamp: t1, count: 1),
      );

      final updatedModel = inserted.copyWith(count: 5);
      await dataSource.updateRecord(updatedModel);

      final all = await dataSource.getAllRecords();
      expect(all.length, equals(1));
      expect(all.first.count, equals(5));
    });

    test('deleteRecord удаляет запись по id', () async {
      final inserted = await dataSource.insertRecord(
        SmokingRecordModel(timestamp: t1, count: 1),
      );

      await dataSource.deleteRecord(inserted.id!);

      final all = await dataSource.getAllRecords();
      expect(all.isEmpty, isTrue);
    });
  });
}
