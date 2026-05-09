import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'add_screen.dart';
import 'database_screen.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AddScreen(),
    const DatabaseScreen(),
    const InventoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -4)),
        ]),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'HOME',
                isActive: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
              _NavItemAdd(isActive: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
              _NavItem(icon: Icons.search, activeIcon: Icons.search, label: 'DATABASE',
                isActive: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
              _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'INVENTORI',
                isActive: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
              _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'PROFIL',
                isActive: _currentIndex == 4, onTap: () => setState(() => _currentIndex = 4)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isActive ? activeIcon : icon, color: isActive ? AppTheme.primary : AppTheme.textMuted, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
            color: isActive ? AppTheme.primary : AppTheme.textMuted, letterSpacing: 0.5)),
        ]),
      ),
    );
  }
}

class _NavItemAdd extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  const _NavItemAdd({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: isActive ? AppTheme.primary : Colors.grey.shade200, shape: BoxShape.circle),
          child: Icon(Icons.add, color: isActive ? Colors.white : AppTheme.textSecondary, size: 24)),
        const SizedBox(height: 2),
        Text('TAMBAH', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
          color: isActive ? AppTheme.primary : AppTheme.textMuted, letterSpacing: 0.5)),
      ]),
    );
  }
}
