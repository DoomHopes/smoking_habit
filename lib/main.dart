import 'dart:ui';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'core/logging/app_talker.dart';
import 'data/datasources/sqlite_smoking_local_datasource.dart';
import 'data/repositories/smoking_repository_impl.dart';
import 'presentation/bloc/smoking_bloc.dart';
import 'presentation/bloc/smoking_event.dart';
import 'presentation/pages/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Глобальный перехват ошибок Flutter фреймворка
  FlutterError.onError = (details) {
    talker.handle(details.exception, details.stack, 'Flutter Error');
  };

  // Перехват асинхронных ошибок платформы
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack, 'Uncaught Platform Error');
    return true;
  };

  talker.info('Инициализация приложения Smoking Habit');

  // Инициализация слоев данных и репозитория
  final localDataSource = SqliteSmokingLocalDataSource();
  final repository = SmokingRepositoryImpl(localDataSource);
  final smokingBloc = SmokingBloc(repository)..add(const LoadSmokingRecords());

  runApp(
    SmokingHabitApp(smokingBloc: smokingBloc),
  );
}

/// Корневой виджет приложения.
class SmokingHabitApp extends StatelessWidget {
  final SmokingBloc smokingBloc;

  const SmokingHabitApp({
    super.key,
    required this.smokingBloc,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSignalProvider<SmokingBloc>.value(
      value: smokingBloc,
      child: MaterialApp(
        title: 'Учёт сигарет',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        navigatorObservers: [
          TalkerRouteObserver(talker),
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10B981), // Современный изумрудно-зеленый
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10B981),
            brightness: Brightness.dark,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}
