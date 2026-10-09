import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smoking_habit/core/services/auto_start_service.dart';
import 'package:smoking_habit/data/datasources/smoking_local_datasource.dart';
import 'package:smoking_habit/data/models/smoking_record_model.dart';
import 'package:smoking_habit/data/repositories/smoking_repository_impl.dart';
import 'package:smoking_habit/presentation/bloc/smoking_bloc.dart';
import 'package:smoking_habit/presentation/bloc/smoking_event.dart';
import 'package:smoking_habit/presentation/pages/settings_page.dart';

class FakeAutoStartService implements AutoStartService {
  bool enabled = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool value) async {
    enabled = value;
  }
}

class FakeLocalDataSource implements SmokingLocalDataSource {
  final List<SmokingRecordModel> records = [];

  @override
  Future<List<SmokingRecordModel>> getAllRecords() async => records;

  @override
  Future<List<SmokingRecordModel>> getRecordsByDateRange(DateTime start, DateTime end) async => records;

  @override
  Future<SmokingRecordModel> insertRecord(SmokingRecordModel record) async {
    records.add(record);
    return record;
  }

  @override
  Future<void> insertAllRecords(List<SmokingRecordModel> items) async {
    records.addAll(items);
  }

  @override
  Future<void> updateRecord(SmokingRecordModel record) async {}

  @override
  Future<void> deleteRecord(int id) async {}

  @override
  Future<void> clearAllRecords() async {
    records.clear();
  }
}

void main() {
  testWidgets('SettingsPage отображает переключатель автозапуска и реагирует на нажатие', (tester) async {
    final fakeAutoStart = FakeAutoStartService();
    final fakeDataSource = FakeLocalDataSource();
    final repository = SmokingRepositoryImpl(fakeDataSource);
    final bloc = SmokingBloc(repository)..add(const LoadSmokingRecords());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocSignalProvider<SmokingBloc>.value(
          value: bloc,
          child: Scaffold(
            body: SettingsPage(autoStartService: fakeAutoStart),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Проверяем отображение заголовка автозапуска
    expect(find.text('Запуск при старте Windows'), findsOneWidget);
    expect(find.text('Система и автозапуск'), findsOneWidget);

    // Находим переключатель Switch
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    // Переключаем Switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Проверяем, что состояние изменилось в сервисе
    expect(fakeAutoStart.enabled, isTrue);
  });
}
