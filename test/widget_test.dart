import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smoking_habit/data/datasources/smoking_local_datasource.dart';
import 'package:smoking_habit/data/models/smoking_record_model.dart';
import 'package:smoking_habit/data/repositories/smoking_repository_impl.dart';
import 'package:smoking_habit/main.dart';
import 'package:smoking_habit/presentation/bloc/smoking_bloc.dart';
import 'package:smoking_habit/presentation/bloc/smoking_event.dart';

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
    return records;
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
  testWidgets('Smoke test: добавление сигареты и переключение на экран статистики', (WidgetTester tester) async {
    final fakeDataSource = FakeLocalDataSource();
    final repository = SmokingRepositoryImpl(fakeDataSource);
    final bloc = SmokingBloc(repository)..add(const LoadSmokingRecords());

    await tester.pumpWidget(SmokingHabitApp(smokingBloc: bloc));
    await tester.pumpAndSettle();

    // Проверяем отображение заголовка и статистики на главной
    expect(find.widgetWithText(AppBar, 'Учёт сигарет'), findsOneWidget);
    expect(find.text('Сегодня'), findsOneWidget);
    expect(find.text('Всего'), findsOneWidget);

    // Нажимаем кнопку добавления выкуренной сигареты
    final addButton = find.text('Выкурил сигарету (+1)');
    expect(addButton, findsOneWidget);

    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Проверяем, что счетчики обновились
    expect(find.text('1'), findsWidgets);
    expect(find.text('История записей'), findsOneWidget);

    // Переключаемся на вкладку "Статистика" в нижней панели навигации
    final statsTab = find.text('Статистика');
    expect(statsTab, findsOneWidget);

    await tester.tap(statsTab);
    await tester.pumpAndSettle();

    // Проверяем, что заголовок изменился на "Статистика курения" и есть фильтры
    expect(find.text('Статистика курения'), findsOneWidget);
    expect(find.text('Неделя'), findsOneWidget);
    expect(find.text('Месяц'), findsOneWidget);
    expect(find.text('6 мес.'), findsOneWidget);
    expect(find.text('Год'), findsOneWidget);
    expect(find.text('Всего за период'), findsOneWidget);

    // Переключаем фильтр на "Месяц"
    await tester.tap(find.text('Месяц'));
    await tester.pumpAndSettle();
    expect(find.text('Динамика (месяц)'), findsOneWidget);
  });
}
