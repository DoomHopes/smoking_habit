import 'package:flutter_test/flutter_test.dart';
import 'package:smoking_habit/data/models/smoking_record_model.dart';
import 'package:smoking_habit/domain/entities/smoking_record.dart';

void main() {
  group('SmokingRecordModel DTO', () {
    final now = DateTime(2026, 10, 9, 13, 30, 0);

    test('конвертируется в Map и обратно из Map (ISO 8601 String)', () {
      final model = SmokingRecordModel(
        id: 10,
        timestamp: now,
        count: 2,
      );

      final map = model.toMap(includeId: true);
      expect(map['id'], equals(10));
      expect(map['timestamp'], equals(now.toIso8601String()));
      expect(map['count'], equals(2));

      final restoredModel = SmokingRecordModel.fromMap(map);
      expect(restoredModel.id, equals(10));
      expect(restoredModel.timestamp, equals(now));
      expect(restoredModel.count, equals(2));
    });

    test('конвертируется из Map с timestamp в миллисекундах', () {
      final map = <String, dynamic>{
        'id': 5,
        'timestamp': now.millisecondsSinceEpoch,
        'count': 3,
      };

      final restoredModel = SmokingRecordModel.fromMap(map);
      expect(restoredModel.id, equals(5));
      expect(
        restoredModel.timestamp.millisecondsSinceEpoch,
        equals(now.millisecondsSinceEpoch),
      );
      expect(restoredModel.count, equals(3));
    });

    test('создается из доменной сущности SmokingRecord', () {
      final entity = SmokingRecord(id: 7, timestamp: now, count: 1);
      final model = SmokingRecordModel.fromEntity(entity);

      expect(model.id, equals(entity.id));
      expect(model.timestamp, equals(entity.timestamp));
      expect(model.count, equals(entity.count));
    });
  });
}
