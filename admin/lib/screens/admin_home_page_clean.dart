import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';
import '../widgets/navigation_footer.dart';
import '../services/realtime_database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_management_screen.dart';
import 'category_management_screen.dart';
import 'promotion_management_screen.dart';
import '../widgets/admin_search_bar.dart';
import '../widgets/admin_notification_bell.dart';
// Removed categories management screen

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _DashboardToolbar extends StatefulWidget {
  const _DashboardToolbar({
    required this.onRefresh,
    required this.onOpenQuickActions,
  });

  final VoidCallback onRefresh;
  final VoidCallback onOpenQuickActions;

  @override
  State<_DashboardToolbar> createState() => _DashboardToolbarState();
}

class _DashboardToolbarState extends State<_DashboardToolbar>
    with TickerProviderStateMixin {
  late final AnimationController _searchController;
  bool _expanded = false;
  String _searchValue = '';

  @override
  void initState() {
    super.initState();
    _searchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _searchController.forward();
    } else {
      _searchController.reverse();
      setState(() => _searchValue = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _searchController,
                curve: Curves.easeOutExpo,
              ),
              child: FadeTransition(
                opacity: _searchController,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: AdminSearchBar(
                    hintText: 'Rechercher dans l\'admin...',
                    onChanged: (value) => setState(() => _searchValue = value),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Rechercher',
              onPressed: _toggleSearch,
              icon: Icon(
                _expanded ? Icons.close_rounded : Icons.search_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            AdminNotificationBell(
              iconColor: Colors.white,
              onNotificationsViewed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Notifications actualisées'),
                    backgroundColor: AppTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Rafraîchir',
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Actions',
              onPressed: widget.onOpenQuickActions,
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withOpacity(0.12),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
              ),
            ),
          ],
        ),
        if (_expanded && _searchValue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: _SearchResultsPreview(query: _searchValue, theme: theme),
          ),
      ],
    );
  }
}

class _SearchResultsPreview extends StatelessWidget {
  const _SearchResultsPreview({required this.query, required this.theme});

  final String query;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Produits correspondant à "$query"',
      'Catégories contenant "$query"',
      'Promotions actives liées à "$query"',
    ];

    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Suggestions intelligentes',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              // TODO: hook into global search results page
            },
            child: const Text('Voir tous les résultats'),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeaderSkeleton extends StatelessWidget {
  const _DashboardHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: List.generate(4, (index) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white,
          period: const Duration(milliseconds: 1400),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
      }),
    );
  }
}

class _QuickActionCarousel extends StatelessWidget {
  const _QuickActionCarousel({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final highlightCards = [
      (
        title: 'Créer un produit',
        message: 'Ajoutez un nouveau produit avec photos et variations.',
        icon: Icons.add_shopping_cart_rounded,
        color: AppTheme.primaryColor,
      ),
      (
        title: 'Planifier une promo',
        message: 'Boostez les ventes avec une promotion attrayante.',
        icon: Icons.local_fire_department_rounded,
        color: AppTheme.warningColor,
      ),
      (
        title: 'Inviter un manager',
        message: 'Partagez l\'accès avec un nouveau membre de l\'équipe.',
        icon: Icons.group_add_rounded,
        color: AppTheme.successColor,
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Suggestions rapides',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.82),
              itemCount: highlightCards.length,
              itemBuilder: (context, index) {
                final card = highlightCards[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [card.color.withOpacity(0.14), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: card.color.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(card.icon, color: card.color, size: 24),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          card.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.message,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Lancer'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Lottie.asset(
            'lib/assets/animations/category_loader.json',
            height: 90,
            repeat: true,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;
  bool _showQuickActions = false;

  final List<Widget> _pages = [
    const DashboardTab(),
    const ProductsTab(),
    const CategoryManagementScreen(),
    const AnalyticsTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationFooter(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        isAdmin: true,
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'totalProducts': 0,
    'totalOrders': 0,
    'totalRevenue': 0.0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() => _isLoading = true);

      // Load stats
      await RealtimeDatabaseService.updateStats();
      final stats = await RealtimeDatabaseService.getStats();

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientContainer(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Dashboard',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage your store efficiently',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      _DashboardToolbar(
                        onRefresh: _loadStats,
                        onOpenQuickActions: () => setState(() {
                          _showQuickActions = !_showQuickActions;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Statistics Cards
                  Text(
                    'Store Statistics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const _DashboardHeaderSkeleton()
                      : GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          children: [
                            _buildStatCard(
                              context,
                              'Total Users',
                              _stats['totalUsers'].toString(),
                              Icons.people,
                              AppTheme.primaryColor,
                            ),
                            _buildStatCard(
                              context,
                              'Total Products',
                              _stats['totalProducts'].toString(),
                              Icons.inventory_2,
                              AppTheme.successColor,
                            ),
                            _buildStatCard(
                              context,
                              'Total Orders',
                              _stats['totalOrders'].toString(),
                              Icons.shopping_cart,
                              AppTheme.warningColor,
                            ),
                            _buildStatCard(
                              context,
                              'Revenue',
                              '${_stats['totalRevenue'].toStringAsFixed(0)} €',
                              Icons.attach_money,
                              AppTheme.errorColor,
                            ),
                          ],
                        ),
                  const SizedBox(height: 30),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 350),
                    crossFadeState: _showQuickActions
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildQuickActionCard(
                          context,
                          'Promotions',
                          Icons.local_offer_rounded,
                          AppTheme.primaryColor,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PromotionManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          'Produits',
                          Icons.inventory_2,
                          AppTheme.successColor,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProductManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          'Catégories',
                          Icons.category_rounded,
                          AppTheme.warningColor,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CategoryManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          'Commandes',
                          Icons.receipt_long_rounded,
                          AppTheme.errorColor,
                          () {
                            // TODO: navigate to orders management
                          },
                        ),
                      ],
                    ),
                    secondChild: _QuickActionCarousel(
                      onClose: () {
                        setState(() {
                          _showQuickActions = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().slideY(delay: 200.ms, begin: 0.3, end: 0);
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(delay: 400.ms, begin: 0.3, end: 0);
  }
}

class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Product Management',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Manage your categories, subcategories, and products',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductManagementScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Product Management'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Removed CategoriesTab

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Analytics',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Track your store performance and sales',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement analytics
              },
              icon: const Icon(Icons.trending_up),
              label: const Text('View Analytics'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Configure your store settings',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/auth');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
