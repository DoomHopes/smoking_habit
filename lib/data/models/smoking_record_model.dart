import '../../domain/entities/smoking_record.dart';

/// DTO модель записи для сохранения и чтения из базы данных.
class SmokingRecordModel extends SmokingRecord {
  const SmokingRecordModel({
    super.id,
    required super.timestamp,
    required super.count,
  });

  /// Создание модели из доменной сущности [SmokingRecord].
  factory SmokingRecordModel.fromEntity(SmokingRecord record) {
    return SmokingRecordModel(
      id: record.id,
      timestamp: record.timestamp,
      count: record.count,
    );
  }

  /// Создание модели из данных SQLite Map.
  factory SmokingRecordModel.fromMap(Map<String, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    final DateTime parsedTimestamp;

    if (rawTimestamp is String) {
      parsedTimestamp = DateTime.parse(rawTimestamp);
    } else if (rawTimestamp is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else {
      throw FormatException(
        'Некорректный формат поля timestamp: $rawTimestamp',
      );
    }

    final rawCount = map['count'];
    final int parsedCount;
    if (rawCount is int) {
      parsedCount = rawCount;
    } else if (rawCount is num) {
      parsedCount = rawCount.toInt();
    } else {
      throw FormatException('Некорректный формат поля count: $rawCount');
    }

    return SmokingRecordModel(
      id: map['id'] as int?,
      timestamp: parsedTimestamp,
      count: parsedCount,
    );
  }

  /// Преобразование модели в Map для записи в SQLite.
  Map<String, dynamic> toMap({bool includeId = false}) {
    final map = <String, dynamic>{
      'timestamp': timestamp.toIso8601String(),
      'count': count,
    };

    if (includeId && id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Копирование модели с новыми параметрами.
  @override
  SmokingRecordModel copyWith({
    int? id,
    DateTime? timestamp,
    int? count,
  }) {
    return SmokingRecordModel(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      count: count ?? this.count,
    );
  }
}
