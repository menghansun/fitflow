import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'calendar/calendar_screen.dart';
import 'stats/stats_screen.dart';
import 'profile/profile_screen.dart';
import 'workout_type_selector.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // 0=home 1=calendar 2=stats 3=profile

  final List<Widget> _screens = [
    const HomeScreen(),
    CalendarScreen(),
    const StatsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha:0.08)
                  : Colors.black.withValues(alpha:0.08),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: (index) {
            if (index == 2) {
              _showWorkoutSelector();
            } else {
              setState(() {
                _currentIndex = index < 2 ? index : index - 1;
              });
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '首页',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: '日历',
            ),
            BottomNavigationBarItem(
              icon: _AddButton(),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: '统计',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }

  // Map 4-page index → 5-item nav index
  int get _navIndex {
    if (_currentIndex < 2) return _currentIndex;
    return _currentIndex + 1;
  }

  void _showWorkoutSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WorkoutTypeSelectorSheet(),
    );
  }
}

class _AddButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkPrimary, AppColors.swimAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkPrimary.withValues(alpha:0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}
