import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/main_layout_widget.dart';
import 'homepage/home_page.dart';
import 'tools/tools_page.dart';
import 'cart/cart_page.dart';
import 'sales/sales_page.dart';
import 'settings/settings_page.dart';

class UserDashboard extends StatefulWidget {
  final int initialTabIndex;

  const UserDashboard({super.key, this.initialTabIndex = 0});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  final List<Widget> _pages = [
    const HomePage(),
    const ToolsPage(),
    const SalesPage(),
    const CartPage(),
    const AdvancedSettingsPage(),
  ];

  final List<String> _titles = [
    'user.nav.home',
    'user.nav.tools',
    'user.nav.sales',
    'user.nav.cart',
    'user.nav.settings',
  ];

  @override
  Widget build(BuildContext context) {
    return MainLayoutWidget(
      currentIndex: _currentIndex,
      title: _titles[_currentIndex].tr(),
      onNavigationTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      child: _pages[_currentIndex],
    );
  }
}
