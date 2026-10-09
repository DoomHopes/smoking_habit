import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../core/logging/app_talker.dart';
import 'home_page.dart';
import 'statistics_page.dart';

/// Главный экран с нижней навигацией между учетом и аналитикой.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _openTalkerScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TalkerScreen(talker: talker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smoke_free_rounded, size: 24),
            const SizedBox(width: 8),
            Text(
              _currentIndex == 0 ? 'Учёт сигарет' : 'Статистика курения',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Логи приложения (Talker)',
            onPressed: () => _openTalkerScreen(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomePage(),
          StatisticsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined_rounded),
            selectedIcon: Icon(Icons.insert_chart_rounded),
            label: 'Статистика',
          ),
        ],
      ),
    );
  }
}
