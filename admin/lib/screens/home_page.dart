import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../firebase_options.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../widgets/navigation_footer.dart';
import '../widgets/navigation_sidebar.dart';
// unused imports removed after embedding ProductManagementScreen
// unused imports removed after embedding ProductManagementScreen
// Removed categories management screen
import 'product_management_screen.dart';
import 'category_management_screen.dart';
import 'promotion_management_screen.dart';
import 'tabs/dashboard_tab.dart' as sep;
import 'tabs/products_tab.dart' as sep;
import 'tabs/analytics_tab.dart' as sep;
import 'tabs/profile_tab.dart' as sep;
import 'announcements_management_screen.dart';
import 'tabs/users_tab.dart' as sep;
import 'tabs/orders_tab.dart' as sep;
import '../widgets/delivery_prices_dialog.dart';
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
                  'Vue d’ensemble des activités de Livriyes',
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
          ElevatedButton.icon(
            onPressed: () => DeliveryPricesDialog.show(context),
            icon: const Icon(Icons.local_shipping_rounded, size: 20),
            label: const Text('Prix Livraison'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
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
      const AnnouncementsManagementScreen(),
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
      'Annonces',
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
      return WillPopScope(
        onWillPop: () async {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text('Quitter l\'application'),
                content: const Text(
                  'Voulez-vous vraiment quitter l\'application admin ?',
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
        },
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(
              _pageTitles[_selectedIndex],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () => DeliveryPricesDialog.show(context),
                icon: const Icon(Icons.local_shipping_rounded),
                tooltip: 'Prix Livraison',
              ),
            ],
          ),
          body: _pages[_selectedIndex],
          bottomNavigationBar: NavigationFooter(
            selectedIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            isAdmin: true,
          ),
        ),
      );
    }
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

