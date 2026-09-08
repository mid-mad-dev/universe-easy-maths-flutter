import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'courses_screen.dart';
import 'doubts_screen.dart';
import 'learning_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  late final List<Widget> pages = [
    const HomeScreenContent(),
    const CoursesScreen(),
    const DoubtsScreen(),
    const LearningScreen(),
    ProfileScreen(onSelectTab: (value) => setState(() => index = value)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: index,
        onTap: (value) => setState(() => index = value),
      ),
    );
  }
}
