import 'package:meta/meta.dart';

/// Модель агрегированной статистики выкуренных сигарет за конкретный день.
@immutable
class DailySmokingSummary {
  /// Дата (начало суток).
  final DateTime date;

  /// Количество сигарет за этот день.
  final int count;

  /// Короткая метка дня недели (например, "Пн", "Вт").
  final String dayLabel;

  /// Является ли этот день текущим.
  final bool isToday;

  const DailySmokingSummary({
    required this.date,
    required this.count,
    required this.dayLabel,
    required this.isToday,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySmokingSummary &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          count == other.count &&
          dayLabel == other.dayLabel &&
          isToday == other.isToday;

  @override
  int get hashCode => Object.hash(runtimeType, date, count, dayLabel, isToday);

  @override
  String toString() =>
      'DailySmokingSummary(date: $date, count: $count, dayLabel: $dayLabel, isToday: $isToday)';
}
