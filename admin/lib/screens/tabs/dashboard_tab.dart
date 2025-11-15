import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../services/realtime_database_service.dart';
import '../../firebase_options.dart';

class DashboardTab extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const DashboardTab({super.key, this.onNavigateToTab});

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
  List<Map<String, dynamic>> _recentOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      await RealtimeDatabaseService.updateStats();
      final stats = await RealtimeDatabaseService.getStats();

      // Load recent orders
      final orders = await _getRecentOrders();

      setState(() {
        _stats = stats;
        _recentOrders = orders;
        _loading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentOrders() async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
      );
      final snapshot = await db
          .ref('orders')
          .orderByChild('createdAt')
          .limitToLast(25)
          .get();

      if (snapshot.exists) {
        final now = DateTime.now();
        final threshold = now
            .subtract(const Duration(hours: 24))
            .millisecondsSinceEpoch;
        final rawValue = snapshot.value;
        final entries = <MapEntry<String, Map<String, dynamic>>>[];

        if (rawValue is Map) {
          entries.addAll(
            rawValue.entries
                .where((entry) => entry.value is Map)
                .map(
                  (entry) => MapEntry(
                    entry.key.toString(),
                    Map<String, dynamic>.from(entry.value),
                  ),
                ),
          );
        } else if (rawValue is List) {
          for (var i = 0; i < rawValue.length; i++) {
            final value = rawValue[i];
            if (value is Map) {
              entries.add(
                MapEntry(i.toString(), Map<String, dynamic>.from(value)),
              );
            }
          }
        }

        int? _createdAtToMillis(dynamic value) {
          if (value == null) return null;
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is String) {
            final trimmed = value.trim();
            if (trimmed.isEmpty) return null;
            final numeric = int.tryParse(trimmed);
            if (numeric != null) return numeric;
            final parsed = DateTime.tryParse(trimmed);
            if (parsed != null) return parsed.millisecondsSinceEpoch;

            final dateMatch = RegExp(
              r'^(\d{1,2})/(\d{1,2})/(\d{2,4})(?:\s|\u00b7)?(\d{1,2}:\d{2})?',
            ).firstMatch(trimmed);
            if (dateMatch != null) {
              final day = int.tryParse(dateMatch.group(1)!);
              final month = int.tryParse(dateMatch.group(2)!);
              final rawYear = dateMatch.group(3)!;
              int? year = int.tryParse(
                rawYear.length == 2 ? '20$rawYear' : rawYear,
              );
              if (day != null && month != null && year != null) {
                int hour = 0;
                int minute = 0;
                final time = dateMatch.group(4);
                if (time != null) {
                  final timeParts = time.split(':');
                  if (timeParts.length == 2) {
                    hour = int.tryParse(timeParts[0]) ?? 0;
                    minute = int.tryParse(timeParts[1]) ?? 0;
                  }
                }
                return DateTime(
                  year,
                  month,
                  day,
                  hour,
                  minute,
                ).millisecondsSinceEpoch;
              }
            }
          }
          return null;
        }

        final orders =
            entries.map((entry) {
              final createdMillis = _createdAtToMillis(
                entry.value['createdAt'],
              );
              return {
                'id': entry.key,
                'createdAtMillis': createdMillis ?? 0,
                ...entry.value,
              };
            }).toList()..sort(
              (a, b) => (b['createdAtMillis'] as int).compareTo(
                a['createdAtMillis'] as int,
              ),
            );

        final filtered = orders
            .where((order) => (order['createdAtMillis'] as int) >= threshold)
            .toList();

        final selection = filtered.isNotEmpty ? filtered : orders;

        return selection.take(5).map((order) {
          final status = (order['status'] ?? 'pending').toString();
          final createdAtMillis = order['createdAtMillis'] as int;
          final id = (order['id'] ?? '').toString();
          final shortId = id.isEmpty
              ? '—'
              : '#${(id.length > 6 ? id.substring(0, 6) : id).toUpperCase()}';

          return {
            'id': id,
            'code': shortId,
            'status': status,
            'statusLabel': _getStatusLabel(status),
            'total': _extractOrderTotal(order),
            'itemsCount': _extractItemsCount(order),
            'customerName': _extractCustomerName(order),
            'phone': _extractPhone(order),
            'address': _extractAddressSummary(order),
            'createdAtMillis': createdAtMillis,
            'createdAtText': _formatOrderDate(createdAtMillis),
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error loading recent orders: $e');
      return [];
    }
  }

  double _extractOrderTotal(Map<String, dynamic> order) {
    final candidates = [
      order['total'],
      order['grandTotal'],
      order['totalAmount'],
      order['totalPrice'],
      order['amount'],
    ];

    for (final candidate in candidates) {
      final parsed = _asDouble(candidate);
      if (parsed > 0) return parsed;
    }
    return 0.0;
  }

  int _extractItemsCount(Map<String, dynamic> order) {
    final keys = ['items', 'products', 'orderItems', 'cart'];
    for (final key in keys) {
      final value = order[key];
      final count = _countCollection(value);
      if (count != null && count > 0) {
        return count;
      }
    }
    return 0;
  }

  int? _countCollection(dynamic value) {
    if (value is List) {
      return value.where((element) => element != null).length;
    }
    if (value is Map) {
      return value.length;
    }
    return null;
  }

  String _extractCustomerName(Map<String, dynamic> order) {
    final keys = [
      'customerName',
      'clientName',
      'name',
      'fullName',
      'userName',
      'customer',
    ];

    for (final key in keys) {
      final value = order[key];
      final resolved = _resolveStringCandidate(value);
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }

    final customer = order['customer'];
    if (customer is Map<String, dynamic>) {
      final nested =
          _resolveStringCandidate(customer['name']) ??
          _resolveStringCandidate(customer['fullName']) ??
          _resolveStringCandidate(customer['displayName']);
      if (nested != null && nested.isNotEmpty) return nested;
    }

    return 'Client';
  }

  String _extractPhone(Map<String, dynamic> order) {
    final keys = [
      'phone',
      'customerPhone',
      'clientPhone',
      'phoneNumber',
      'mobile',
      'contact',
    ];

    for (final key in keys) {
      final value = order[key];
      final resolved = _resolveStringCandidate(value);
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }

    final customer = order['customer'];
    if (customer is Map<String, dynamic>) {
      final nested =
          _resolveStringCandidate(customer['phone']) ??
          _resolveStringCandidate(customer['phoneNumber']);
      if (nested != null && nested.isNotEmpty) return nested;
    }

    return '';
  }

  String _extractAddressSummary(Map<String, dynamic> order) {
    final keys = [
      'deliveryAddress',
      'address',
      'shippingAddress',
      'addressLine',
    ];

    for (final key in keys) {
      final value = order[key];
      final resolved = _resolveStringCandidate(value);
      if (resolved != null && resolved.isNotEmpty) return resolved;

      if (value is Map<String, dynamic>) {
        final nested =
            _resolveStringCandidate(value['fullAddress']) ??
            _resolveStringCandidate(value['address']);
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }

    final wilaya = _resolveStringCandidate(order['wilaya']) ?? '';
    final commune = _resolveStringCandidate(order['commune']) ?? '';
    if (wilaya.isNotEmpty || commune.isNotEmpty) {
      if (wilaya.isNotEmpty && commune.isNotEmpty) {
        return '$wilaya · $commune';
      }
      return wilaya.isNotEmpty ? wilaya : commune;
    }

    return '';
  }

  String? _resolveStringCandidate(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.trim().isEmpty) return 0.0;
      final sanitized = value.trim().replaceAll(',', '.');
      return double.tryParse(sanitized) ?? 0.0;
    }
    return 0.0;
  }

  String _formatOrderDate(int? millis) {
    if (millis == null || millis <= 0) return '—';
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  String _formatCurrency(num amount) {
    return AppTheme.formatCurrency(amount);
  }

  String _getStatusLabel(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'pending' || normalized == 'en attente') {
      return 'En attente';
    }
    if (normalized == 'processing' ||
        normalized == 'en cours' ||
        normalized == 'en cours de livraison' ||
        normalized == 'livraison') {
      return 'En livraison';
    }
    if (normalized == 'delivered' ||
        normalized == 'livré' ||
        normalized == 'delivre' ||
        normalized == 'delivré' ||
        normalized == 'termines' ||
        normalized == 'terminé' ||
        normalized == 'termine') {
      return 'Terminée';
    }
    return status;
  }

  Color _getStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'pending' || normalized == 'en attente') {
      return Colors.orange;
    }
    if (normalized == 'processing' ||
        normalized == 'en cours' ||
        normalized == 'en cours de livraison' ||
        normalized == 'livraison') {
      return AppTheme.accentColor;
    }
    if (normalized == 'delivered' ||
        normalized == 'livré' ||
        normalized == 'delivre' ||
        normalized == 'delivré' ||
        normalized == 'termines' ||
        normalized == 'terminé' ||
        normalized == 'termine') {
      return AppTheme.successColor;
    }
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth >= 1280
        ? AppSpacing.xl
        : screenWidth >= 960
        ? AppSpacing.lg
        : AppSpacing.md;

    return Container(
      color: AppTheme.backgroundColor,
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: AppDurations.medium,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: AppSpacing.xl,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 1280 + horizontalPadding * 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: AppSpacing.xl),
                          _buildStatsCards(context),
                          const SizedBox(height: AppSpacing.xl),
                          _buildRecentOrders(context),
                          const SizedBox(height: AppSpacing.xl),
                          _buildQuickActions(context),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue, Admin',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Vue d’ensemble',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Actualiser'),
        ),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => widget.onNavigateToTab?.call(4),
          icon: const Icon(Icons.receipt_long_outlined, size: 18),
          label: const Text('Voir commandes'),
        ),
      ],
    ).animate().fade(delay: 200.ms).slideX(begin: -0.08);
  }

  Widget _buildStatsCards(BuildContext context) {
    final theme = Theme.of(context);
    final cards = [
      {
        'title': 'Commandes',
        'value': _stats['totalOrders'].toString(),
        'icon': Icons.shopping_cart_outlined,
        'color': AppTheme.primaryColor,
      },
      {
        'title': 'Revenus',
        'value': _formatCurrency(_stats['totalRevenue'] as double),
        'icon': Icons.attach_money_rounded,
        'color': AppTheme.successColor,
      },
      {
        'title': 'Produits',
        'value': _stats['totalProducts'].toString(),
        'icon': Icons.inventory_2_outlined,
        'color': AppTheme.warningColor,
      },
      {
        'title': 'Clients',
        'value': _stats['totalUsers'].toString(),
        'icon': Icons.people_alt_outlined,
        'color': AppTheme.accentColor,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 1024
            ? 4
            : maxWidth >= 768
            ? 2
            : 1;
        final itemWidth = (maxWidth - (columns - 1) * AppSpacing.lg) / columns;

        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: cards.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;
            return SizedBox(
              width: columns == 1 ? maxWidth : itemWidth,
              child:
                  CustomCard(
                        margin: EdgeInsets.zero,
                        shadows: AppShadows.subtle,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: (stat['color'] as Color).withOpacity(
                                  0.14,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.sm,
                                ),
                              ),
                              child: Icon(
                                stat['icon'] as IconData,
                                color: stat['color'] as Color,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stat['title'] as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    stat['value'] as String,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fade(delay: (200 + index * 80).ms)
                      .slideY(begin: 0.12),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentOrders(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Commandes récentes',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                widget.onNavigateToTab?.call(4); // Navigate to Orders tab
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_recentOrders.isEmpty)
          CustomCard(
            margin: EdgeInsets.zero,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: AppTheme.textLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune commande récente',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          CustomCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Commande',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Client',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Articles',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Total',
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Date',
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Statut',
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...List.generate(_recentOrders.length, (index) {
                  final order = _recentOrders[index];
                  final status = (order['status'] ?? 'pending').toString();
                  final statusLabel =
                      order['statusLabel']?.toString() ??
                      _getStatusLabel(status);
                  final statusColor = _getStatusColor(status);
                  final totalValue = order['total'] is num
                      ? (order['total'] as num).toDouble()
                      : 0.0;
                  final itemsCount = order['itemsCount'] is int
                      ? order['itemsCount'] as int
                      : 0;
                  final phone = (order['phone'] ?? '').toString();
                  final address = (order['address'] ?? '').toString();
                  final code = (order['code'] ?? order['id'] ?? '—').toString();
                  final theme = Theme.of(context);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Tooltip(
                                message: (order['id'] ?? '').toString(),
                                child: Text(
                                  code,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (order['customerName'] ?? 'Client')
                                        .toString(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (phone.isNotEmpty)
                                    Text(
                                      phone,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (address.isNotEmpty)
                                    Text(
                                      address,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                itemsCount > 0 ? '$itemsCount art.' : '—',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _formatCurrency(totalValue),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  (order['createdAtText'] ?? '—').toString(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index != _recentOrders.length - 1)
                        const Divider(height: 1),
                    ],
                  ).animate().fade().slideX(begin: -0.05);
                }),
              ],
            ),
          ),
      ],
    ).animate().slideY(delay: 600.ms, begin: 0.3, end: 0);
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'title': 'Gérer produits',
        'subtitle': 'Ajoutez et gérez votre catalogue',
        'icon': Icons.inventory_2,
        'color': const Color(0xFF3B82F6),
        'tab': 1,
      },
      {
        'title': 'Gérer catégories',
        'subtitle': 'Organisez les rayons de votre boutique',
        'icon': Icons.category_rounded,
        'color': const Color(0xFF10B981),
        'tab': 2,
      },
      {
        'title': 'Gérer promotions',
        'subtitle': 'Créez des offres attractives',
        'icon': Icons.local_offer_rounded,
        'color': const Color(0xFFF97316),
        'tab': 3,
      },
      {
        'title': 'Voir commandes',
        'subtitle': 'Suivez les commandes en temps réel',
        'icon': Icons.receipt_long,
        'color': const Color(0xFF6366F1),
        'tab': 4,
      },
      {
        'title': 'Gérer utilisateurs',
        'subtitle': 'Administrez vos clients et livreurs',
        'icon': Icons.people_alt_rounded,
        'color': const Color(0xFFA855F7),
        'tab': 5,
      },
      {
        'title': 'Analyses & rapports',
        'subtitle': 'Visualisez les performances',
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFF14B8A6),
        'tab': 6,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isWide = maxWidth >= 960;
        final isTablet = maxWidth >= 640;
        final columns = isWide
            ? 3
            : isTablet
            ? 2
            : 1;
        final double itemWidth;
        if (columns == 1) {
          itemWidth = maxWidth;
        } else {
          final totalGap = (columns - 1) * AppSpacing.lg;
          itemWidth = (maxWidth - totalGap) / columns;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Actions rapides',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Actualiser les données'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: actions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;
                return SizedBox(
                  width: itemWidth,
                  child:
                      CustomCard(
                            margin: EdgeInsets.zero,
                            shadows: AppShadows.subtle,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              onTap: () {
                                final callback = widget.onNavigateToTab;
                                if (callback != null) {
                                  callback(action['tab'] as int);
                                } else {
                                  _navigateToTab(context, action['tab'] as int);
                                }
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (action['color'] as Color)
                                          .withOpacity(0.16),
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.sm,
                                      ),
                                    ),
                                    child: Icon(
                                      action['icon'] as IconData,
                                      color: action['color'] as Color,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          action['title'] as String,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          action['subtitle'] as String,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fade(delay: (600 + index * 60).ms)
                          .slideY(begin: 0.1),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    // Fallback navigation method
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation vers l\'onglet ${tabIndex + 1}'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    }
  }
}
