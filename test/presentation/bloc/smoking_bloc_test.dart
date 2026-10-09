import 'package:flutter_test/flutter_test.dart';
import 'package:smoking_habit/data/datasources/smoking_local_datasource.dart';
import 'package:smoking_habit/data/models/smoking_record_model.dart';
import 'package:smoking_habit/data/repositories/smoking_repository_impl.dart';
import 'package:smoking_habit/domain/entities/smoking_record.dart';
import 'package:smoking_habit/domain/entities/stats_period.dart';
import 'package:smoking_habit/presentation/bloc/smoking_bloc.dart';
import 'package:smoking_habit/presentation/bloc/smoking_event.dart';
import 'package:smoking_habit/presentation/bloc/smoking_state.dart';

class FakeLocalDataSource implements SmokingLocalDataSource {
  final List<SmokingRecordModel> records = [];
  int _idCounter = 1;

  @override
  Future<List<SmokingRecordModel>> getAllRecords() async {
    return List.from(records)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<SmokingRecordModel>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return records
        .where((r) =>
            (r.timestamp.isAfter(start) || r.timestamp.isAtSameMomentAs(start)) &&
            (r.timestamp.isBefore(end) || r.timestamp.isAtSameMomentAs(end)))
        .toList();
  }

  @override
  Future<SmokingRecordModel> insertRecord(SmokingRecordModel record) async {
    final saved = record.copyWith(id: _idCounter++);
    records.add(saved);
    return saved;
  }

  @override
  Future<void> insertAllRecords(List<SmokingRecordModel> items) async {
    for (final item in items) {
      records.add(item.copyWith(id: _idCounter++));
    }
  }

  @override
  Future<void> updateRecord(SmokingRecordModel record) async {
    final idx = records.indexWhere((r) => r.id == record.id);
    if (idx != -1) records[idx] = record;
  }

