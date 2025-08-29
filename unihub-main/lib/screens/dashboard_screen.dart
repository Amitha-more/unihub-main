import 'package:flutter/material.dart';
import 'modern_home_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'more_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const ModernHomeScreen(),
    const Center(child: Text('Notes')),
    const EventsScreen(),
    const ProfileScreen(),
    const MoreScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: NavigationBar(
            height: 65,
            backgroundColor: Colors.white,
            indicatorColor: Colors.transparent,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              _buildNavigationDestination(
                icon: Icons.home_outlined,
                label: 'Home',
                index: 0,
              ),
              _buildNavigationDestination(
                icon: Icons.menu_book_outlined,
                label: 'Notes',
                index: 1,
              ),
              _buildNavigationDestination(
                icon: Icons.event_outlined,
                label: 'Events',
                index: 2,
              ),
              _buildNavigationDestination(
                icon: Icons.person_outline,
                label: 'Profile',
                index: 3,
              ),
              _buildNavigationDestination(
                icon: Icons.more_horiz,
                label: 'More',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavigationDestination({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return NavigationDestination(
      icon: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
        size: 24,
      ),
      label: label,
    );
  }
} 