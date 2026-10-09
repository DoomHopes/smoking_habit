import 'package:bloc_signals/bloc_signals.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/logging/app_talker.dart';
import '../../domain/entities/smoking_record.dart';
import '../../domain/repositories/smoking_repository.dart';
import 'smoking_event.dart';
import 'smoking_state.dart';

/// BLoC на сигналах для управления состоянием учета выкуренных сигарет с логированием через Talker.
class SmokingBloc extends BlocSignal<SmokingEvent, SmokingState> {
  final SmokingRepository _repository;
  final Talker? _talker;

  SmokingBloc(
    this._repository, {
    Talker? customTalker,
  })  : _talker = customTalker,
        super(initialState: const SmokingInitial()) {
    on<LoadSmokingRecords>(_onLoadRecords);
    on<AddSmokingRecord>(_onAddRecord);
    on<DeleteSmokingRecord>(_onDeleteRecord);
    on<DeleteLatestSmokingRecord>(_onDeleteLatestRecord);
    on<ClearAllSmokingRecords>(_onClearAllRecords);
    on<ImportSmokingRecordsFromJson>(_onImportFromJson);
  }

  SmokingRepository get repository => _repository;

  Talker get _effectiveTalker => _talker ?? talker;

  /// Обработчик загрузки всех записей.
  Future<void> _onLoadRecords(
    LoadSmokingRecords event,
    void Function(SmokingState) emit,
  ) async {
    _effectiveTalker.debug('SmokingBloc: событие LoadSmokingRecords');
    emit(const SmokingLoading());
    final result = await _repository.getAllRecords();

    result.when(
      onSuccess: (records) {
        _effectiveTalker.info(
          'SmokingBloc: загружено ${records.length} записей',
        );
        emit(SmokingLoaded(records: records));
      },
      onFailure: (failure) {
        _effectiveTalker.error(
          'SmokingBloc: ошибка загрузки записей',
          failure.error,
          failure.stackTrace,
        );
        emit(SmokingError(failure.message));
      },
    );
  }

  /// Обработчик добавления новой записи.
  Future<void> _onAddRecord(
    AddSmokingRecord event,
    void Function(SmokingState) emit,
  ) async {
    _effectiveTalker.debug(
      'SmokingBloc: событие AddSmokingRecord(count: ${event.count})',
    );
    final record = SmokingRecord(
      timestamp: event.timestamp ?? DateTime.now(),
      count: event.count,
    );

    final result = await _repository.addRecord(record);

    await result.when(
      onSuccess: (saved) async {
        _effectiveTalker.info(
          'SmokingBloc: добавлена запись id=${saved.id}',
        );
        final reloadResult = await _repository.getAllRecords();
        reloadResult.when(
          onSuccess: (records) => emit(SmokingLoaded(records: records)),
          onFailure: (failure) => emit(SmokingError(failure.message)),
        );
      },
      onFailure: (failure) {
        _effectiveTalker.error(
          'SmokingBloc: ошибка добавления записи',
          failure.error,
          failure.stackTrace,
        );
        emit(SmokingError(failure.message));
      },
    );
  }

  /// Обработчик удаления записи по ID.
  Future<void> _onDeleteRecord(
    DeleteSmokingRecord event,
    void Function(SmokingState) emit,
  ) async {
    _effectiveTalker.debug(
      'SmokingBloc: событие DeleteSmokingRecord(id: ${event.id})',
    );
    final result = await _repository.deleteRecord(event.id);

    await result.when(
      onSuccess: (_) async {
        _effectiveTalker.info(
          'SmokingBloc: успешно удалена запись id=${event.id}',
        );
        final reloadResult = await _repository.getAllRecords();
        reloadResult.when(
          onSuccess: (records) => emit(SmokingLoaded(records: records)),
          onFailure: (failure) => emit(SmokingError(failure.message)),
        );
      },
      onFailure: (failure) {
        _effectiveTalker.error(
          'SmokingBloc: ошибка удаления записи id=${event.id}',
          failure.error,
          failure.stackTrace,
        );
        emit(SmokingError(failure.message));
      },
    );
  }

  /// Обработчик удаления последней записи.
  Future<void> _onDeleteLatestRecord(
    DeleteLatestSmokingRecord event,
    void Function(SmokingState) emit,
  ) async {
    _effectiveTalker.debug('SmokingBloc: событие DeleteLatestSmokingRecord');
    final currentState = state.value;
    if (currentState is! SmokingLoaded || currentState.records.isEmpty) {
      _effectiveTalker.warning(
        'SmokingBloc: попытка удаления последней записи при пустом списке',
      );
      return;
    }

    final latest = currentState.latestRecord;
    if (latest == null || latest.id == null) {
      return;
    }

    final result = await _repository.deleteRecord(latest.id!);

    await result.when(
      onSuccess: (_) async {
        _effectiveTalker.info(
          'SmokingBloc: успешно удалена последняя запись id=${latest.id}',
        );
        final reloadResult = await _repository.getAllRecords();
        reloadResult.when(
          onSuccess: (records) => emit(SmokingLoaded(records: records)),
          onFailure: (failure) => emit(SmokingError(failure.message)),
        );
      },
      onFailure: (failure) {
        _effectiveTalker.error(
          'SmokingBloc: ошибка удаления последней записи',
          failure.error,
          failure.stackTrace,
        );
        emit(SmokingError(failure.message));
      },
    );
  }

  /// Обработчик полной очистки базы данных.
  Future<void> _onClearAllRecords(
    ClearAllSmokingRecords event,
    void Function(SmokingState) emit,
  ) async {
    _effectiveTalker.warning('SmokingBloc: событие ClearAllSmokingRecords');
    final result = await _repository.clearAllRecords();

    result.when(
      onSuccess: (_) {
        emit(SmokingLoaded(records: const []));
      },
      onFailure: (failure) {
        _effectiveTalker.error(
          'SmokingBloc: ошибка очистки базы данных',
          failure.error,
          failure.stackTrace,
        );
        emit(SmokingError(failure.message));
      },
    );
  }

  /// Обработчик импорта данных из JSON.
  Future<void> _onImportFromJson(
    ImportSmokingRecordsFromJson event,
    void Function(SmokingState) emit,
  ) async {
    _effectiveTalker.info(
      'SmokingBloc: событие ImportSmokingRecordsFromJson(replace: ${event.replaceExisting})',
    );
    final result = await _repository.importRecordsFromJson(
      event.jsonContent,
      replaceExisting: event.replaceExisting,
    );

    await result.when(
      onSuccess: (importedCount) async {
        _effectiveTalker.info(
          'SmokingBloc: импортировано $importedCount записей',
        );
        final reloadResult = await _repository.getAllRecords();
        reloadResult.when(
          onSuccess: (records) => emit(SmokingLoaded(records: records)),
          onFailure: (failure) => emit(SmokingError(failure.message)),
        );
      },
      onFailure: (failure) {
        _effectiveTalker.error(
          'SmokingBloc: ошибка импорта данных',
          failure.error,
          failure.stackTrace,
        );
        emit(SmokingError(failure.message));
      },
    );
  }
}
