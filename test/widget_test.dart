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
  testWidgets('Smoke test: добавление сигареты, просмотр статистики и открытие экрана настроек', (WidgetTester tester) async {
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

    // Открываем боковое меню (Drawer)
    var scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    // Нажимаем на пункт "Статистика" в Drawer
    await tester.tap(find.text('Статистика'));
    await tester.pumpAndSettle();

    // Проверяем, что заголовок изменился на "Статистика курения" и есть фильтры
    expect(find.text('Статистика курения'), findsOneWidget);
    expect(find.text('Неделя'), findsOneWidget);
    expect(find.text('Месяц'), findsOneWidget);
    expect(find.text('6 мес.'), findsOneWidget);
    expect(find.text('Год'), findsOneWidget);

    // Открываем боковое меню и переходим в "Настройки"
    scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();

    // Проверяем заголовок "Настройки" и разделы
    expect(find.text('Настройки'), findsWidgets);
    expect(find.text('Экспорт данных'), findsOneWidget);
    expect(find.text('Импорт данных'), findsOneWidget);

    // Прокручиваем до блока опасной зоны и очистки
    await tester.scrollUntilVisible(
      find.text('Очистить всю базу данных'),
      100.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Очистить всю базу данных'), findsOneWidget);
  });
}

