import 'dart:convert';
import 'dart:io';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../bloc/smoking_bloc.dart';
import '../bloc/smoking_event.dart';
import '../bloc/smoking_state.dart';
import '../widgets/responsive_content_container.dart';

/// Страница настроек приложения и управления базой данных (очистка, экспорт, импорт).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _exportToFile(BuildContext context, SmokingBloc bloc) async {
    final result = await bloc.repository.exportRecordsToJson();

    await result.when(
      onSuccess: (jsonString) async {
        try {
          // Сохраняем во временный файл для шаринга / сохранения
          final fileName =
              'smoking_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
          final tempDir = Directory.systemTemp;
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsString(jsonString);

          await Share.shareXFiles(
            [XFile(file.path, mimeType: 'application/json')],
            subject: 'Резервная копия Smoking Habit',
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Резервная копия успешно сформирована'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Не удалось сохранить файл: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
    );
  }

  Future<void> _copyJsonToClipboard(
    BuildContext context,
    SmokingBloc bloc,
  ) async {
    final result = await bloc.repository.exportRecordsToJson();

    result.when(
      onSuccess: (jsonString) {
        Clipboard.setData(ClipboardData(text: jsonString));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('JSON скопирован в буфер обмена'),
            backgroundColor: Colors.green,
          ),
        );
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
    );
  }

  Future<void> _importFromFile(BuildContext context, SmokingBloc bloc) async {
    try {
      final pickResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (pickResult == null || pickResult.files.isEmpty) {
        return;
      }

      final file = pickResult.files.first;
      String jsonContent;

      if (file.bytes != null) {
        jsonContent = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        jsonContent = await File(file.path!).readAsString();
      } else {
        throw Exception('Не удалось прочитать файл');
      }

      if (!context.mounted) return;
      await _confirmImportDialog(context, bloc, jsonContent);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выборе файла: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importFromTextDialog(
    BuildContext context,
    SmokingBloc bloc,
  ) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Импорт JSON из текста'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Вставьте содержимое JSON резервной копии...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.of(dialogContext).pop();
              _confirmImportDialog(context, bloc, text);
            },
            child: const Text('Далее'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmImportDialog(
    BuildContext context,
    SmokingBloc bloc,
    String jsonContent,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Параметры импорта'),
        content: const Text(
          'Как вы хотите импортировать данные?\n\n'
          '• «Объединить» — добавит новые записи к существующим.\n'
          '• «Заменить» — полностью сотрет текущие данные и запишет новые.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(
                ImportSmokingRecordsFromJson(
                  jsonContent: jsonContent,
                  replaceExisting: false,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Импорт данных запущен...')),
              );
            },
            child: const Text('Объединить'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(
                ImportSmokingRecordsFromJson(
                  jsonContent: jsonContent,
                  replaceExisting: true,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Данные заменяются...')),
              );
            },
            child: const Text('Заменить всё'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearDatabase(
    BuildContext context,
    SmokingBloc bloc,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Очистка базы данных'),
        content: const Text(
          'Вы уверены, что хотите удалить ВСЕ записи о выкуренных сигаретах?\n\n'
          'Это действие необратимо!',
        ),
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
              bloc.add(const ClearAllSmokingRecords());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('База данных успешно очищена'),
                ),
              );
            },
            child: const Text('Удалить всё'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bloc = context.read<SmokingBloc>();

    return BlocSignalBuilder<SmokingBloc, SmokingState>(
      builder: (context, state) {
        final recordsCount = switch (state) {
          SmokingLoaded(:final records) => records.length,
          _ => 0,
        };

        return ResponsiveContentContainer(
          child: ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 32),
            children: [
              // Секция статуса базы данных
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.storage_rounded,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Локальная база данных',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Сохранено записей: $recordsCount',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Раздел Экспорта
              Text(
                'Экспорт данных',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text('Сохранить резервную копию (.json)'),
                      subtitle: const Text('Экспорт всех записей в JSON файл'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _exportToFile(context, bloc),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.copy_rounded),
                      title: const Text('Скопировать JSON в буфер'),
                      subtitle: const Text('Для быстрой вставки или проверки'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _copyJsonToClipboard(context, bloc),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Раздел Импорта
              Text(
                'Импорт данных',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.file_upload_outlined),
                      title: const Text('Импортировать из файла (.json)'),
                      subtitle: const Text('Восстановление записей из файла'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _importFromFile(context, bloc),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.paste_rounded),
                      title: const Text('Вставить JSON из буфера'),
                      subtitle: const Text('Ручной ввод содержимого резервной копии'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _importFromTextDialog(context, bloc),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Раздел Очистки
              Text(
                'Опасная зона',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.delete_forever_rounded,
                    color: colorScheme.error,
                  ),
                  title: Text(
                    'Очистить всю базу данных',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Безвозвратно удалит все записи'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _confirmClearDatabase(context, bloc),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
