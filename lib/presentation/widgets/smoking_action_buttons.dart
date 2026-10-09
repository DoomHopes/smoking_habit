import 'package:flutter/material.dart';

/// Блок кнопок управления: добавление выкуренной сигареты и удаление последней записи.
class SmokingActionButtons extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback? onDeleteLatest;
  final bool isDeleteEnabled;

  const SmokingActionButtons({
    super.key,
    required this.onAdd,
    this.onDeleteLatest,
    this.isDeleteEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
            label: const Text(
              'Выкурил сигарету (+1)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: isDeleteEnabled ? onDeleteLatest : null,
            icon: const Icon(Icons.undo_rounded, size: 20),
            label: const Text(
              'Удалить последнюю запись',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                color: isDeleteEnabled
                    ? theme.colorScheme.error.withValues(alpha: 0.5)
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
