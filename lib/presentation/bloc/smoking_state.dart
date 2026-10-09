import 'package:meta/meta.dart';
import '../../domain/entities/daily_smoking_summary.dart';
import '../../domain/entities/period_smoking_summary.dart';
import '../../domain/entities/smoking_record.dart';
import '../../domain/entities/stats_period.dart';

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

  /// Агрегированная статистика по дням за последние 7 дней (для быстрого доступа).
  final List<DailySmokingSummary> last7DaysSummary;

  /// Среднее количество сигарет в день за последние 7 дней.
  final double averagePerDayLast7Days;

  SmokingLoaded({
    required List<SmokingRecord> records,
    DateTime? currentDate,
  })  : records = List.unmodifiable(records),
        todayCount = _calculateTodayCount(records, currentDate ?? DateTime.now()),
        totalCount = _calculateTotalCount(records),
        last7DaysSummary = _calculateDaysSummary(
          records,
          currentDate ?? DateTime.now(),
          7,
        ),
        averagePerDayLast7Days = _calculateDaysAverage(
          records,
          currentDate ?? DateTime.now(),
          7,
        );

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

  /// Получение сводки статистики для выбранного периода.
  PeriodSmokingSummary getPeriodSummary(
    StatsPeriod period, [
    DateTime? currentDate,
  ]) {
    final now = currentDate ?? DateTime.now();

    return switch (period) {
      StatsPeriod.week => _buildDaysPeriodSummary(period, now, 7),
      StatsPeriod.month => _buildDaysPeriodSummary(period, now, 30),
      StatsPeriod.sixMonths => _buildMonthsPeriodSummary(period, now, 6),
      StatsPeriod.year => _buildMonthsPeriodSummary(period, now, 12),
    };
  }

  PeriodSmokingSummary _buildDaysPeriodSummary(
    StatsPeriod period,
    DateTime now,
    int daysCount,
  ) {
    final dataPoints = _calculateDaysSummary(records, now, daysCount);
    final total = dataPoints.fold<int>(0, (sum, item) => sum + item.count);
    final average = total / daysCount.toDouble();
    final max = dataPoints.isEmpty
        ? 0
        : dataPoints.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return PeriodSmokingSummary(
      period: period,
      dataPoints: dataPoints,
      totalCount: total,
      averagePerDay: average,
      maxCount: max,
    );
  }

  PeriodSmokingSummary _buildMonthsPeriodSummary(
    StatsPeriod period,
    DateTime now,
    int monthsCount,
  ) {
    const monthNames = {
      1: 'Янв',
      2: 'Фев',
      3: 'Мар',
      4: 'Апр',
      5: 'Май',
      6: 'Июн',
      7: 'Июл',
      8: 'Авг',
      9: 'Сен',
      10: 'Окт',
      11: 'Ноя',
      12: 'Дек',
    };

    final dataPoints = <DailySmokingSummary>[];
    int totalDays = 0;

    for (int i = monthsCount - 1; i >= 0; i--) {
      // Смещение по месяцам
      int targetYear = now.year;
      int targetMonth = now.month - i;
      while (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }

      final monthStart = DateTime(targetYear, targetMonth, 1);
      final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
      totalDays += daysInMonth;

      final count = records
          .where((r) =>
              r.timestamp.year == targetYear &&
              r.timestamp.month == targetMonth)
          .fold<int>(0, (sum, item) => sum + item.count);

      final isCurrentMonth =
          targetYear == now.year && targetMonth == now.month;

      dataPoints.add(
        DailySmokingSummary(
          date: monthStart,
          count: count,
          dayLabel: monthNames[targetMonth] ?? '$targetMonth',
          isToday: isCurrentMonth,
        ),
      );
    }

    final total = dataPoints.fold<int>(0, (sum, item) => sum + item.count);
    final average = totalDays > 0 ? (total / totalDays.toDouble()) : 0.0;
    final max = dataPoints.isEmpty
        ? 0
        : dataPoints.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return PeriodSmokingSummary(
      period: period,
      dataPoints: List.unmodifiable(dataPoints),
      totalCount: total,
      averagePerDay: average,
      maxCount: max,
    );
  }

  /// Формирование среза данных по дням.
  static List<DailySmokingSummary> _calculateDaysSummary(
    List<SmokingRecord> records,
    DateTime now,
    int daysCount,
  ) {
    const dayNames = {
      DateTime.monday: 'Пн',
      DateTime.tuesday: 'Вт',
      DateTime.wednesday: 'Ср',
      DateTime.thursday: 'Чт',
      DateTime.friday: 'Пт',
      DateTime.saturday: 'Сб',
      DateTime.sunday: 'Вс',
    };

    final todayMidnight = DateTime(now.year, now.month, now.day);
    final summaries = <DailySmokingSummary>[];

    for (int i = daysCount - 1; i >= 0; i--) {
      final day = todayMidnight.subtract(Duration(days: i));
      final count = records
          .where((r) =>
              r.timestamp.year == day.year &&
              r.timestamp.month == day.month &&
              r.timestamp.day == day.day)
          .fold<int>(0, (sum, item) => sum + item.count);

      final String label;
      if (daysCount == 7) {
        label = dayNames[day.weekday] ?? '';
      } else {
        label = '${day.day}';
      }

      summaries.add(
        DailySmokingSummary(
          date: day,
          count: count,
          dayLabel: label,
          isToday: i == 0,
        ),
      );
    }

    return List.unmodifiable(summaries);
  }

  /// Вычисление среднего количества сигарет за N дней.
  static double _calculateDaysAverage(
    List<SmokingRecord> records,
    DateTime now,
    int daysCount,
  ) {
    final list = _calculateDaysSummary(records, now, daysCount);
    final sum = list.fold<int>(0, (prev, curr) => prev + curr.count);
    return sum / daysCount.toDouble();
  }

  /// Максимальное количество сигарет за день в выборке 7 дней.
  int get maxCountInLast7Days {
    if (last7DaysSummary.isEmpty) return 0;
    return last7DaysSummary
        .map((s) => s.count)
        .reduce((a, b) => a > b ? a : b);
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
