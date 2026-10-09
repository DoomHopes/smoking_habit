import 'package:meta/meta.dart';

/// Сущность записи о выкуренных сигаретах.
///
/// Представляет неизменяемое доменное событие фиксации выкуренных сигарет
/// в определенный момент времени.
@immutable
class SmokingRecord {
  /// Уникальный идентификатор записи (null для новых несохраненных записей).
  final int? id;

  /// Дата и время фиксации события.
  final DateTime timestamp;

  /// Количество выкуренных сигарет.
  final int count;

  /// Основной константный конструктор.
  const SmokingRecord({
    this.id,
    required this.timestamp,
    required this.count,
  });

  /// Фабричный валидирующий конструктор.
  ///
  /// Выбрасывает [ArgumentError], если количество сигарет меньше или равно нулю.
  factory SmokingRecord.create({
    int? id,
    required DateTime timestamp,
    int count = 1,
  }) {
    if (count <= 0) {
      throw ArgumentError.value(
        count,
        'count',
        'Количество выкуренных сигарет должно быть больше 0',
      );
    }

    return SmokingRecord(
      id: id,
      timestamp: timestamp,
      count: count,
    );
  }

  /// Создание копии объекта с возможностью обновления отдельных полей.
  SmokingRecord copyWith({
    int? id,
    DateTime? timestamp,
    int? count,
  }) {
    return SmokingRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      count: count ?? this.count,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmokingRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp &&
          count == other.count;

  @override
  int get hashCode => Object.hash(runtimeType, id, timestamp, count);

  @override
  String toString() =>
      'SmokingRecord(id: $id, timestamp: $timestamp, count: $count)';
}
