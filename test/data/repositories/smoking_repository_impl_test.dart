import 'package:flutter_test/flutter_test.dart';
import 'package:smoking_habit/core/error/failures.dart';
import 'package:smoking_habit/data/datasources/smoking_local_datasource.dart';
import 'package:smoking_habit/data/models/smoking_record_model.dart';
import 'package:smoking_habit/data/repositories/smoking_repository_impl.dart';
import 'package:smoking_habit/domain/entities/smoking_record.dart';

class FakeSmokingLocalDataSource implements SmokingLocalDataSource {
  final List<SmokingRecordModel> records = [];
  bool shouldThrow = false;
  int _nextId = 1;

  @override
  Future<List<SmokingRecordModel>> getAllRecords() async {
    if (shouldThrow) throw Exception('DB connection lost');
    return List.from(records)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<SmokingRecordModel>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    if (shouldThrow) throw Exception('DB query error');
    return records
        .where(
          (r) =>
              (r.timestamp.isAfter(start) || r.timestamp.isAtSameMomentAs(start)) &&
              (r.timestamp.isBefore(end) || r.timestamp.isAtSameMomentAs(end)),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<SmokingRecordModel> insertRecord(SmokingRecordModel record) async {
    if (shouldThrow) throw Exception('DB insert error');
    final saved = record.copyWith(id: _nextId++);
    records.add(saved);
    return saved;
  }

  @override
  Future<void> updateRecord(SmokingRecordModel record) async {
    if (shouldThrow) throw Exception('DB update error');
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
    }
  }

  @override
  Future<void> deleteRecord(int id) async {
    if (shouldThrow) throw Exception('DB delete error');
    records.removeWhere((r) => r.id == id);
  }
}

void main() {
  late FakeSmokingLocalDataSource fakeDataSource;
  late SmokingRepositoryImpl repository;

  setUp(() {
    fakeDataSource = FakeSmokingLocalDataSource();
    repository = SmokingRepositoryImpl(fakeDataSource);
  });

  group('SmokingRepositoryImpl', () {
    final now = DateTime(2026, 10, 9, 12, 0);

    test('addRecord успешно добавляет запись и возвращает Result.success', () async {
      final record = SmokingRecord(timestamp: now, count: 2);
      final result = await repository.addRecord(record);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.id, equals(1));
      expect(result.dataOrNull?.count, equals(2));
      expect(fakeDataSource.records.length, equals(1));
    });

    test('addRecord возвращает ValidationFailure при count <= 0', () async {
      final invalidRecord = SmokingRecord(timestamp: now, count: 0);
      final result = await repository.addRecord(invalidRecord);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('getAllRecords возвращает список записей или DatabaseFailure при ошибке', () async {
      await repository.addRecord(SmokingRecord(timestamp: now, count: 1));
      
      final result = await repository.getAllRecords();
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.length, equals(1));

      fakeDataSource.shouldThrow = true;
      final failureResult = await repository.getAllRecords();
      expect(failureResult.isFailure, isTrue);
      expect(failureResult.failureOrNull, isA<DatabaseFailure>());
    });

    test('getRecordsByDateRange возвращает ValidationFailure при некорректном диапазоне', () async {
      final result = await repository.getRecordsByDateRange(
        DateTime(2026, 10, 10),
        DateTime(2026, 10, 9),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('deleteRecord успешно удаляет запись', () async {
      final addRes = await repository.addRecord(
        SmokingRecord(timestamp: now, count: 1),
      );
      final id = addRes.dataOrNull!.id!;

      final delRes = await repository.deleteRecord(id);
      expect(delRes.isSuccess, isTrue);
      expect(fakeDataSource.records.isEmpty, isTrue);
    });
  });
}
