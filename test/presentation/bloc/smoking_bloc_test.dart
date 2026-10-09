import 'package:flutter_test/flutter_test.dart';
import 'package:smoking_habit/data/datasources/smoking_local_datasource.dart';
import 'package:smoking_habit/data/models/smoking_record_model.dart';
import 'package:smoking_habit/data/repositories/smoking_repository_impl.dart';
import 'package:smoking_habit/domain/entities/smoking_record.dart';
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
  Future<void> updateRecord(SmokingRecordModel record) async {
    final idx = records.indexWhere((r) => r.id == record.id);
    if (idx != -1) records[idx] = record;
  }

  @override
  Future<void> deleteRecord(int id) async {
    records.removeWhere((r) => r.id == id);
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
  });
}
