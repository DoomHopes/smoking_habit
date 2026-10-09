/// Периоды отображения статистики выкуренных сигарет.
enum StatsPeriod {
  /// Последние 7 дней
  week('Неделя'),

  /// Последние 30 дней
  month('Месяц'),

  /// Последние 6 месяцев
  sixMonths('6 мес.'),

  /// Последние 12 месяцев (1 год)
  year('Год');

  final String label;

  const StatsPeriod(this.label);
}
