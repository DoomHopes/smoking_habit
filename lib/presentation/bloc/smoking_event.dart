import 'package:meta/meta.dart';

/// Базовый класс событий BLoC для учета выкуренных сигарет.
@immutable
sealed class SmokingEvent {
  const SmokingEvent();
}

/// Событие запроса на загрузку всех записей.
final class LoadSmokingRecords extends SmokingEvent {
  const LoadSmokingRecords();
}

/// Событие добавления новой записи о выкуренных сигаретах.
final class AddSmokingRecord extends SmokingEvent {
  /// Количество выкуренных сигарет (по умолчанию 1).
  final int count;

  /// Время события (если null, используется текущее время).
  final DateTime? timestamp;

  const AddSmokingRecord({
    this.count = 1,
    this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddSmokingRecord &&
          runtimeType == other.runtimeType &&
          count == other.count &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(runtimeType, count, timestamp);
}

/// Событие удаления записи по ее уникальному идентификатору.
final class DeleteSmokingRecord extends SmokingEvent {
  final int id;

  const DeleteSmokingRecord(this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeleteSmokingRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}

/// Событие быстрого удаления последней добавленной записи.
final class DeleteLatestSmokingRecord extends SmokingEvent {
  const DeleteLatestSmokingRecord();
}

/// Событие полной очистки базы данных.
final class ClearAllSmokingRecords extends SmokingEvent {
  const ClearAllSmokingRecords();
}

/// Событие импорта данных из JSON.
final class ImportSmokingRecordsFromJson extends SmokingEvent {
  final String jsonContent;
  final bool replaceExisting;

  const ImportSmokingRecordsFromJson({
    required this.jsonContent,
    this.replaceExisting = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportSmokingRecordsFromJson &&
          runtimeType == other.runtimeType &&
          jsonContent == other.jsonContent &&
          replaceExisting == other.replaceExisting;

  @override
  int get hashCode => Object.hash(runtimeType, jsonContent, replaceExisting);
}
