import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../firebase_options.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../widgets/navigation_footer.dart';
import '../widgets/navigation_sidebar.dart';
// unused imports removed after embedding ProductManagementScreen
import '../services/payment_service.dart';
// Removed categories management screen
import 'product_management_screen.dart';
import 'category_management_screen.dart';
import 'promotion_management_screen.dart';
import 'tabs/dashboard_tab.dart' as sep;
import 'tabs/products_tab.dart' as sep;
import 'tabs/analytics_tab.dart' as sep;
import 'tabs/profile_tab.dart' as sep;
import 'tabs/users_tab.dart' as sep;
import 'tabs/orders_tab.dart' as sep;
// components imported inside specific tabs

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _DesktopTopBar extends StatelessWidget {
  final String title;

  const _DesktopTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vue d’ensemble des activités de Salim Store',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 320,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
            child: const Icon(Icons.person, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;
  int _pendingOrdersCount = 0;
  StreamSubscription<DatabaseEvent>? _pendingOrdersSubscription;
  bool _initialPendingSnapshotHandled = false;
  late final AudioPlayer _alertPlayer;

  late final List<Widget> _pages;
  late final List<String> _pageTitles;

  @override
  void initState() {
    super.initState();
    _alertPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    _pages = [
      sep.DashboardTab(
        onNavigateToTab: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
      const sep.ProductsTab(),
      const CategoryManagementScreen(),
      const PromotionManagementScreen(),
      const sep.OrdersTab(),
      const sep.UsersTab(),
      const sep.AnalyticsTab(),
      const sep.ProfileTab(),
    ];
    _pageTitles = [
      'Tableau de bord',
      'Produits',
      'Catégories',
      'Promotions',
      'Commandes',
      'Utilisateurs',
      'Analyses',
      'Profil',
    ];
    _listenPendingOrders();
  }

  @override
  void dispose() {
    _pendingOrdersSubscription?.cancel();
    _alertPlayer.dispose();
    super.dispose();
  }

  void _listenPendingOrders() {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
    );
    final ref = db.ref('orders');

    _pendingOrdersSubscription?.cancel();
    _pendingOrdersSubscription = ref.onValue.listen(
      (event) {
        if (!mounted) return;

        final data = event.snapshot.value;
        final previousCount = _pendingOrdersCount;
        final pendingCount = _extractPendingCount(data);
        final shouldPlayAlert =
            _initialPendingSnapshotHandled && pendingCount > previousCount;

        if (pendingCount != previousCount) {
          setState(() => _pendingOrdersCount = pendingCount);
        }

        if (shouldPlayAlert) {
          _playNewOrderSound();
        }

        _initialPendingSnapshotHandled = true;
      },
      onError: (error) {
        debugPrint('Error listening to pending orders: $error');
      },
    );
  }

  int _extractPendingCount(dynamic data) {
    int pending = 0;

    bool isPendingStatus(String? status) {
      if (status == null) return false;
      final normalized = status.trim().toLowerCase();
      return normalized == 'pending' || normalized == 'en attente';
    }

    void handleOrder(dynamic rawOrder) {
      if (rawOrder is Map) {
        final status = rawOrder['status']?.toString();
        if (isPendingStatus(status)) {
          pending++;
        }
      }
    }

    if (data is Map) {
      for (final value in data.values) {
        handleOrder(value);
      }
    } else if (data is List) {
      for (final value in data) {
        if (value != null) {
          handleOrder(value);
        }
      }
    }

    return pending;
  }

  Future<void> _playNewOrderSound() async {
    try {
      await _alertPlayer.stop();
      await _alertPlayer.play(BytesSource(_newOrderToneBytes));
    } catch (e) {
      debugPrint('Failed to play new order sound: $e');
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  static final Uint8List _newOrderToneBytes = _generateNewOrderTone();

  static Uint8List _generateNewOrderTone() {
    const sampleRate = 44100;
    const durationSeconds = 0.9;
    const amplitude = 0.98;
    const vibratoFrequency = 5.5;
    const shimmerFrequency = 13.5;

    final totalSamples = (sampleRate * durationSeconds).round();
    final dataLength = totalSamples * 2; // 16-bit mono
    final totalLength = 44 + dataLength;
    final byteData = ByteData(totalLength);

    // RIFF header
    byteData.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    byteData.setUint32(4, totalLength - 8, Endian.little);
    byteData.setUint32(8, 0x57415645, Endian.big); // "WAVE"

    // fmt chunk
    byteData.setUint32(12, 0x666d7420, Endian.big); // "fmt "
    byteData.setUint32(16, 16, Endian.little); // PCM chunk size
    byteData.setUint16(20, 1, Endian.little); // Audio format (PCM)
    byteData.setUint16(22, 1, Endian.little); // Channels
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    byteData.setUint16(32, 2, Endian.little); // block align
    byteData.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    byteData.setUint32(36, 0x64617461, Endian.big); // "data"
    byteData.setUint32(40, dataLength, Endian.little);

    const twoPi = 2 * math.pi;

    for (var i = 0; i < totalSamples; i++) {
      final time = i / sampleRate;
      final progress = i / totalSamples;

      List<double> frequencies;
      if (progress < 0.33) {
        frequencies = [587.33, 880.0];
      } else if (progress < 0.66) {
        frequencies = [739.99, 1108.73, 1479.98];
      } else {
        frequencies = [880.0, 1318.51, 1760.0];
      }

      final vibrato = 1 + 0.012 * math.sin(twoPi * vibratoFrequency * time);
      final shimmer = 1 + 0.08 * math.sin(twoPi * shimmerFrequency * time);

      final attack = time < 0.12 ? math.pow(time / 0.12, 0.85) : 1.0;
      final decay = math.pow(1 - progress, 1.4);
      final envelope = (attack * decay * shimmer).clamp(0.0, 1.25);

      double sampleSum = 0;
      for (final baseFrequency in frequencies) {
        final freq = baseFrequency * vibrato;
        final fundamental = math.sin(twoPi * freq * time);
        final overtone = 0.4 * math.sin(twoPi * freq * 2 * time);
        final softPad = 0.2 * math.sin(twoPi * freq * 0.5 * time);
        sampleSum += fundamental + overtone + softPad;
      }

      sampleSum /= frequencies.length;
      final scaled = sampleSum * envelope * amplitude;
      var intSample = (scaled * 0x7FFF).round();
      if (intSample > 32767) intSample = 32767;
      if (intSample < -32768) intSample = -32768;
      byteData.setInt16(44 + (i * 2), intSample, Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  // Check if screen is desktop (width >= 600 for better desktop support)
  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);

    if (isDesktop) {
      // Desktop layout with sidebar and top bar
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Row(
            children: [
              NavigationSidebar(
                selectedIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                isCollapsed: _sidebarCollapsed,
                onToggleCollapse: () {
                  setState(() => _sidebarCollapsed = !_sidebarCollapsed);
                },
                pendingOrdersCount: _pendingOrdersCount,
              ),
              Expanded(
                child: Column(
                  children: [
                    _DesktopTopBar(title: _pageTitles[_selectedIndex]),
                    Expanded(
                      child: Container(
                        color: AppTheme.backgroundColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: _pages[_selectedIndex],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Mobile layout with bottom navigation
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            _pageTitles[_selectedIndex],
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: true,
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavigationFooter(
          selectedIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          isAdmin: true,
        ),
      );
    }
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 30),
              _buildStatsCards(context),
              const SizedBox(height: 30),
              _buildRecentOrders(context),
              const SizedBox(height: 30),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, Admin!',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            Text(
              'Salim Store Dashboard',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.admin_panel_settings,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    ).animate().slideX(delay: 200.ms, begin: -0.3, end: 0);
  }

  Widget _buildStatsCards(BuildContext context) {
    final stats = [
      {
        'title': 'Total Orders',
        'value': '1,234',
        'icon': Icons.shopping_cart,
        'color': Colors.blue,
      },
      {
        'title': 'Revenue',
        'value': '\$45,678',
        'icon': Icons.attach_money,
        'color': Colors.green,
      },
      {
        'title': 'Products',
        'value': '567',
        'icon': Icons.inventory,
        'color': Colors.orange,
      },
      {
        'title': 'Customers',
        'value': '890',
        'icon': Icons.people,
        'color': Colors.purple,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return CustomCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                stat['value'] as String,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                stat['title'] as String,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    ).animate().slideY(delay: 400.ms, begin: 0.3, end: 0);
  }

  Widget _buildRecentOrders(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(5, (index) {
          return CustomCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${2000 + index}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Customer: Customer ${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${(index + 1) * 75}.00',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pending',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.successColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    ).animate().slideY(delay: 600.ms, begin: 0.3, end: 0);
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'title': 'Add Product', 'icon': Icons.add_box, 'color': Colors.blue},
      {'title': 'View Orders', 'icon': Icons.list_alt, 'color': Colors.green},
      {'title': 'Manage Users', 'icon': Icons.people, 'color': Colors.orange},
      {'title': 'Analytics', 'icon': Icons.analytics, 'color': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return CustomCard(
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action['title'] as String,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ).animate().slideY(delay: 800.ms, begin: 0.3, end: 0);
  }
}

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  @override
  Widget build(BuildContext context) {
    // Embed product management UI directly
    return const ProductManagementScreen();
  }
}

// Removed CategoriesTab and all references to CategoryManagementScreen

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: AppTheme.textLight),
            SizedBox(height: 16),
            Text(
              'Analytics Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming Soon!',
              style: TextStyle(color: AppTheme.textSecondary),
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
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: const Center(child: Text('Settings Page')),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Profil Administrateur',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _AdminPaymentsSection(),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Se Déconnecter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminPaymentsSection extends StatefulWidget {
  @override
  State<_AdminPaymentsSection> createState() => _AdminPaymentsSectionState();
}

class _AdminPaymentsSectionState extends State<_AdminPaymentsSection> {
  bool _loading = true;
  List<Map<String, dynamic>> _methods = [];
  String? _defaultId;
  String? _error;
  final _stripeAccountIdCtrl = TextEditingController();
  final _stripePubKeyCtrl = TextEditingController();
  final _paypalMerchantIdCtrl = TextEditingController();
  final _paypalEmailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _methods = [];
          _defaultId = null;
          _loading = false;
        });
        return;
      }
      final list = await AdminPaymentService.getMethods();
      final def = await AdminPaymentService.getDefaultMethodId();
      final pub = await AdminPaymentService.getPublicInfo();
      if (!mounted) return;
      setState(() {
        _methods = list;
        _defaultId = def;
        _loading = false;
        _error = null;
        _stripeAccountIdCtrl.text = pub['stripeAccountId'] ?? '';
        _stripePubKeyCtrl.text = pub['stripePublishableKey'] ?? '';
        _paypalMerchantIdCtrl.text = pub['paypalMerchantId'] ?? '';
        _paypalEmailCtrl.text = pub['paypalEmail'] ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load payment methods';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthodes de Paiement (Admin)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (FirebaseAuth.instance.currentUser == null)
          CustomCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Veuillez vous connecter pour gérer les paiements.',
                  ),
                ),
              ],
            ),
          )
        else if (_error != null)
          CustomCard(
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.errorColor),
                const SizedBox(width: 12),
                Expanded(child: Text(_error!)),
                TextButton(onPressed: _load, child: const Text('Réessayer')),
              ],
            ),
          )
        else if (_methods.isEmpty)
          CustomCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Aucune méthode de paiement. Liez Stripe ou PayPal.',
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _methods.length,
            itemBuilder: (context, index) {
              final m = _methods[index];
              final isStripe = m['provider'] == 'stripe';
              return CustomCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          (isStripe
                                  ? AppTheme.primaryColor
                                  : AppTheme.accentColor)
                              .withOpacity(0.12),
                      child: Icon(
                        isStripe
                            ? Icons.credit_card
                            : Icons.account_balance_wallet,
                        color: isStripe
                            ? AppTheme.primaryColor
                            : AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isStripe ? 'Stripe' : 'PayPal',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (m['last4'] != null)
                            Text(
                              '${m['brand'] ?? ''} •••• ${m['last4']}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    if (_defaultId == m['id'])
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 18,
                        ),
                      ),
                    IconButton(
                      onPressed: () async {
                        await AdminPaymentService.unlink(m['id']);
                        _load();
                      },
                      icon: const Icon(
                        Icons.delete,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await AdminPaymentService.setDefaultMethod(m['id']);
                        _load();
                      },
                      icon: const Icon(
                        Icons.star,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        Text(
          'Informations Publiques (Réception des paiements)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        CustomCard(
          child: Column(
            children: [
              TextField(
                controller: _stripeAccountIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Stripe Account ID (acct_...)',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _stripePubKeyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Stripe Publishable Key (pk_test_...)',
                  prefixIcon: Icon(Icons.vpn_key),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _paypalMerchantIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'PayPal Merchant ID',
                  prefixIcon: Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _paypalEmailCtrl,
                decoration: const InputDecoration(
                  labelText: 'PayPal Email',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await AdminPaymentService.savePublicInfo(
                      stripeAccountId: _stripeAccountIdCtrl.text.trim().isEmpty
                          ? null
                          : _stripeAccountIdCtrl.text.trim(),
                      stripePublishableKey:
                          _stripePubKeyCtrl.text.trim().isEmpty
                          ? null
                          : _stripePubKeyCtrl.text.trim(),
                      paypalMerchantId:
                          _paypalMerchantIdCtrl.text.trim().isEmpty
                          ? null
                          : _paypalMerchantIdCtrl.text.trim(),
                      paypalEmail: _paypalEmailCtrl.text.trim().isEmpty
                          ? null
                          : _paypalEmailCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Informations enregistrées'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await AdminPaymentService.linkStripeTest();
                  _load();
                },
                icon: const Icon(Icons.credit_card),
                label: const Text('Lier Stripe (test)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await AdminPaymentService.linkPayPalSandbox();
                  _load();
                },
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Lier PayPal (sandbox)'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
