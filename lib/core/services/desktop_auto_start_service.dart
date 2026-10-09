import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../logging/app_talker.dart';
import 'auto_start_service.dart';

/// Десктопная реализация сервиса управления автозапуском через системный реестр / launch_at_startup.
class DesktopAutoStartService implements AutoStartService {
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (kIsWeb || !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      talker.debug('DesktopAutoStartService: пропуск инициализации (не десктоп)');
      return;
    }

    if (_isInitialized) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      launchAtStartup.setup(
        appName: packageInfo.appName.isNotEmpty ? packageInfo.appName : 'Smoking Habit',
        appPath: Platform.resolvedExecutable,
      );

      _isInitialized = true;
      talker.info('DesktopAutoStartService успешно инициализирован');
    } catch (e, st) {
      talker.handle(e, st, 'Ошибка при инициализации DesktopAutoStartService');
    }
  }

  @override
  Future<bool> isEnabled() async {
    if (kIsWeb || !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return false;
    }

    try {
      if (!_isInitialized) {
        await initialize();
      }
      return await launchAtStartup.isEnabled();
    } catch (e, st) {
      talker.handle(e, st, 'Ошибка проверки статуса автозапуска');
      return false;
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (kIsWeb || !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return;
    }

    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (enabled) {
        await launchAtStartup.enable();
        talker.info('Автозапуск приложения включен');
      } else {
        await launchAtStartup.disable();
        talker.info('Автозапуск приложения отключен');
      }
    } catch (e, st) {
      talker.handle(e, st, 'Ошибка изменения статуса автозапуска ($enabled)');
      rethrow;
    }
  }
}
