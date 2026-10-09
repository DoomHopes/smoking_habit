import 'package:meta/meta.dart';
import 'daily_smoking_summary.dart';
import 'stats_period.dart';

/// Модель сводной статистики за выбранный период времени.
@immutable
class PeriodSmokingSummary {
  /// Выбранный период
  final StatsPeriod period;

  /// Список агрегированных точек данных для графика
  final List<DailySmokingSummary> dataPoints;

  /// Общее количество выкуренных сигарет за период
  final int totalCount;

  /// Среднее количество сигарет в день
  final double averagePerDay;

  /// Максимальное значение за один интервал (день или месяц)
  final int maxCount;

  const PeriodSmokingSummary({
    required this.period,
    required this.dataPoints,
    required this.totalCount,
    required this.averagePerDay,
    required this.maxCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeriodSmokingSummary &&
          runtimeType == other.runtimeType &&
          period == other.period &&
          totalCount == other.totalCount &&
          averagePerDay == other.averagePerDay &&
          maxCount == other.maxCount;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        period,
        totalCount,
        averagePerDay,
        maxCount,
      );
}
