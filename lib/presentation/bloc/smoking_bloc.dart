import 'package:bloc_signals/bloc_signals.dart';
import '../../domain/entities/smoking_record.dart';
import '../../domain/repositories/smoking_repository.dart';
import 'smoking_event.dart';
import 'smoking_state.dart';

/// BLoC на сигналах для управления состоянием учета выкуренных сигарет.
class SmokingBloc extends BlocSignal<SmokingEvent, SmokingState> {
  final SmokingRepository _repository;

  SmokingBloc(this._repository)
      : super(initialState: const SmokingInitial()) {
    on<LoadSmokingRecords>(_onLoadRecords);
    on<AddSmokingRecord>(_onAddRecord);
    on<DeleteSmokingRecord>(_onDeleteRecord);
    on<DeleteLatestSmokingRecord>(_onDeleteLatestRecord);
  }

  /// Обработчик загрузки всех записей.
  Future<void> _onLoadRecords(
    LoadSmokingRecords event,
    void Function(SmokingState) emit,
  ) async {
    emit(const SmokingLoading());
    final result = await _repository.getAllRecords();

    result.when(
      onSuccess: (records) {
        emit(SmokingLoaded(records: records));
      },
      onFailure: (failure) {
        emit(SmokingError(failure.message));
      },
    );
  }

  /// Обработчик добавления новой записи.
  Future<void> _onAddRecord(
    AddSmokingRecord event,
    void Function(SmokingState) emit,
  ) async {
    final record = SmokingRecord(
      timestamp: event.timestamp ?? DateTime.now(),
      count: event.count,
    );

    final result = await _repository.addRecord(record);

    await result.when(
      onSuccess: (_) async {
        final reloadResult = await _repository.getAllRecords();
        reloadResult.when(
          onSuccess: (records) => emit(SmokingLoaded(records: records)),
          onFailure: (failure) => emit(SmokingError(failure.message)),
        );
      },
      onFailure: (failure) {
        emit(SmokingError(failure.message));
      },
    );
  }

  /// Обработчик удаления записи по ID.
  Future<void> _onDeleteRecord(
    DeleteSmokingRecord event,
    void Function(SmokingState) emit,
  ) async {
    final result = await _repository.deleteRecord(event.id);

    await result.when(
      onSuccess: (_) async {
        final reloadResult = await _repository.getAllRecords();
        reloadResult.when(
          onSuccess: (records) => emit(SmokingLoaded(records: records)),
          onFailure: (failure) => emit(SmokingError(failure.message)),
        );
      },
      onFailure: (failure) {
        emit(SmokingError(failure.message));
      },
    );
  }

  /// Обработчик удаления последней записи.
  Future<void> _onDeleteLatestRecord(
    DeleteLatestSmokingRecord event,
    void Function(SmokingState) emit,
  ) async {
    final currentState = state.value;
    if (currentState is! SmokingLoaded || currentState.records.isEmpty) {
      return;
    }

    final latest = currentState.latestRecord;
    if (latest == null || latest.id == null) {
      return;
    }

    final result = await _repository.deleteRecord(latest.id!);

    await result.when(
      onSuccess: (_) async {
        final reloadResult = await _repository.getAllRecords();
        reloadResult.when(
          onSuccess: (records) => emit(SmokingLoaded(records: records)),
          onFailure: (failure) => emit(SmokingError(failure.message)),
        );
      },
      onFailure: (failure) {
        emit(SmokingError(failure.message));
      },
    );
  }
}
