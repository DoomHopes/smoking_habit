import 'dart:convert';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/error/failures.dart';
import '../../core/logging/app_talker.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/smoking_record.dart';
import '../../domain/repositories/smoking_repository.dart';
import '../datasources/smoking_local_datasource.dart';
import '../models/smoking_record_model.dart';

/// Конкретная реализация доменного репозитория [SmokingRepository].
class SmokingRepositoryImpl implements SmokingRepository {
  final SmokingLocalDataSource _localDataSource;
  final Talker? _talker;

  /// Конструктор с внедрением источника данных и опционального экземпляра Talker.
  const SmokingRepositoryImpl(
    this._localDataSource, {
    Talker? customTalker,
  }) : _talker = customTalker;

  Talker get _effectiveTalker => _talker ?? talker;

  @override
  Future<Result<List<SmokingRecord>>> getAllRecords() async {
    try {
      _effectiveTalker.debug('Запрос всех записей о курении из локальной БД');
      final models = await _localDataSource.getAllRecords();
      _effectiveTalker.info('Загружено записей: ${models.length}');
      return Result.success(List.unmodifiable(models));
    } catch (e, stackTrace) {
      _effectiveTalker.handle(e, stackTrace, 'Ошибка при загрузке записей');
      return Result.failure(
        DatabaseFailure(
          'Не удалось загрузить записи из базы данных: $e',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<List<SmokingRecord>>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      if (start.isAfter(end)) {
        final failure = const ValidationFailure(
          'Начальная дата не может быть позже конечной даты',
        );
        _effectiveTalker.warning(failure.message);
        return Result.failure(failure);
      }

      _effectiveTalker.debug(
        'Запрос записей за период: $start — $end',
      );
      final models = await _localDataSource.getRecordsByDateRange(start, end);
      return Result.success(List.unmodifiable(models));
    } catch (e, stackTrace) {
      _effectiveTalker.handle(
        e,
        stackTrace,
        'Ошибка при получении записей за диапазон',
      );
      return Result.failure(
        DatabaseFailure(
          'Не удалось получить записи за период: $e',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<SmokingRecord>> addRecord(SmokingRecord record) async {
    try {
      if (record.count <= 0) {
        final failure = const ValidationFailure(
          'Количество сигарет должно быть больше нуля',
        );
        _effectiveTalker.warning(failure.message);
        return Result.failure(failure);
      }

      _effectiveTalker.info(
        'Сохранение записи: ${record.count} шт., время: ${record.timestamp}',
      );
      final model = SmokingRecordModel.fromEntity(record);
      final savedModel = await _localDataSource.insertRecord(model);
      _effectiveTalker.info('Запись успешно сохранена с id=${savedModel.id}');
      return Result.success(savedModel);
    } catch (e, stackTrace) {
      _effectiveTalker.handle(e, stackTrace, 'Ошибка сохранения записи');
      return Result.failure(
        DatabaseFailure(
          'Не удалось сохранить запись: $e',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateRecord(SmokingRecord record) async {
    try {
      if (record.id == null) {
        final failure = const ValidationFailure(
          'Для обновления записи требуется указать её id',
        );
        _effectiveTalker.warning(failure.message);
        return Result.failure(failure);
      }

      if (record.count <= 0) {
        final failure = const ValidationFailure(
          'Количество сигарет должно быть больше нуля',
        );
        _effectiveTalker.warning(failure.message);
        return Result.failure(failure);
      }

      _effectiveTalker.info('Обновление записи id=${record.id}');
      final model = SmokingRecordModel.fromEntity(record);
      await _localDataSource.updateRecord(model);
      return const Result.success(null);
    } catch (e, stackTrace) {
      _effectiveTalker.handle(e, stackTrace, 'Ошибка обновления записи');
      return Result.failure(
        DatabaseFailure(
          'Не удалось обновить запись: $e',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteRecord(int id) async {
    try {
      _effectiveTalker.info('Удаление записи id=$id');
      await _localDataSource.deleteRecord(id);
      _effectiveTalker.info('Запись id=$id успешно удалена');
      return const Result.success(null);
    } catch (e, stackTrace) {
      _effectiveTalker.handle(e, stackTrace, 'Ошибка удаления записи');
      return Result.failure(
        DatabaseFailure(
          'Не удалось удалить запись: $e',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> clearAllRecords() async {
    try {
      _effectiveTalker.warning('Полная очистка всех записей из базы данных');
      await _localDataSource.clearAllRecords();
      _effectiveTalker.info('База данных успешно очищена');
      return const Result.success(null);
    } catch (e, stackTrace) {
      _effectiveTalker.handle(e, stackTrace, 'Ошибка при очистке базы данных');
      return Result.failure(
        DatabaseFailure(
          'Не удалось очистить базу данных: $e',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<String>> exportRecordsToJson() async {
    try {
      _effectiveTalker.info('Формирование JSON резервной копии базы данных');
      final records = await _localDataSource.getAllRecords();

      final exportMap = <String, dynamic>{
        'version': 1,
        'app': 'Smoking Habit',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'recordsCount': records.length,
        'records': records.map((r) => r.toMap(includeId: false)).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportMap);
      _effectiveTalker.info(
        'Экспорт завершен. Экспортировано записей: ${records.length}',
      );
      return Result.success(jsonString);
    } catch (e, stackTrace) {
      _effectiveTalker.handle(e, stackTrace, 'Ошибка экспорта данных в JSON');
      return Result.failure(
        DatabaseFailure(
          'Не удалось экспортировать данные: $e',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<int>> importRecordsFromJson(
    String jsonContent, {
    bool replaceExisting = false,
  }) async {
    try {
      _effectiveTalker.info(
        'Импорт данных из JSON (замена существующих: $replaceExisting)',
      );

      final dynamic decoded = jsonDecode(jsonContent);
      final List<dynamic> rawList;

      if (decoded is Map<String, dynamic> && decoded.containsKey('records')) {
        final recordsField = decoded['records'];
        if (recordsField is List) {
          rawList = recordsField;
        } else {
          return const Result.failure(
            ValidationFailure('Поле "records" в JSON должно быть массивом'),
          );
        }
      } else if (decoded is List) {
        rawList = decoded;
      } else {
        return const Result.failure(
          ValidationFailure('Некорректная структура JSON файла резервной копии'),
        );
      }

      final modelsToInsert = <SmokingRecordModel>[];

      for (int i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        if (item is! Map<String, dynamic>) {
          return Result.failure(
            ValidationFailure('Элемент #$i в списке записей не является объектом'),
          );
        }

        try {
          final model = SmokingRecordModel.fromMap(item);
          if (model.count <= 0) {
            return Result.failure(
              ValidationFailure(
                'Запись #$i содержит некорректное количество сигарет (${model.count})',
              ),
            );
          }
          modelsToInsert.add(model);
        } catch (e) {
          return Result.failure(
            ValidationFailure('Ошибка разбора записи #$i: $e'),
          );
        }
      }

      if (replaceExisting) {
        await _localDataSource.clearAllRecords();
      }

      await _localDataSource.insertAllRecords(modelsToInsert);

      _effectiveTalker.info(
        'Успешно импортировано записей: ${modelsToInsert.length}',
      );
      return Result.success(modelsToInsert.length);
    } catch (e, stackTrace) {
      _effectiveTalker.handle(e, stackTrace, 'Ошибка при импорте данных из JSON');
      return Result.failure(
        ValidationFailure(
          'Не удалось импортировать данные: $e',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
