/// Абстрактный контракт сервиса управления автозапуском приложения при старте ОС.
abstract interface class AutoStartService {
  /// Первичная инициализация сервиса и регистрация параметров приложения.
  Future<void> initialize();

  /// Проверка, включен ли автозапуск в текущий момент.
  Future<bool> isEnabled();

  /// Включение или выключение автозапуска.
  Future<void> setEnabled(bool enabled);
}
