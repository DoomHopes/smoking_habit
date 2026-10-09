import 'package:meta/meta.dart';

/// Базовый класс для всех ошибок приложения.
@immutable
sealed class Failure {
  /// Пользовательское сообщение об ошибке.
  final String message;

  /// Исходное исключение или ошибка (если есть).
  final Object? error;

  /// Стек вызовов (если есть).
  final StackTrace? stackTrace;

  const Failure(this.message, {this.error, this.stackTrace});

  @override
  String toString() => '$runtimeType(message: $message, error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          error == other.error;

  @override
  int get hashCode => Object.hash(runtimeType, message, error);
}

/// Ошибка при работе с локальной базой данных.
final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.error, super.stackTrace});
}

/// Ошибка валидации данных.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.error, super.stackTrace});
}

/// Непредвиденная или неизвестная ошибка.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(
    super.message, {
    super.error,
    super.stackTrace,
  });
}
