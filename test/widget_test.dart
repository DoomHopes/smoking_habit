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
  testWidgets('Smoke test: рендеринг экрана и добавление сигареты', (WidgetTester tester) async {
    final fakeDataSource = FakeLocalDataSource();
    final repository = SmokingRepositoryImpl(fakeDataSource);
    final bloc = SmokingBloc(repository)..add(const LoadSmokingRecords());

    await tester.pumpWidget(SmokingHabitApp(smokingBloc: bloc));
    await tester.pumpAndSettle();

    // Проверяем отображение заголовка и статистики
    expect(find.text('Учёт сигарет'), findsOneWidget);
    expect(find.text('Сегодня'), findsOneWidget);
    expect(find.text('Всего'), findsOneWidget);

    // Нажимаем кнопку добавления выкуренной сигареты
    final addButton = find.text('Выкурил сигарету (+1)');
    expect(addButton, findsOneWidget);

    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Проверяем, что счетчики обновились до 1
    expect(find.text('1'), findsNWidgets(2)); // В карточке сегодня и всего
    expect(find.text('История записей'), findsOneWidget);
  });
}
