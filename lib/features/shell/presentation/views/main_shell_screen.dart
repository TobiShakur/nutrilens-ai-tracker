import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../alacena/presentation/views/alacena_screen.dart';
import '../../../diario/presentation/views/dashboard_screen.dart';
import '../../../diario/presentation/widgets/app_nav_bar.dart';
import '../../../perfil/presentation/views/perfil_screen.dart';
import '../../../scanner/presentation/views/scanner_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  void _onCenterTap() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: const [
              DashboardScreen(),
              AlacenaScreen(),
              PerfilScreen(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppNavBar(
              selectedIndex: _currentIndex,
              onItemSelected: _onTabSelected,
              onCenterTap: _onCenterTap,
            ),
          ),
        ],
      ),
    );
  }
}
