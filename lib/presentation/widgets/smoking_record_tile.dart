import 'package:flutter/material.dart';
import '../../domain/entities/smoking_record.dart';

/// Элемент списка истории выкуренных сигарет с кнопкой удаления.
class SmokingRecordTile extends StatelessWidget {
  final SmokingRecord record;
  final VoidCallback onDelete;

  const SmokingRecordTile({
    super.key,
    required this.record,
    required this.onDelete,
  });

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    if (isToday) {
      return 'Сегодня, $timeStr';
    }

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day.$month.${dt.year}, $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.smoking_rooms_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          _formatDateTime(record.timestamp.toLocal()),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${record.count} ${record.count == 1 ? 'сигарета' : 'сиг.'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: colorScheme.error.withValues(alpha: 0.8),
          ),
          tooltip: 'Удалить запись',
          onPressed: onDelete,
        ),
      ),
    );
  }
}
