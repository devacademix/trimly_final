import 'package:flutter/material.dart';
import '../dashboard/salon_dashboard_screen.dart';
import '../bookings/bookings_list_screen.dart';
import '../customers/customers_screen.dart';
import '../wallet/wallet_screen.dart';
import '../more/more_hub_screen.dart';

class SalonNavigation extends StatefulWidget {
  const SalonNavigation({super.key});

  @override
  State<SalonNavigation> createState() => _SalonNavigationState();
}

class _SalonNavigationState extends State<SalonNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const SalonDashboardScreen(),
    const BookingsListScreen(),
    const CustomersScreen(),
    const WalletScreen(),
    const MoreHubScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.blueGrey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_outlined),
            activeIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}


