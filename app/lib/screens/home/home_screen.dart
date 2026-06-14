import 'package:flutter/material.dart';

import '../achievement/achievement_screen.dart';
import '../character/character_screen.dart';
import '../commute/commute_screen.dart';
import '../equipment/equipment_screen.dart';
import '../ranking/ranking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    CommuteScreen(),
    CharacterScreen(),
    EquipmentScreen(),
    AchievementScreen(),
    RankingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_subway),
            selectedIcon: Icon(Icons.directions_subway, color: Colors.white),
            label: '던전',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: '캐릭터',
          ),
          NavigationDestination(
            icon: Icon(Icons.backpack_outlined),
            selectedIcon: Icon(Icons.backpack, color: Colors.white),
            label: '장비',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events, color: Colors.white),
            label: '업적',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard, color: Colors.white),
            label: '랭킹',
          ),
        ],
      ),
    );
  }
}
