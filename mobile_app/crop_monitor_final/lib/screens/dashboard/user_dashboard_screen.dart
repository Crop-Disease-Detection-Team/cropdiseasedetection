import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../history/history_screen.dart';
import '../predict/predict_screen.dart';
import '../profile/profile_screen.dart';
import 'home_tab.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _index = 0;

  void _goToScan() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PredictScreen()));
  }

  void _goToHistoryTab() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(onScanTap: _goToScan, onHistoryTap: _goToHistoryTab),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.green700,
        onPressed: _goToScan,
        child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', index: 0),
              _navItem(
                  icon: Icons.history_outlined, activeIcon: Icons.history, label: 'History', index: 1),
              const SizedBox(width: 40), // space for the notch/FAB
              _navItem(
                  icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', index: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final selected = _index == index;
    final color = selected ? AppColors.green700 : AppColors.gray500;
    return InkWell(
      onTap: () => setState(() => _index = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
