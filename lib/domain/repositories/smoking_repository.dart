import '../../core/utils/result.dart';
import '../entities/smoking_record.dart';

/// Абстрактный контракт репозитория для работы с записями о курении.
abstract interface class SmokingRepository {
  /// Получить все записи, отсортированные от новых к старым.
  Future<Result<List<SmokingRecord>>> getAllRecords();

  /// Получить записи за указанный интервал времени ([start] включительно, [end] включительно).
  Future<Result<List<SmokingRecord>>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Добавить новую запись. Возвращает созданную запись с присвоенным идентификатором.
  Future<Result<SmokingRecord>> addRecord(SmokingRecord record);

  /// Обновить существующую запись.
  Future<Result<void>> updateRecord(SmokingRecord record);

  /// Удалить запись по её уникальному идентификатору [id].
  Future<Result<void>> deleteRecord(int id);
}
