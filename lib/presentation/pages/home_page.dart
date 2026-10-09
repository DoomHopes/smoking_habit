import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/logging/app_talker.dart';
import '../../domain/entities/smoking_record.dart';
import '../bloc/smoking_bloc.dart';
import '../bloc/smoking_event.dart';
import '../bloc/smoking_state.dart';
import '../widgets/smoking_action_buttons.dart';
import '../widgets/smoking_record_tile.dart';
import '../widgets/smoking_summary_card.dart';

/// Главный экран приложения для учёта выкуренных сигарет.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openTalkerScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TalkerScreen(talker: talker),
      ),
    );
  }

  void _onAddCigarette(BuildContext context) {
    context.read<SmokingBloc>().add(const AddSmokingRecord(count: 1));
  }

  void _onDeleteLatest(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удаление последней записи'),
        content: const Text('Вы уверены, что хотите удалить последнюю добавленную запись?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<SmokingBloc>().add(const DeleteLatestSmokingRecord());
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _onDeleteRecord(BuildContext context, SmokingRecord record) {
    if (record.id == null) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text('Удалить запись за ${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')} (${record.count} шт.)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<SmokingBloc>().add(DeleteSmokingRecord(record.id!));
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smoke_free_rounded, size: 24),
            SizedBox(width: 8),
            Text(
              'Учёт сигарет',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Логи приложения (Talker)',
            onPressed: () => _openTalkerScreen(context),
          ),
        ],
      ),
      body: BlocSignalConsumer<SmokingBloc, SmokingState>(
        listener: (context, state) {
          if (state is SmokingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            SmokingInitial() || SmokingLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            SmokingError(:final message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(message),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context
                          .read<SmokingBloc>()
                          .add(const LoadSmokingRecords()),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            SmokingLoaded(
              :final records,
              :final todayCount,
              :final totalCount,
              :final latestRecord,
            ) =>
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    SmokingSummaryCard(
                      todayCount: todayCount,
                      totalCount: totalCount,
                      latestTimestamp: latestRecord?.timestamp,
                    ),
                    const SizedBox(height: 16),
                    SmokingActionButtons(
                      onAdd: () => _onAddCigarette(context),
                      onDeleteLatest: latestRecord != null
                          ? () => _onDeleteLatest(context)
                          : null,
                      isDeleteEnabled: latestRecord != null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'История записей',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${records.length})',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: records.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 56,
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Сегодня еще не было записей',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: records.length,
                              itemBuilder: (context, index) {
                                final record = records[index];
                                return SmokingRecordTile(
                                  record: record,
                                  onDelete: () =>
                                      _onDeleteRecord(context, record),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}
