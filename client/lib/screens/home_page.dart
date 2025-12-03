import 'package:flutter/material.dart';
import '../widgets/navigation_footer.dart';
import 'tabs/home_tab.dart';
import 'tabs/categories_tab.dart';
import 'tabs/cart_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/favorites_tab.dart';

class LivriYESHomePage extends StatefulWidget {
  final int initialIndex;

  const LivriYESHomePage({super.key, this.initialIndex = 0});

  @override
  State<LivriYESHomePage> createState() => _LivriYESHomePageState();
}

class _LivriYESHomePageState extends State<LivriYESHomePage> {
  late int _selectedIndex;
  final GlobalKey<OrdersTabState> _ordersTabKey = GlobalKey();

  List<Widget> get _pages => [
    HomeTab(
      onNavigateToCategories: () => setState(() => _selectedIndex = 1),
      onNavigateToCart: () => setState(() => _selectedIndex = 2),
    ),
    CategoriesTab(onBackToHome: () => setState(() => _selectedIndex = 0)),
    CartTab(onBackToHome: () => setState(() => _selectedIndex = 0)),
    FavoritesTab(onBackToHome: () => setState(() => _selectedIndex = 0)),
    OrdersTab(
      key: _ordersTabKey,
      onBackToHome: () => setState(() => _selectedIndex = 0),
    ),
    ProfileTab(onBackToHome: () => setState(() => _selectedIndex = 0)),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex == 0) {
          // User is on home tab, show exit confirmation
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text('Quitter l\'application'),
                content: const Text(
                  'Voulez-vous vraiment quitter l\'application ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Non'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Oui'),
                  ),
                ],
              );
            },
          );

          return shouldExit ?? false;
        } else {
          // User is in any other tab, redirect to home tab
          setState(() {
            _selectedIndex = 0;
          });
          return false; // Prevent app exit
        }
      },
      child: Scaffold(
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
      ),
    );
  }
}
