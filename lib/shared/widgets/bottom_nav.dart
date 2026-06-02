import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/presentation/homescreen/home_screen.dart';
import 'package:kudipay/presentation/profile/profile_screen.dart';
import 'package:kudipay/presentation/support/support_screen.dart';
import 'package:kudipay/presentation/transaction/transaction_screen.dart';
import 'package:kudipay/provider/refresh/refresh_provider.dart';

// BottomNavBar upgraded to ConsumerStatefulWidget so it can:
//   1. Trigger an initial full data load as soon as the shell mounts
//   2. Remain the single place where we kick off background refresh
class BottomNavBar extends ConsumerStatefulWidget {
  const BottomNavBar({super.key});

  @override
  ConsumerState<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends ConsumerState<BottomNavBar> {
  int _currentIndex = 0;

  // Screens are constant — Flutter re-uses the widget tree between tab switches.
  final List<Widget> _screens = [
    const HomeScreen(),
    const TransactionsScreen(),
    const SupportScreen(),
    const UserProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Kick off the very first data load after the frame renders.
    // This guarantees all tabs have fresh data immediately on login,
    // without requiring the user to pull-to-refresh manually.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refreshProvider.notifier).refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF069494),
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz),
              label: 'Transaction',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.headphones_outlined),
              label: 'Support',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  void onTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
