import 'package:flutter/material.dart';

import '../widget/bottom_nav_bar.dart';
import 'map/map_screen.dart';
import 'profile/profile_screen.dart';

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
    _Placeholder(label: 'Forum'),
    _Placeholder(label: 'Pest ID'),
    _Placeholder(label: 'Pooling'),
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

/// Temporary placeholder for screens not yet built.
class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
