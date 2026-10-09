import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../presentation/bloc/smoking_bloc.dart';
import '../../presentation/bloc/smoking_event.dart';
import '../logging/app_talker.dart';
import 'tray_service.dart';

/// Десктопная реализация сервиса управления системным треем и жизненным циклом окна.
class DesktopTrayService with TrayListener, WindowListener implements TrayService {
  final SmokingBloc smokingBloc;
  bool _isInitialized = false;

  DesktopTrayService({required this.smokingBloc});

  @override
  Future<void> initialize() async {
    if (kIsWeb || !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      talker.debug('DesktopTrayService: пропуск инициализации (не десктопная платформа)');
      return;
    }

    if (_isInitialized) return;

    try {
      talker.info('Инициализация WindowManager и TrayManager');

      // Инициализируем WindowManager
      await windowManager.ensureInitialized();
      windowManager.addListener(this);

      const windowOptions = WindowOptions(
        size: Size(1280, 720),
        minimumSize: Size(400, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: 'Smoking Habit',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
        // Включаем перехват закрытия окна (крестик)
        await windowManager.setPreventClose(true);
      });

      // Инициализируем TrayManager
      trayManager.addListener(this);

      // Задаем путь к иконке для трея
      final iconPath = Platform.isWindows
          ? 'assets/icons/app_icon.ico'
          : 'assets/icons/app_icon.png';

      await trayManager.setIcon(iconPath);
      await trayManager.setToolTip('Smoking Habit — Учёт сигарет');

      // Контекстное меню по правому клику на иконку
      await _updateContextMenu();

      _isInitialized = true;
      talker.info('DesktopTrayService успешно инициализирован');
    } catch (e, st) {
      talker.handle(e, st, 'Ошибка при инициализации DesktopTrayService');
    }
  }

  Future<void> _updateContextMenu() async {
    final menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Открыть Smoking Habit',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quick_add_1',
          label: 'Выкурил сигарету (+1)',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Выйти из приложения',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onWindowClose() async {
    talker.info('Перехвачено закрытие окна: сворачивание в трей');
    final isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  void onTrayIconMouseDown() async {
    talker.debug('Клик левой кнопкой мыши по иконке в трее');
    await _restoreAndFocusWindow();
  }

  @override
  void onTrayIconRightMouseDown() async {
    talker.debug('Клик правой кнопкой мыши по иконке в трее: открытие меню');
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    talker.info('Выбран пункт меню трея: ${menuItem.key}');
    switch (menuItem.key) {
      case 'show_window':
        await _restoreAndFocusWindow();
        break;
      case 'quick_add_1':
        smokingBloc.add(const AddSmokingRecord(count: 1));
        break;
      case 'exit_app':
        await exitApplication();
        break;
    }
  }

  /// Восстановление и фокус на окне
  Future<void> _restoreAndFocusWindow() async {
    final isVisible = await windowManager.isVisible();
    if (!isVisible) {
      await windowManager.show();
    }
    final isMinimized = await windowManager.isMinimized();
    if (isMinimized) {
      await windowManager.restore();
    }
    await windowManager.focus();
  }

  /// Корректный выход из приложения с закрытием процесса
  Future<void> exitApplication() async {
    talker.info('Завершение работы приложения через меню трея');
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  Future<void> dispose() async {
    if (!_isInitialized) return;
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    _isInitialized = false;
  }
}
