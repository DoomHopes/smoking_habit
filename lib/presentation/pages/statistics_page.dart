import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/stats_period.dart';
import '../bloc/smoking_bloc.dart';
import '../bloc/smoking_state.dart';
import '../widgets/responsive_content_container.dart';
import '../widgets/smoking_line_chart_card.dart';

/// Экран подробной аналитики и графиков выкуренных сигарет по периодам.
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  StatsPeriod _selectedPeriod = StatsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocSignalBuilder<SmokingBloc, SmokingState>(
      builder: (context, state) {
        return switch (state) {
          SmokingInitial() ||
          SmokingLoading() => const Center(child: CircularProgressIndicator()),
          SmokingError(:final message) => Center(child: Text(message)),
          SmokingLoaded() => ResponsiveContentContainer(
            child: ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              children: [
                // Переключатель периодов
                SegmentedButton<StatsPeriod>(
                  segments: StatsPeriod.values
                      .map(
                        (period) => ButtonSegment<StatsPeriod>(
                          value: period,
                          label: Text(
                            period.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                      .toList(),
                  selected: {_selectedPeriod},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedPeriod = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Вычисление данных за выбранный период
                Builder(
                  builder: (context) {
                    final summary = state.getPeriodSummary(_selectedPeriod);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Карточки ключевых показателей
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Всего за период',
                                value: '${summary.totalCount}',
                                unit: 'сиг.',
                                icon: Icons.all_inclusive_rounded,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'В среднем в день',
                                value: summary.averagePerDay.toStringAsFixed(1),
                                unit: 'сиг.',
                                icon: Icons.trending_up_rounded,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Максимум за интервал',
                                value: '${summary.maxCount}',
                                unit: 'сиг.',
                                icon: Icons.vertical_align_top_rounded,
                                color: colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Всего записей в базе',
                                value: '${state.records.length}',
                                unit: 'шт.',
                                icon: Icons.fact_check_outlined,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // График за период
                        SmokingLineChartCard(
                          title:
                              'Динамика (${_selectedPeriod.label.toLowerCase()})',
                          dailySummaries: summary.dataPoints,
                          averagePerDay: summary.averagePerDay,
                          maxCount: summary.maxCount,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        };
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
