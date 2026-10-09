import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/smoking_record.dart';
import '../../domain/repositories/smoking_repository.dart';
import '../datasources/smoking_local_datasource.dart';
import '../models/smoking_record_model.dart';

/// Конкретная реализация доменного репозитория [SmokingRepository].
class SmokingRepositoryImpl implements SmokingRepository {
  final SmokingLocalDataSource _localDataSource;

  /// Конструктор с внедрением зависимости источника данных.
  const SmokingRepositoryImpl(this._localDataSource);

  @override
  Future<Result<List<SmokingRecord>>> getAllRecords() async {
    try {
      final models = await _localDataSource.getAllRecords();
      return Result.success(List.unmodifiable(models));
    } catch (e, stackTrace) {
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
        return Result.failure(
          const ValidationFailure(
            'Начальная дата не может быть позже конечной даты',
          ),
        );
      }

      final models = await _localDataSource.getRecordsByDateRange(start, end);
      return Result.success(List.unmodifiable(models));
    } catch (e, stackTrace) {
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
        return Result.failure(
          const ValidationFailure(
            'Количество сигарет должно быть больше нуля',
          ),
        );
      }

      final model = SmokingRecordModel.fromEntity(record);
      final savedModel = await _localDataSource.insertRecord(model);
      return Result.success(savedModel);
    } catch (e, stackTrace) {
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
        return Result.failure(
          const ValidationFailure(
            'Для обновления записи требуется указать её id',
          ),
        );
      }

      if (record.count <= 0) {
        return Result.failure(
          const ValidationFailure(
            'Количество сигарет должно быть больше нуля',
          ),
        );
      }

      final model = SmokingRecordModel.fromEntity(record);
      await _localDataSource.updateRecord(model);
      return const Result.success(null);
    } catch (e, stackTrace) {
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
      await _localDataSource.deleteRecord(id);
      return const Result.success(null);
    } catch (e, stackTrace) {
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
