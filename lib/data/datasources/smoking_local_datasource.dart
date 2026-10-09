import '../models/smoking_record_model.dart';

/// Абстрактный контракт локального источника данных.
abstract interface class SmokingLocalDataSource {
  /// Получить все сохраненные записи.
  Future<List<SmokingRecordModel>> getAllRecords();

  /// Получить записи в заданном диапазоне дат.
  Future<List<SmokingRecordModel>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Вставить новую запись и вернуть модель с обновленным ID.
  Future<SmokingRecordModel> insertRecord(SmokingRecordModel record);

  /// Пакетная вставка списка записей.
  Future<void> insertAllRecords(List<SmokingRecordModel> records);

  /// Обновить существующую запись в хранилище.
  Future<void> updateRecord(SmokingRecordModel record);

  /// Удалить запись по ID.
  Future<void> deleteRecord(int id);

  /// Удалить абсолютно все записи из таблицы.
  Future<void> clearAllRecords();
}
