import 'package:flutter_test/flutter_test.dart';
import 'package:smoking_habit/domain/entities/smoking_record.dart';

void main() {
  group('SmokingRecord Entity', () {
    final now = DateTime(2026, 10, 9, 13, 30);

    test('создается корректно с валидными параметрами', () {
      final record = SmokingRecord.create(
        id: 1,
        timestamp: now,
        count: 2,
      );

      expect(record.id, equals(1));
      expect(record.timestamp, equals(now));
      expect(record.count, equals(2));
    });

    test('выбрасывает ArgumentError, если count <= 0', () {
      expect(
        () => SmokingRecord.create(timestamp: now, count: 0),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => SmokingRecord.create(timestamp: now, count: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('copyWith создает обновленную копию объекта', () {
      final original = SmokingRecord(id: 1, timestamp: now, count: 1);
      final updated = original.copyWith(count: 3);

      expect(updated.id, equals(1));
      expect(updated.timestamp, equals(now));
      expect(updated.count, equals(3));
    });

    test('проверка эквивалентности (operator == и hashCode)', () {
      final record1 = SmokingRecord(id: 1, timestamp: now, count: 1);
      final record2 = SmokingRecord(id: 1, timestamp: now, count: 1);
      final record3 = SmokingRecord(id: 2, timestamp: now, count: 1);

      expect(record1, equals(record2));
      expect(record1.hashCode, equals(record2.hashCode));
      expect(record1, isNot(equals(record3)));
    });
  });
}
