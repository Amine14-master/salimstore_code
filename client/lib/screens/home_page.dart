import 'package:flutter/material.dart';
import '../widgets/navigation_footer.dart';
import 'tabs/home_tab.dart';
import 'tabs/categories_tab.dart';
import 'tabs/cart_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/favorites_tab.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  int _selectedIndex = 0;
  final GlobalKey<OrdersTabState> _ordersTabKey = GlobalKey();

  List<Widget> get _pages => [
    HomeTab(
      onNavigateToCategories: () => setState(() => _selectedIndex = 1),
      onNavigateToCart: () => setState(() => _selectedIndex = 2),
    ),
    const CategoriesTab(),
    const CartTab(),
    const FavoritesTab(),
    OrdersTab(key: _ordersTabKey),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationFooter(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          // Refresh OrdersTab when navigating to it
          if (index == 4 && _ordersTabKey.currentState != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _ordersTabKey.currentState?.refresh();
            });
          }
        },
        isAdmin: false,
      ),
    );
  }
}
