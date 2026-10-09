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
}