  @override
  Future<void> deleteRecord(int id) async {
    records.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> clearAllRecords() async {
    records.clear();
  }
}

void main() {
  late FakeLocalDataSource dataSource;
  late SmokingRepositoryImpl repository;
  late SmokingBloc bloc;

  setUp(() {
    dataSource = FakeLocalDataSource();
    repository = SmokingRepositoryImpl(dataSource);
    bloc = SmokingBloc(repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('SmokingBloc Tests', () {
    test('начальное состояние — SmokingInitial', () {
      expect(bloc.state.value, isA<SmokingInitial>());
    });

    test('LoadSmokingRecords загружает записи и выставляет SmokingLoaded', () async {
      final now = DateTime.now();
      await repository.addRecord(SmokingRecord(timestamp: now, count: 1));

      bloc.add(const LoadSmokingRecords());
      // Даем время на выполнение асинхронного события
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = bloc.state.value;
      expect(state, isA<SmokingLoaded>());
      final loaded = state as SmokingLoaded;
      expect(loaded.records.length, equals(1));
      expect(loaded.todayCount, equals(1));
      expect(loaded.totalCount, equals(1));
    });

    test('AddSmokingRecord добавляет запись и обновляет список', () async {
      bloc.add(const AddSmokingRecord(count: 2));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = bloc.state.value;
      expect(state, isA<SmokingLoaded>());
      final loaded = state as SmokingLoaded;
      expect(loaded.records.length, equals(1));
      expect(loaded.todayCount, equals(2));
      expect(loaded.totalCount, equals(2));
    });

    test('DeleteSmokingRecord удаляет запись по id', () async {
      bloc.add(const AddSmokingRecord(count: 1));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final loadedState = bloc.state.value as SmokingLoaded;
      final recordId = loadedState.records.first.id!;

      bloc.add(DeleteSmokingRecord(recordId));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final finalState = bloc.state.value as SmokingLoaded;
      expect(finalState.records.isEmpty, isTrue);
      expect(finalState.todayCount, equals(0));
    });

    test('DeleteLatestSmokingRecord удаляет последнюю запись', () async {
      bloc.add(const AddSmokingRecord(count: 1));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      bloc.add(const AddSmokingRecord(count: 3));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final stateBefore = bloc.state.value as SmokingLoaded;
      expect(stateBefore.records.length, equals(2));
      expect(stateBefore.totalCount, equals(4));

      bloc.add(const DeleteLatestSmokingRecord());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final stateAfter = bloc.state.value as SmokingLoaded;
      expect(stateAfter.records.length, equals(1));
      expect(stateAfter.totalCount, equals(1));
    });

    test('SmokingLoaded корректно формирует срез last7DaysSummary и averagePerDay', () async {
      final now = DateTime.now();
      final day1 = now.subtract(const Duration(days: 1));
      final day2 = now.subtract(const Duration(days: 2));

      await repository.addRecord(SmokingRecord(timestamp: now, count: 2));
      await repository.addRecord(SmokingRecord(timestamp: day1, count: 3));
      await repository.addRecord(SmokingRecord(timestamp: day2, count: 5));

      bloc.add(const LoadSmokingRecords());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = bloc.state.value as SmokingLoaded;
      expect(state.last7DaysSummary.length, equals(7));
      expect(state.last7DaysSummary.last.isToday, isTrue);
      expect(state.last7DaysSummary.last.count, equals(2));
      expect(state.totalCount, equals(10));
      expect(state.averagePerDayLast7Days, closeTo(10 / 7.0, 0.01));
      expect(state.maxCountInLast7Days, equals(5));
    });

    test('getPeriodSummary корректно рассчитывает данные для всех периодов', () async {
      final now = DateTime(2026, 10, 9, 12, 0);
      final monthAgo = DateTime(2026, 9, 15, 12, 0);
      final threeMonthsAgo = DateTime(2026, 7, 10, 12, 0);

      await repository.addRecord(SmokingRecord(timestamp: now, count: 4));
      await repository.addRecord(SmokingRecord(timestamp: monthAgo, count: 6));
      await repository.addRecord(SmokingRecord(timestamp: threeMonthsAgo, count: 10));

      bloc.add(const LoadSmokingRecords());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = bloc.state.value as SmokingLoaded;

      // Тест недели
      final weekSummary = state.getPeriodSummary(StatsPeriod.week, now);
      expect(weekSummary.dataPoints.length, equals(7));
      expect(weekSummary.totalCount, equals(4));

      // Тест месяца
      final monthSummary = state.getPeriodSummary(StatsPeriod.month, now);
      expect(monthSummary.dataPoints.length, equals(30));
      expect(monthSummary.totalCount, equals(10)); // 4 (сегодня) + 6 (24 дня назад)

      // Тест 6 месяцев
      final sixMonthsSummary = state.getPeriodSummary(StatsPeriod.sixMonths, now);
      expect(sixMonthsSummary.dataPoints.length, equals(6));
      expect(sixMonthsSummary.totalCount, equals(20)); // 4 + 6 + 10

      // Тест года
      final yearSummary = state.getPeriodSummary(StatsPeriod.year, now);
      expect(yearSummary.dataPoints.length, equals(12));
      expect(yearSummary.totalCount, equals(20));
    });

    test('ClearAllSmokingRecords очищает базу и выставляет пустой SmokingLoaded', () async {
      bloc.add(const AddSmokingRecord(count: 2));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect((bloc.state.value as SmokingLoaded).records.length, equals(1));

      bloc.add(const ClearAllSmokingRecords());
      await Future<void>.delayed(const Duration(milliseconds: 40));

      final state = bloc.state.value as SmokingLoaded;
      expect(state.records.isEmpty, isTrue);
      expect(state.totalCount, equals(0));
    });

    test('ImportSmokingRecordsFromJson импортирует записи', () async {
      const jsonBackup = '{"records":[{"timestamp":"2026-10-09T10:00:00.000","count":5}]}';

      bloc.add(const ImportSmokingRecordsFromJson(jsonContent: jsonBackup, replaceExisting: true));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = bloc.state.value as SmokingLoaded;
      expect(state.records.length, equals(1));
      expect(state.totalCount, equals(5));
    });
  });
}
