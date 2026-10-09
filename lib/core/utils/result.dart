import 'package:meta/meta.dart';
import '../error/failures.dart';

/// Обобщенный результат операции (может быть успехом или ошибкой).
@immutable
sealed class Result<T> {
  const Result();

  /// Фабричный конструктор успешного результата.
  const factory Result.success(T data) = Success<T>;

  /// Фабричный конструктор ошибки.
  const factory Result.failure(Failure failure) = FailureResult<T>;

  /// Проверка на успешный результат.
  bool get isSuccess => this is Success<T>;

  /// Проверка на ошибку.
  bool get isFailure => this is FailureResult<T>;

  /// Возвращает данные или null, если результат с ошибкой.
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        FailureResult<T>() => null,
      };

  /// Возвращает ошибку или null, если результат успешный.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        FailureResult<T>(:final failure) => failure,
      };

  /// Сопоставление с образцом (Pattern Matching) для обработки результата.
  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      FailureResult<T>(:final failure) => onFailure(failure),
    };
  }
}

/// Успешный результат операции.
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => Object.hash(runtimeType, data);

  @override
  String toString() => 'Success(data: $data)';
}

/// Результат операции, завершившейся ошибкой.
final class FailureResult<T> extends Result<T> {
  final Failure failure;

  const FailureResult(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FailureResult<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => Object.hash(runtimeType, failure);

  @override
  String toString() => 'FailureResult(failure: $failure)';
}
