import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NavigationFooter extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final bool isAdmin;

  const NavigationFooter({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textLight,
        items: isAdmin ? _getAdminItems() : _getClientItems(),
      ),
    );
  }

  List<BottomNavigationBarItem> _getAdminItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Tableau de Bord',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.inventory_outlined),
        activeIcon: Icon(Icons.inventory),
        label: 'Produits',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.category_outlined),
        activeIcon: Icon(Icons.category),
        label: 'Catégories',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.local_offer_outlined),
        activeIcon: Icon(Icons.local_offer),
        label: 'Promotions',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long_outlined),
        activeIcon: Icon(Icons.receipt_long),
        label: 'Commandes',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.group_outlined),
        activeIcon: Icon(Icons.group),
        label: 'Utilisateurs',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.analytics_outlined),
        activeIcon: Icon(Icons.analytics),
        label: 'Analyses',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];
  }

  List<BottomNavigationBarItem> _getClientItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Accueil',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.category_outlined),
        activeIcon: Icon(Icons.category),
        label: 'Catégories',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart_outlined),
        activeIcon: Icon(Icons.shopping_cart),
        label: 'Panier',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];
  }
}
