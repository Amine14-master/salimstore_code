import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../firebase_options.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  bool _loading = true;
  bool _isFetching = false;
  bool _pendingRefresh = false;
  Map<String, dynamic> _stats = {};
  Map<String, int> _wilayaStats = {};
  Map<String, int> _categoryStats = {};
  List<Map<String, dynamic>> _topProducts = [];
  late final FirebaseDatabase _database;
  late final DatabaseReference _ordersRef;
  late final DatabaseReference _productsRef;
  late final DatabaseReference _categoriesRef;
  final List<StreamSubscription<DatabaseEvent>> _dbSubscriptions = [];
  Timer? _refreshDebounce;
  String _section = 'overview';

  @override
  void initState() {
    super.initState();
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
    );
    _ordersRef = _database.ref('orders');
    _productsRef = _database.ref('products');
    _categoriesRef = _database.ref('categories');
    _loadAnalytics();
    _setupRealtimeListener();
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360, maxHeight: 260),
              child: Lottie.asset(
                'lib/assets/animations/category_loader.json',
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analyse des performances...',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nous préparons vos indicateurs clés en temps réel.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: List.generate(4, (index) {
                return Shimmer.fromColors(
                  baseColor: AppTheme.surfaceColor.withOpacity(0.35),
                  highlightColor: AppTheme.surfaceColor.withOpacity(0.15),
                  child: Container(
                    width: 150,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                      ),
                      gradient: const LinearGradient(
                        colors: [Color(0x11FFFFFF), Color(0x22FFFFFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: AppTheme.primaryColor.withOpacity(0.22),
                          ),
                        ),
                        Container(
                          height: 10,
                          width: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: AppTheme.primaryColor.withOpacity(0.18),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final sub in _dbSubscriptions) {
      sub.cancel();
    }
    _refreshDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAnalytics({bool showLoader = true}) async {
    if (_isFetching) {
      _pendingRefresh = true;
      return;
    }

    _isFetching = true;

    if (showLoader && mounted) {
      setState(() => _loading = true);
    }

    try {
      final ordersFuture = _ordersRef.get();
      final productsFuture = _productsRef.get();
      final categoriesFuture = _categoriesRef.get();
      final usersFuture =
          FirebaseFirestore.instance.collection('clients').get();

      final ordersSnapshot = await ordersFuture;
      final productsSnapshot = await productsFuture;
      final categoriesSnapshot = await categoriesFuture;
      final usersSnapshot = await usersFuture;

      final ordersData = _castDataMap(ordersSnapshot.value);
      final productsData = _castDataMap(productsSnapshot.value);
      final categoriesData = _castDataMap(categoriesSnapshot.value);

      final analytics = _computeAnalyticsData(
        ordersData: ordersData,
        productsData: productsData,
        categoriesData: categoriesData,
        totalUsers: usersSnapshot.docs.length,
      );

      if (!mounted) return;

      setState(() {
        _stats = analytics.overview;
        _wilayaStats = analytics.wilayaStats;
        _categoryStats = analytics.categoryStats;
        _topProducts = analytics.topProducts;
        _loading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    } finally {
      _isFetching = false;
      if (_pendingRefresh) {
        _pendingRefresh = false;
        Future.microtask(() => _loadAnalytics(showLoader: false));
      }
    }
  }

  void _setupRealtimeListener() {
    void listenTo(DatabaseReference ref) {
      _dbSubscriptions.add(
        ref.onValue.listen((_) {
          if (!mounted) return;
          _scheduleSilentRefresh();
        }),
      );
    }

    listenTo(_ordersRef);
    listenTo(_productsRef);
    listenTo(_categoriesRef);
  }

  void _scheduleSilentRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 450), () {
      _refreshAnalyticsSilently();
    });
  }

  Future<void> _refreshAnalyticsSilently() {
    return _loadAnalytics(showLoader: false);
  }

  ({
    Map<String, dynamic> overview,
    Map<String, int> wilayaStats,
    Map<String, int> categoryStats,
    List<Map<String, dynamic>> topProducts,
  })
  _computeAnalyticsData({
    required Map<String, Map<String, dynamic>> ordersData,
    required Map<String, Map<String, dynamic>> productsData,
    required Map<String, Map<String, dynamic>> categoriesData,
    required int totalUsers,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    int pendingOrders = 0;
    int processingOrders = 0;
    int deliveredOrders = 0;
    double totalRevenue = 0;
    double todayRevenue = 0;
    double thisMonthRevenue = 0;

    final wilayaCounts = <String, int>{};
    final Map<String, Map<String, double>> productSales = {};

    ordersData.forEach((key, order) {
      final status = (order['status'] ?? 'pending').toString().toLowerCase();

      if (status == 'pending' || status == 'en attente') {
        pendingOrders++;
      } else if (status == 'processing' ||
          status == 'en cours' ||
          status == 'en cours de livraison') {
        processingOrders++;
      } else if (status == 'delivered' ||
          status == 'livré' ||
          status == 'delivre') {
        deliveredOrders++;
      }

      final orderTotal = _toDouble(order['total']);
      totalRevenue += orderTotal;

      final orderDate = _parseDate(order['createdAt']);
      if (orderDate != null) {
        if (orderDate.isAfter(todayStart)) {
          todayRevenue += orderTotal;
        }
        if (orderDate.isAfter(monthStart)) {
          thisMonthRevenue += orderTotal;
        }
      }

      final wilayaRaw = order['wilaya'] ?? order['wilayaCode'];
      final wilaya = (wilayaRaw is String && wilayaRaw.trim().isNotEmpty)
          ? wilayaRaw.trim()
          : 'Non spécifiée';
      wilayaCounts[wilaya] = (wilayaCounts[wilaya] ?? 0) + 1;

      for (final item in _extractOrderItems(order['items'])) {
        final productName = (item['productName'] ?? item['name'] ?? 'Sans nom')
            .toString();
        final quantity = _toDouble(item['quantity'], fallback: 1);
        double itemRevenue = _toDouble(item['totalPrice']);
        if (itemRevenue == 0) {
          final unitPrice = _toDouble(item['price']);
          itemRevenue = unitPrice * (quantity == 0 ? 1 : quantity);
        }

        final sale = productSales.putIfAbsent(
          productName,
          () => {'quantity': 0.0, 'revenue': 0.0},
        );
        sale['quantity'] = (sale['quantity'] ?? 0) + quantity;
        sale['revenue'] = (sale['revenue'] ?? 0) + itemRevenue;
      }
    });

    final categoryCounts = <String, int>{};
    for (final category in categoriesData.values) {
      final name = (category['name'] ?? 'Catégorie').toString().trim();
      if (name.isNotEmpty) {
        categoryCounts.putIfAbsent(name, () => 0);
      }
    }

    for (final product in productsData.values) {
      final categoryName =
          _resolveCategoryName(product, categoriesData) ?? 'Autres';
      categoryCounts[categoryName] = (categoryCounts[categoryName] ?? 0) + 1;
    }

    final topProducts =
        productSales.entries
            .map(
              (entry) => {
                'name': entry.key,
                'quantity': entry.value['quantity'] ?? 0.0,
                'revenue': entry.value['revenue'] ?? 0.0,
              },
            )
            .toList()
          ..sort(
            (a, b) =>
                (b['quantity'] as double).compareTo(a['quantity'] as double),
          );

    final overview = <String, dynamic>{
      'totalUsers': totalUsers,
      'totalProducts': productsData.length,
      'totalCategories': categoriesData.length,
      'totalOrders': ordersData.length,
      'pendingOrders': pendingOrders,
      'processingOrders': processingOrders,
      'deliveredOrders': deliveredOrders,
      'totalRevenue': totalRevenue,
      'todayRevenue': todayRevenue,
      'thisMonthRevenue': thisMonthRevenue,
    };

    return (
      overview: overview,
      wilayaStats: wilayaCounts,
      categoryStats: categoryCounts,
      topProducts: topProducts.take(10).toList(),
    );
  }

  Map<String, Map<String, dynamic>> _castDataMap(dynamic raw) {
    final result = <String, Map<String, dynamic>>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map) {
          result[key.toString()] = Map<String, dynamic>.from(value);
        }
      });
    } else if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        final value = raw[i];
        if (value is Map) {
          result[i.toString()] = Map<String, dynamic>.from(value);
        }
      }
    }
    return result;
  }

  Iterable<Map<String, dynamic>> _extractOrderItems(dynamic rawItems) sync* {
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          yield Map<String, dynamic>.from(item);
        }
      }
    } else if (rawItems is Map) {
      for (final entry in rawItems.entries) {
        final value = entry.value;
        if (value is Map) {
          yield Map<String, dynamic>.from(value);
        }
      }
    }
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value
          .replaceAll(RegExp(r'[^0-9.,-]'), '')
          .replaceAll(',', '.');
      return double.tryParse(normalized) ?? fallback;
    }
    return fallback;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String? _resolveCategoryName(
    Map<String, dynamic> product,
    Map<String, Map<String, dynamic>> categories,
  ) {
    final direct = product['category'] ?? product['categoryName'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }

    final categoryId = product['categoryId']?.toString();
    if (categoryId != null && categories.containsKey(categoryId)) {
      final name = categories[categoryId]?['name']?.toString();
      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: _loading
            ? _buildLoadingState(context)
            : RefreshIndicator(
                onRefresh: () => _loadAnalytics(showLoader: false),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Analyses',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadAnalytics,
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSectionButtons(),
                      const SizedBox(height: 16),
                      ..._buildSectionContent(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionButtons() {
    final items = [
      {'key': 'overview', 'label': 'Aperçu', 'icon': Icons.dashboard},
      {'key': 'wilayas', 'label': 'Wilayas', 'icon': Icons.location_city},
      {'key': 'products', 'label': 'Produits', 'icon': Icons.inventory_2},
      {'key': 'categories', 'label': 'Catégories', 'icon': Icons.category},
      {'key': 'users', 'label': 'Utilisateurs', 'icon': Icons.people},
      {'key': 'top', 'label': 'Top Produits', 'icon': Icons.star},
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((e) {
        final selected = _section == e['key'];
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(e['icon'] as IconData, size: 16),
              const SizedBox(width: 6),
              Text(e['label'] as String),
            ],
          ),
          selected: selected,
          onSelected: (_) => setState(() => _section = e['key'] as String),
        );
      }).toList(),
    );
  }

  List<Widget> _buildSectionContent() {
    switch (_section) {
      case 'wilayas':
        return [_buildWilayaSection()];
      case 'products':
        return [
          _buildOverviewCardsFiltered(['Total Produits']),
          const SizedBox(height: 16),
          if (_topProducts.isNotEmpty) _buildTopProductsSection(),
        ];
      case 'categories':
        return [
          _buildOverviewCardsFiltered(['Total Catégories']),
          const SizedBox(height: 16),
          if (_categoryStats.isNotEmpty) _buildCategorySection(),
        ];
      case 'users':
        return [
          _buildOverviewCardsFiltered(['Total Utilisateurs']),
        ];
      case 'top':
        return [if (_topProducts.isNotEmpty) _buildTopProductsSection()];
      case 'overview':
      default:
        return [
          _buildOverviewCards(),
          const SizedBox(height: 24),
          _buildRevenueSection(),
          const SizedBox(height: 24),
          _buildOrdersStatusSection(),
          const SizedBox(height: 24),
          if (_wilayaStats.isNotEmpty) _buildWilayaSection(),
          if (_wilayaStats.isNotEmpty) const SizedBox(height: 24),
          if (_categoryStats.isNotEmpty) _buildCategorySection(),
          if (_categoryStats.isNotEmpty) const SizedBox(height: 24),
          if (_topProducts.isNotEmpty) _buildTopProductsSection(),
        ];
    }
  }

  Widget _buildOverviewCardsFiltered(List<String> titles) {
    final cards = [
      {
        'title': 'Total Utilisateurs',
        'value': (_stats['totalUsers'] ?? 0).toString(),
        'icon': Icons.people,
        'color': AppTheme.primaryColor,
      },
      {
        'title': 'Total Produits',
        'value': (_stats['totalProducts'] ?? 0).toString(),
        'icon': Icons.inventory_2,
        'color': AppTheme.successColor,
      },
      {
        'title': 'Total Catégories',
        'value': (_stats['totalCategories'] ?? 0).toString(),
        'icon': Icons.category,
        'color': AppTheme.accentColor,
      },
      {
        'title': 'Total Commandes',
        'value': (_stats['totalOrders'] ?? 0).toString(),
        'icon': Icons.shopping_cart,
        'color': AppTheme.warningColor,
      },
    ].where((c) => titles.contains(c['title'] as String)).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return CustomCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (card['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  card['icon'] as IconData,
                  color: card['color'] as Color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                card['value'] as String,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card['title'] as String,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewCards() {
    final cards = [
      {
        'title': 'Total Utilisateurs',
        'value': (_stats['totalUsers'] ?? 0).toString(),
        'icon': Icons.people,
        'color': AppTheme.primaryColor,
      },
      {
        'title': 'Total Produits',
        'value': (_stats['totalProducts'] ?? 0).toString(),
        'icon': Icons.inventory_2,
        'color': AppTheme.successColor,
      },
      {
        'title': 'Total Catégories',
        'value': (_stats['totalCategories'] ?? 0).toString(),
        'icon': Icons.category,
        'color': AppTheme.accentColor,
      },
      {
        'title': 'Total Commandes',
        'value': (_stats['totalOrders'] ?? 0).toString(),
        'icon': Icons.shopping_cart,
        'color': AppTheme.warningColor,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return CustomCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (card['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  card['icon'] as IconData,
                  color: card['color'] as Color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                card['value'] as String,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card['title'] as String,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevenueSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Revenus',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatRow(
            'Total des revenus',
            '${(_stats['totalRevenue'] ?? 0.0).toStringAsFixed(0)} €',
          ),
          const Divider(),
          _buildStatRow(
            'Aujourd\'hui',
            '${(_stats['todayRevenue'] ?? 0.0).toStringAsFixed(0)} €',
          ),
          const Divider(),
          _buildStatRow(
            'Ce mois',
            '${(_stats['thisMonthRevenue'] ?? 0.0).toStringAsFixed(0)} €',
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersStatusSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: AppTheme.warningColor),
              const SizedBox(width: 8),
              Text(
                'Statut des Commandes',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatRow(
            'En attente',
            '${(_stats['pendingOrders'] ?? 0)}',
            color: AppTheme.warningColor,
          ),
          const Divider(),
          _buildStatRow(
            'En cours',
            '${(_stats['processingOrders'] ?? 0)}',
            color: AppTheme.accentColor,
          ),
          const Divider(),
          _buildStatRow(
            'Livrées',
            '${(_stats['deliveredOrders'] ?? 0)}',
            color: AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildWilayaSection() {
    final topWilayas = _wilayaStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_city, color: AppTheme.accentColor),
              const SizedBox(width: 8),
              Text(
                'Commandes par Wilaya',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topWilayas.take(10).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final topCategories = _categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: AppTheme.successColor),
              const SizedBox(width: 8),
              Text(
                'Produits par Catégorie',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topCategories.take(10).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: AppTheme.warningColor),
              const SizedBox(width: 8),
              Text(
                'Top 10 Produits',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._topProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Quantité: ${(product['quantity'] ?? 0.0).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(product['revenue'] ?? 0.0).toStringAsFixed(0)} €',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
