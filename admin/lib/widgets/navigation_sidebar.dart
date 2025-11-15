import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

class NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final bool isCollapsed;
  final Function() onToggleCollapse;
  final int pendingOrdersCount;

  const NavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.isCollapsed,
    required this.onToggleCollapse,
    this.pendingOrdersCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final items = _getAdminItems();

    return Container(
      width: isCollapsed ? 84 : 264,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1F2937),
            blurRadius: 18,
            offset: Offset(2, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 72,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? AppSpacing.md : AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(color: AppTheme.surfaceColor),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Salim Store',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Admin Panel',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    isCollapsed ? Icons.menu : Icons.menu_open,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: onToggleCollapse,
                  tooltip: isCollapsed ? 'Expand' : 'Collapse',
                ),
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = selectedIndex == index;

                return _buildMenuItem(
                  context: context,
                  icon: item['icon'] as IconData,
                  activeIcon: item['activeIcon'] as IconData,
                  label: item['label'] as String,
                  isSelected: isSelected,
                  isCollapsed: isCollapsed,
                  onTap: () => onTap(index),
                  badgeCount: (item['label'] as String) == 'Commandes'
                      ? pendingOrdersCount
                      : 0,
                );
              }).toList(),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.textLight.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: isCollapsed
                ? Icon(
                    Icons.admin_panel_settings,
                    color: AppTheme.primaryColor,
                    size: 24,
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Administrator',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required bool isCollapsed,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final bool isCommandes = label == 'Commandes';
    final bool showBadge = badgeCount > 0;
    final iconData = isSelected ? activeIcon : icon;
    final iconColor = isSelected
        ? AppTheme.primaryColor
        : AppTheme.textSecondary;

    Widget iconWidget = Icon(iconData, color: iconColor, size: 24);

    if (isCommandes && showBadge) {
      iconWidget = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: isCollapsed ? 44 : 52,
            height: isCollapsed ? 44 : 52,
            child: Lottie.asset(
              'lib/assets/animations/category_loader.json',
              repeat: true,
              animate: true,
              fit: BoxFit.cover,
            ),
          ),
          Icon(iconData, color: iconColor, size: 24),
        ],
      );
    }

    final menuTile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.16),
                      AppTheme.primaryColor.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
          ),
          child: Row(
            children: [
              iconWidget,
              if (!isCollapsed) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          menuTile,
          if (showBadge)
            Positioned(
              right: isCollapsed ? 10 : 16,
              top: isCollapsed ? -2 : 8,
              child: _buildBadge(badgeCount, isCollapsed),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAdminItems() {
    return [
      {
        'icon': Icons.dashboard_outlined,
        'activeIcon': Icons.dashboard,
        'label': 'Tableau de Bord',
      },
      {
        'icon': Icons.inventory_outlined,
        'activeIcon': Icons.inventory,
        'label': 'Produits',
      },
      {
        'icon': Icons.category_outlined,
        'activeIcon': Icons.category,
        'label': 'Catégories',
      },
      {
        'icon': Icons.local_offer_outlined,
        'activeIcon': Icons.local_offer,
        'label': 'Promotions',
      },
      {
        'icon': Icons.receipt_long_outlined,
        'activeIcon': Icons.receipt_long,
        'label': 'Commandes',
      },
      {
        'icon': Icons.group_outlined,
        'activeIcon': Icons.group,
        'label': 'Utilisateurs',
      },
      {
        'icon': Icons.analytics_outlined,
        'activeIcon': Icons.analytics,
        'label': 'Analyses',
      },
      {
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
        'label': 'Profil',
      },
    ];
  }

  Widget _buildBadge(int count, bool isCollapsed) {
    final display = count > 99 ? '99+' : count.toString();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 8 : 12,
        vertical: isCollapsed ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.white,
        highlightColor: Colors.white.withOpacity(0.8),
        child: Text(
          display,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: isCollapsed ? 12 : 13,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
