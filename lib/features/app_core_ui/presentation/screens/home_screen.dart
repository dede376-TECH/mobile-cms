import 'package:flutter/material.dart';
import '../../../player/presentation/screens/players_screen.dart';
import '../../../schedule/presentation/screens/schedules_screen.dart';
import '../../../media/presentation/screens/media_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PlayersScreen(),
    SchedulesScreen(),
    MediaScreen(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
            icon: Icon(Icons.tv_outlined),
            selectedIcon: Icon(Icons.tv),
            label: 'Players',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Planifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.perm_media_outlined),
            selectedIcon: Icon(Icons.perm_media),
            label: 'Médias',
          ),
        ],
      ),
    );
  }
}
