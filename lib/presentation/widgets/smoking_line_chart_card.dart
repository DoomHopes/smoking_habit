import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/daily_smoking_summary.dart';

/// Современный неоновый LineChart график динамики выкуренных сигарет с градиентной заливкой.
class SmokingLineChartCard extends StatelessWidget {
  final String title;
  final List<DailySmokingSummary> dailySummaries;
  final double averagePerDay;
  final int maxCount;

  const SmokingLineChartCard({
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
    final isDark = theme.brightness == Brightness.dark;

    final double computedMaxY = (maxCount <= 4)
        ? 5.0
        : (maxCount + (maxCount % 2 == 0 ? 2 : 3)).toDouble();

    final int pointsCount = dailySummaries.length;
    final double maxX = pointsCount > 1 ? (pointsCount - 1).toDouble() : 1.0;

    final spots = dailySummaries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
    }).toList();

    // Цвета градиента линии и заливки: от яркого циан/бирюзового до изумрудно-зеленого
    const lineGradientColors = [
      Color(0xFF00E5FF),
      Color(0xFF00B4D8),
      Color(0xFF10B981),
    ];

    final cardBgColor = isDark
        ? const Color(0xFF111827)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);

    final gridLineColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final labelColor = isDark
        ? Colors.grey.shade400
        : colorScheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
        ),
      ),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и среднее значение
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.show_chart_rounded,
                          size: 20,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ср.: ${averagePerDay.toStringAsFixed(1)} / день',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Область графика LineChart
            SizedBox(
              height: 210,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX,
                  minY: 0,
                  maxY: computedMaxY,
                  // Интерактивное касание и всплывающая подсказка
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => Colors.white,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      tooltipMargin: 10,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          if (idx < 0 || idx >= dailySummaries.length) {
                            return null;
                          }
                          final summary = dailySummaries[idx];
                          final formattedDate =
                              '${summary.date.day.toString().padLeft(2, '0')}.${summary.date.month.toString().padLeft(2, '0')}';

                          return LineTooltipItem(
                            '${spot.y.toInt()}',
                            const TextStyle(
                              color: Color(0xFF0284C7),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: ' сиг.\n$formattedDate (${summary.dayLabel})',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                            strokeWidth: 2,
                            dashArray: [4, 4],
                          ),
                          FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, i) {
                              return FlDotCirclePainter(
                                radius: 6,
                                color: const Color(0xFF00E5FF),
                                strokeWidth: 4,
                                strokeColor: Colors.white.withValues(alpha: 0.4),
                              );
                            },
                          ),
                        );
                      }).toList();
                    },
                  ),
                  // Сетка
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                    horizontalInterval: computedMaxY > 10 ? 5 : 2,
                    verticalInterval: pointsCount <= 7
                        ? 1
                        : (pointsCount <= 14 ? 2 : (pointsCount <= 31 ? 5 : 2)),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: gridLineColor,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: gridLineColor,
                      strokeWidth: 1,
                    ),
                  ),
                  // Настройка подписей осей
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
                        reservedSize: 32,
                        interval: computedMaxY > 10 ? 5 : 2,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == computedMaxY) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Text(
                              value.toInt().toString(),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: labelColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dailySummaries.length) {
                            return const SizedBox.shrink();
                          }

                          // Для периода > 15 дней фильтруем метки для читаемости
                          if (pointsCount > 15 &&
                              (index % 5 != 0 && index != pointsCount - 1)) {
                            return const SizedBox.shrink();
                          }

                          final item = dailySummaries[index];
                          final isToday = item.isToday;

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              item.dayLabel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isToday
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isToday
                                    ? const Color(0xFF00E5FF)
                                    : labelColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  // Линия графика и градиент под ней
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      preventCurveOverShooting: true,
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      gradient: const LinearGradient(
                        colors: lineGradientColors,
                      ),
                      // Точки на линии (показываем для коротких периодов <= 14 точек)
                      dotData: FlDotData(
                        show: pointsCount <= 14,
                        getDotPainter: (spot, percent, barData, index) {
                          final isLast = index == pointsCount - 1;
                          return FlDotCirclePainter(
                            radius: isLast ? 4.5 : 3.0,
                            color: isLast
                                ? const Color(0xFF10B981)
                                : const Color(0xFF00E5FF),
                            strokeWidth: 2,
                            strokeColor: cardBgColor,
                          );
                        },
                      ),
                      // Градиентная область под кривой графика
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF00E5FF).withValues(alpha: 0.35),
                            const Color(0xFF10B981).withValues(alpha: 0.10),
                            const Color(0xFF10B981).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
