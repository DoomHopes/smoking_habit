import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:flutter/material.dart';

import 'data/datasources/sqlite_smoking_local_datasource.dart';
import 'data/repositories/smoking_repository_impl.dart';
import 'presentation/bloc/smoking_bloc.dart';
import 'presentation/bloc/smoking_event.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: Brightness.dark,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
