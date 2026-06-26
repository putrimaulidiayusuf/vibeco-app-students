import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../student/clean_rank_screen.dart';
import 'class_monitor_screen.dart';
import 'piket_management_screen.dart';
import 'verification_queue_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;

  List<Widget> _buildScreens(String roleType) {
    if (roleType == 'homeroom') {
      return const [
        ClassMonitorScreen(),
        PiketManagementScreen(),
        CleanRankScreen(),
      ];
    } else if (roleType == 'plh') {
      return const [
        VerificationQueueScreen(),
        CleanRankScreen(),
      ];
    } else {
      // Regular teacher
      return const [
        CleanRankScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _buildNavItems(String roleType) {
    if (roleType == 'homeroom') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics_rounded),
          label: 'Pantau Kelas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month_rounded),
          label: 'Jadwal Piket',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard_outlined),
          activeIcon: Icon(Icons.leaderboard_rounded),
          label: 'CleanRank',
        ),
      ];
    } else if (roleType == 'plh') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.fact_check_outlined),
          activeIcon: Icon(Icons.fact_check_rounded),
          label: 'Validasi AI',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard_outlined),
          activeIcon: Icon(Icons.leaderboard_rounded),
          label: 'CleanRank',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard_outlined),
          activeIcon: Icon(Icons.leaderboard_rounded),
          label: 'CleanRank',
        ),
      ];
    }
  }

  String _getRoleLabel(String? roleType) {
    switch (roleType) {
      case 'homeroom':
        return 'Guru Wali Kelas';
      case 'plh':
        return 'Guru PLH';
      default:
        return 'Guru Biasa';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String roleType = user.roleType ?? 'regular';
    final screens = _buildScreens(roleType);
    final navItems = _buildNavItems(roleType);

    // Safeguard index out of bounds on role switches
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _getRoleLabel(user.roleType) + (user.className != null ? ' - Kelas ${user.className}' : ''),
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('logout_button'),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Keluar Aplikasi'),
                  content: const Text('Apakah Anda yakin ingin keluar dari ZieClean?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await auth.clearSession();
              }
            },
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: navItems.length > 1
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: navItems,
            )
          : null,
    );
  }
}
