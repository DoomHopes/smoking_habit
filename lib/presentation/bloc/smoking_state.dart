import 'package:meta/meta.dart';
import '../../domain/entities/smoking_record.dart';

/// Базовый класс состояний экрана учета выкуренных сигарет.
@immutable
sealed class SmokingState {
  const SmokingState();
}

/// Начальное состояние до первой загрузки данных.
final class SmokingInitial extends SmokingState {
  const SmokingInitial();
}

/// Состояние выполнения асинхронной загрузки данных.
final class SmokingLoading extends SmokingState {
  const SmokingLoading();
}

/// Состояние с успешно загруженными данными.
final class SmokingLoaded extends SmokingState {
  /// Полный список записей, отсортированный от новых к старым.
  final List<SmokingRecord> records;

  /// Количество сигарет, выкуренных за сегодня.
  final int todayCount;

  /// Общее количество сигарет за всё время.
  final int totalCount;

  SmokingLoaded({
    required List<SmokingRecord> records,
    DateTime? currentDate,
  })  : records = List.unmodifiable(records),
        todayCount = _calculateTodayCount(records, currentDate ?? DateTime.now()),
        totalCount = _calculateTotalCount(records);

  /// Вычисление суммы сигарет за текущий день.
  static int _calculateTodayCount(List<SmokingRecord> records, DateTime now) {
    return records
        .where((r) =>
            r.timestamp.year == now.year &&
            r.timestamp.month == now.month &&
            r.timestamp.day == now.day)
        .fold<int>(0, (sum, item) => sum + item.count);
  }

  /// Вычисление общего количества сигарет за всё время.
  static int _calculateTotalCount(List<SmokingRecord> records) {
    return records.fold<int>(0, (sum, item) => sum + item.count);
  }

  /// Получить самую последнюю запись (если есть).
  SmokingRecord? get latestRecord => records.isNotEmpty ? records.first : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmokingLoaded &&
          runtimeType == other.runtimeType &&
          todayCount == other.todayCount &&
          totalCount == other.totalCount &&
          _listEquals(records, other.records);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        todayCount,
        totalCount,
        Object.hashAll(records),
      );

  static bool _listEquals(List<SmokingRecord> a, List<SmokingRecord> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Состояние ошибки при выполнении операции.
final class SmokingError extends SmokingState {
  final String message;

  const SmokingError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmokingError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}
