import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/daily_smoking_summary.dart';

/// Интерактивный график выкуренных сигарет с поддержкой различных временных периодов.
class SmokingBarChartCard extends StatelessWidget {
  final String title;
  final List<DailySmokingSummary> dailySummaries;
  final double averagePerDay;
  final int maxCount;

  const SmokingBarChartCard({
    super.key,
    this.title = 'Динамика выкуренных сигарет',
    required this.dailySummaries,
    required this.averagePerDay,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double computedMaxY = (maxCount <= 4)
        ? 5.0
        : (maxCount + (maxCount % 2 == 0 ? 2 : 3)).toDouble();

    final int countPoints = dailySummaries.length;
    final double rodWidth = switch (countPoints) {
      <= 7 => 18.0,
      <= 12 => 12.0,
      _ => 5.0,
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Ср.: ${averagePerDay.toStringAsFixed(1)} / день',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: computedMaxY,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => colorScheme.inverseSurface,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final summary = dailySummaries[groupIndex];
                        final formattedDate =
                            '${summary.date.day.toString().padLeft(2, '0')}.${summary.date.month.toString().padLeft(2, '0')}';
                        return BarTooltipItem(
                          '$formattedDate (${summary.dayLabel})\n',
                          TextStyle(
                            color: colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: '${rod.toY.toInt()} сиг.',
                              style: TextStyle(
                                color: colorScheme.primaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: computedMaxY > 10 ? 5 : 2,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == computedMaxY) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dailySummaries.length) {
                            return const SizedBox.shrink();
                          }

                          // Для месяца показываем подписи с интервалом в 5 дней, чтобы не нагромождать
                          if (countPoints > 15 &&
                              (index % 5 != 0 && index != countPoints - 1)) {
                            return const SizedBox.shrink();
                          }

                          final item = dailySummaries[index];
                          final isToday = item.isToday;

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              item.dayLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isToday
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: computedMaxY > 10 ? 5 : 2,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: dailySummaries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isToday = item.isToday;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: item.count.toDouble(),
                          width: rodWidth,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: isToday
                                ? [
                                    colorScheme.primary,
                                    colorScheme.primary.withValues(alpha: 0.8),
                                  ]
                                : [
                                    colorScheme.secondary.withValues(
                                      alpha: 0.6,
                                    ),
                                    colorScheme.secondary.withValues(
                                      alpha: 0.9,
                                    ),
                                  ],
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: computedMaxY,
                            color: colorScheme.surface.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
