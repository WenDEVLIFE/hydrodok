import 'package:flutter/material.dart';
import 'user/forum/forum_screen.dart';
import 'user/map/map_screen.dart';
import 'user/pest_id/pest_id_screen.dart';
import 'user/pooling/pooling_screen.dart';
import 'user/profile/profile_screen.dart';

import '../widget/bottom_nav_bar.dart';


/// Root shell that hosts the bottom nav and switches between feature screens.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Screens ordered to match FitFormBottomNav items:
  //  0 → Map, 1 → Forum, 2 → Pest ID, 3 → Pooling, 4 → Profile
  final List<Widget> _screens = const [
    MapScreen(),
    ForumScreen(),
    PestIdScreen(),
    PoolingScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: FitFormBottomNav(
        currentIndex: _currentIndex,
        onIndexChanged: (index) => setState(() => _currentIndex = index),
      ),
      extendBody: true,
    );
  }
}
