import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/cart_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatting.dart';
import '../../utils/pricing_utils.dart';
import '../product_detail_screen.dart';

import '../../services/address_service.dart';
import '../../services/city_service.dart';
import '../../services/wilaya_geo_service.dart';
import '../addresses_management_screen.dart';
import '../receivers_management_screen.dart';
import '../../services/receiver_service.dart';
import '../../services/realtime_database_service.dart';

import '../../widgets/pill_page_header.dart';
import '../paypal_checkout_screen.dart';
import '../../services/server_wakeup_service.dart';

class ParsedDeliveryContext {
  final String rawAddress;
  final String simplifiedAddress;
  final List<String> segments;
  final String? wilayaName;
  final String? communeName;
  final double? latitude;
  final double? longitude;

  const ParsedDeliveryContext({
    required this.rawAddress,
    required this.simplifiedAddress,
    required this.segments,
    this.wilayaName,
    this.communeName,
    this.latitude,
    this.longitude,
  });
}

class DeliveryFeeResult {
  final double fee;
  final bool isAllowed;
  final String? wilayaCode;
  final String? wilayaName;
  final String? communeName;

  const DeliveryFeeResult({
    required this.fee,
    required this.isAllowed,
    this.wilayaCode,
    this.wilayaName,
    this.communeName,
  });
}

class CartTab extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const CartTab({super.key, this.onBackToHome});

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  static const double _expressDeliveryFee = 25.0;
  static const double _bejaiaCityDeliveryFee = 1.5;
  static const double _bejaiaCommuneDeliveryFee = 3.99;
  static const double _otherWilayaDeliveryFee = 8.99;

  static const Set<String> _allowedWilayaCodes = {'06', '15', '18', '19', '34'};
  static const Map<String, String> _wilayaDisplayNames = {
    '06': 'Béjaïa',
    '15': 'Tizi Ouzou',
    '18': 'Jijel',
    '19': 'Sétif',
    '34': 'Bordj Bou Arreridj',
  };

  List<CartItem> _cartItems = [];
  bool _loading = true;

  // Delivery and payment options
  Map<String, dynamic>? _selectedAddress;
  double _deliveryFee = 0.0;
  bool _isBejaia = false;
  bool _expressDelivery = false;
  double _tip = 0.0;
  String _tipMode = 'none'; // 'none', '1', '2', '5', '10', 'custom'
  final TextEditingController _customTipController = TextEditingController();
  bool _showTipOptions = false;
  bool _deliveryAvailable = true;
  String? _resolvedWilayaName;
  String? _resolvedWilayaCode;
  String? _resolvedCommuneName;

  StreamSubscription<List<CartItem>>? _cartSubscription;
  StreamSubscription<Map<String, dynamic>?>? _defaultAddressSubscription;
  final FocusNode _customTipFocusNode = FocusNode();
  String? _receiverName;
  String? _receiverPhone;

  ParsedDeliveryContext _parseAddress(
    Map<String, dynamic> sourceAddress,
    String fullAddress,
    String? wilayaField,
    String? communeField,
  ) {
    final segments = fullAddress
        .split(',')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    final simplifiedAddress = _simplify(fullAddress);

    String? wilayaName = _cleanAddressPart(wilayaField);
    String? communeName = _cleanAddressPart(communeField);

    final latitude = _parseCoordinate(sourceAddress['latitude']);
    final longitude = _parseCoordinate(sourceAddress['longitude']);

    if (latitude != null && longitude != null) {
      final geoMatch = WilayaGeoService.findByCoordinates(latitude, longitude);
      wilayaName ??= geoMatch?.name;
    }

    if (wilayaName == null || wilayaName.isEmpty) {
      if (segments.isNotEmpty) {
        wilayaName = segments.last;
      }
    }

    if ((communeName == null || communeName.isEmpty) && segments.length >= 2) {
      communeName = segments[segments.length - 2];
    }

    if (CityService.isLoaded() && wilayaName != null && wilayaName.isNotEmpty) {
      final normalizedWilaya = _normalizeWilayaName(wilayaName);
      if (normalizedWilaya != null) {
        wilayaName = normalizedWilaya;
      }

      if (communeName != null && communeName.isNotEmpty) {
        final normalizedCommune = _normalizeCommuneName(
          wilayaName,
          communeName,
        );
        if (normalizedCommune != null) {
          communeName = normalizedCommune;
        }
      }
    }

    return ParsedDeliveryContext(
      rawAddress: fullAddress,
      simplifiedAddress: simplifiedAddress,
      segments: segments,
      wilayaName: wilayaName,
      communeName: communeName,
      latitude: latitude,
      longitude: longitude,
    );
  }

  DeliveryFeeResult _resolveDeliveryFee(ParsedDeliveryContext context) {
    final wilayaCode = _resolveWilayaCode(
      context.wilayaName,
      context.simplifiedAddress,
      context,
    );

    if (wilayaCode == null || !_allowedWilayaCodes.contains(wilayaCode)) {
      return DeliveryFeeResult(
        fee: 0.0,
        isAllowed: false,
        wilayaCode: wilayaCode,
        wilayaName: context.wilayaName,
        communeName: context.communeName,
      );
    }

    double fee;
    if (wilayaCode == '06') {
      final isBejaiaCity = _isBejaiaCity(
        context.communeName,
        context.simplifiedAddress,
      );
      fee = isBejaiaCity ? _bejaiaCityDeliveryFee : _bejaiaCommuneDeliveryFee;
    } else {
      fee = _otherWilayaDeliveryFee;
    }

    final displayWilaya = _wilayaDisplayNames[wilayaCode] ?? context.wilayaName;

    return DeliveryFeeResult(
      fee: fee,
      isAllowed: true,
      wilayaCode: wilayaCode,
      wilayaName: displayWilaya ?? context.wilayaName,
      communeName: context.communeName,
    );
  }

  String? _cleanAddressPart(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _simplify(String input) {
    var simplified = input.toLowerCase();
    const replacements = {
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'á': 'a',
      'ã': 'a',
      'å': 'a',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'ö': 'o',
      'ò': 'o',
      'ó': 'o',
      'õ': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ú': 'u',
      'œ': 'oe',
      'ÿ': 'y',
      'ý': 'y',
    };

    replacements.forEach((key, value) {
      simplified = simplified.replaceAll(key, value);
    });

    simplified = simplified.replaceAll(RegExp(r"[^a-z0-9\s,]"), ' ');
    simplified = simplified.replaceAll(RegExp(r'\s+'), ' ').trim();
    return simplified;
  }

  String? _normalizeWilayaName(String wilayaName) {
    final code = _resolveWilayaCode(wilayaName, _simplify(wilayaName), null);
    if (code == null) {
      return wilayaName;
    }
    return _wilayaDisplayNames[code] ?? wilayaName;
  }

  String? _normalizeCommuneName(String? wilayaName, String communeName) {
    if (wilayaName == null || !CityService.isLoaded()) {
      return communeName;
    }

    final wilayaCode = _resolveWilayaCode(
      wilayaName,
      _simplify(wilayaName),
      null,
    );

    final lookupWilaya = wilayaCode != null
        ? (_wilayaDisplayNames[wilayaCode] ?? wilayaName)
        : wilayaName;

    final communes = CityService.getCommunesForWilaya(lookupWilaya);
    if (communes.isEmpty) {
      return communeName;
    }

    final simplifiedTarget = _simplify(communeName);
    for (final candidate in communes) {
      final simplifiedCandidate = _simplify(candidate);
      if (simplifiedCandidate == simplifiedTarget) {
        final normalized = CityService.getCommuneName(lookupWilaya, candidate);
        return normalized ?? candidate;
      }
    }

    return communeName;
  }

  String? _resolveWilayaCode(
    String? wilayaName,
    String simplifiedAddress,
    ParsedDeliveryContext? context,
  ) {
    final latitude = context?.latitude;
    final longitude = context?.longitude;
    if (latitude != null && longitude != null) {
      final geoMatch = WilayaGeoService.findByCoordinates(latitude, longitude);
      if (geoMatch != null) {
        return geoMatch.code;
      }
    }

    if (wilayaName != null && wilayaName.isNotEmpty && CityService.isLoaded()) {
      final code = CityService.getWilayaCode(wilayaName);
      if (code != null) {
        return code.toString().padLeft(2, '0');
      }
    }

    if (simplifiedAddress.isNotEmpty) {
      final segments = simplifiedAddress.split(',');
      for (final segment in segments.reversed) {
        final value = segment.trim();
        if (value.length >= 2 && int.tryParse(value.substring(0, 2)) != null) {
          return value.substring(0, 2);
        }
      }
    }

    return null;
  }

  bool _isBejaiaCity(String? communeName, String simplifiedAddress) {
    final simplifiedCommune = communeName != null ? _simplify(communeName) : '';
    return simplifiedCommune.contains('bejaia') ||
        simplifiedAddress.contains('bejaia');
  }

  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String && value.trim().isNotEmpty) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  Future<void> _ensureCityDataLoaded() async {
    if (CityService.isLoaded()) return;
    try {
      final jsonString = await rootBundle.loadString(
        'lib/data/algeria_cities.json',
      );
      await CityService.loadCities(jsonString);
    } catch (e) {
      debugPrint('Failed to load city data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCart();
    _loadDeliveryAddress();
    _loadReceiverFromPrefs();
    _listenToDefaultAddress();
    // Listen for cart changes
    _cartSubscription = CartService.cartStream().listen((items) {
      if (mounted) {
        setState(() {
          _cartItems = items;
          _refreshExpressSelection();
        });
      }
    });

    // Proactively wake up server when user opens cart
    ServerWakeupService.wakeupServer();
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    _defaultAddressSubscription?.cancel();
    _customTipController.dispose();
    _customTipFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveryAddress() async {
    try {
      await _ensureCityDataLoaded();
      final addresses = await AddressService.getAddresses();
      final defaultAddr = await AddressService.getDefaultAddress();

      setState(() {
        _applySelectedAddress(
          defaultAddr ?? (addresses.isNotEmpty ? addresses.first : null),
        );
      });
    } catch (e) {
      print('Error loading address: $e');
    }
  }

  void _listenToDefaultAddress() {
    _defaultAddressSubscription?.cancel();
    _defaultAddressSubscription = AddressService.defaultAddressStream().listen((
      address,
    ) {
      if (!mounted) return;
      if (address == null) {
        _loadDeliveryAddress();
        return;
      }

      final normalized = Map<String, dynamic>.from(address);
      setState(() {
        _applySelectedAddress(normalized);
      });
    });
  }

  Future<void> _loadReceiverFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _receiverName = prefs.getString('receiver_name');
      _receiverPhone = prefs.getString('receiver_phone');
    });
  }

  Future<void> _saveReceiverToPrefs(String? name, String? phone) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      await prefs.setString('receiver_name', name);
    }
    if (phone != null) {
      await prefs.setString('receiver_phone', phone);
    }
  }

  Future<void> _showReceiverSheet() async {
    final nameCtrl = TextEditingController(text: _receiverName ?? '');
    final phoneCtrl = TextEditingController(text: _receiverPhone ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Destinataire de la commande',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final enteredName = nameCtrl.text.trim();
                          final digitsOnly = phoneCtrl.text.replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          if (digitsOnly.length != 10) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Le numéro doit contenir exactement 10 chiffres.',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _receiverName = enteredName;
                            _receiverPhone = digitsOnly;
                          });
                          await _saveReceiverToPrefs(
                            _receiverName,
                            _receiverPhone,
                          );
                          if (mounted) Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showReceiverPicker() async {
    final saved = await ReceiverService.getReceivers();

    if (saved.isEmpty) {
      await _showReceiverSheet();
      return;
    }

    await showModalBottomSheet<Map<String, String>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.group_rounded, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Choisir un destinataire',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: saved.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = saved[i];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context, {
                            'name': (r['name'] ?? '').toString(),
                            'phone': (r['phone'] ?? '').toString(),
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(
                                    0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (r['name'] ?? '').toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (r['phone'] ?? '').toString(),
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.check_circle_outline,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReceiversManagementScreen(),
                            ),
                          );
                          if (!mounted) return;
                          // After managing, return to the root (home page)
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.group_add_rounded),
                        label: const Text('Gérer'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _showReceiverSheet();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((selected) async {
      if (selected != null) {
        setState(() {
          _receiverName = selected['name'];
          _receiverPhone = selected['phone'];
        });
        await _saveReceiverToPrefs(_receiverName, _receiverPhone);
      }
    });
  }

  void _applySelectedAddress(Map<String, dynamic>? address) {
    _selectedAddress = address;
    if (_selectedAddress != null) {
      _updateDeliveryContext(_selectedAddress!);
    }
  }

  Future<void> _updateDeliveryContext(Map<String, dynamic> address) async {
    await _ensureCityDataLoaded();
    await WilayaGeoService.ensureLoaded();

    final fullAddress = address['fullAddress']?.toString() ?? '';
    final wilayaFromAddress = address['wilaya']?.toString();
    final communeFromAddress = address['commune']?.toString();

    final parsed = _parseAddress(
      address,
      fullAddress,
      wilayaFromAddress,
      communeFromAddress,
    );
    final feeInfo = _resolveDeliveryFee(parsed);

    if (!mounted) return;

    setState(() {
      _resolvedWilayaName = feeInfo.wilayaName;
      _resolvedWilayaCode = feeInfo.wilayaCode;
      _resolvedCommuneName = feeInfo.communeName;
      _deliveryFee = feeInfo.fee;
      _deliveryAvailable = feeInfo.isAllowed;
      if (!_deliveryAvailable && feeInfo.wilayaCode != null) {
        _deliveryAvailable = _allowedWilayaCodes.contains(feeInfo.wilayaCode);
      }
      _isBejaia = feeInfo.wilayaCode == '06';

      if (!_deliveryAvailable) {
        _expressDelivery = false;
      }

      _refreshExpressSelection();
    });
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    final items = await CartService.getCartItems();
    setState(() {
      _cartItems = items;
      _loading = false;
      _refreshExpressSelection();
    });
  }

  Future<void> _updateQuantity(String itemId, double newQuantity) async {
    await CartService.updateQuantity(itemId, newQuantity);
    _loadCart();
  }

  double _getIncrementStep(String unit) {
    if (unit.toLowerCase().contains('kg')) return 0.5;
    if (unit.toLowerCase().contains('g')) return 100.0;
    if (unit.toLowerCase().contains('l')) return 0.5;
    return 1.0;
  }

  String _formatQuantity(double qty, String unit) {
    if (unit.toLowerCase().contains('kg') || unit.toLowerCase().contains('l')) {
      return qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
    }
    return qty.toInt().toString();
  }

  Future<void> _removeItem(String itemId) async {
    final previousItems = List<CartItem>.from(_cartItems);

    setState(() {
      _cartItems = _cartItems.where((item) => item.id != itemId).toList();
      _refreshExpressSelection();
    });

    try {
      await CartService.removeFromCart(itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit retiré du panier'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _cartItems = previousItems);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la suppression: $e"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showOrderConfirmationDialog() async {
    if (_cartItems.isEmpty || _selectedAddress == null || !_deliveryAvailable) {
      return;
    }

    final cartTotal = _getCartTotal();
    final expressFee = _expressDelivery && _isExpressAvailable(cartTotal)
        ? _expressDeliveryFee
        : 0.0;
    final finalTotal = _getFinalTotal();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF7F8FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirmer la commande',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Vérifiez le récapitulatif avant de valider.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Produits',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ..._cartItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.productName} x ${_formatQuantity(item.quantity, item.unit)}',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatPrice(item.totalPrice),
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Adresse de livraison',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatConfirmationAddressLine(),
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Destinataire',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (_receiverName?.isNotEmpty == true ||
                                  _receiverPhone?.isNotEmpty == true)
                              ? '${_receiverName ?? ''}${(_receiverName?.isNotEmpty == true && _receiverPhone?.isNotEmpty == true) ? ' • ' : ''}${_receiverPhone ?? ''}'
                              : 'Non spécifié',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Récapitulatif',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Sous-total',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              _formatPrice(cartTotal),
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Livraison',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              _formatPrice(_deliveryFee),
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (expressFee > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Livraison Express (48h)',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                _formatPrice(expressFee),
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_tip > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Pourboire',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                _formatPrice(_tip),
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Total à payer',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              _formatPrice(finalTotal),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppTheme.textSecondary.withOpacity(0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _createOrder();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Confirmer',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatConfirmationAddressLine() {
    if (_selectedAddress == null) return '';

    final label = (_selectedAddress!['label'] ?? '').toString().trim();

    // Only show the name the user chose for this address.
    if (label.isNotEmpty) return label;

    // Fallback: very short representation if label is missing.
    final fallback = _selectedAddress!['fullAddress']?.toString().trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;

    return '';
  }

  double _getCartTotal() {
    return _cartItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
  }

  bool _isExpressAvailable(double cartTotal) {
    // Express allowed only if delivery is available, not in Béjaïa,
    // and (cart + tip) is strictly above 25€
    final baseTotal = cartTotal + _tip;
    return _deliveryAvailable && !_isBejaia && baseTotal > 25.0;
  }

  void _refreshExpressSelection() {
    final cartTotal = _getCartTotal();
    final canUseExpress = _isExpressAvailable(cartTotal);
    if (!canUseExpress && _expressDelivery) {
      _expressDelivery = false;
    }
  }

  double _getFinalTotal() {
    final cartTotal = _getCartTotal();
    final expressFee = _expressDelivery && _isExpressAvailable(cartTotal)
        ? _expressDeliveryFee
        : 0.0;
    return cartTotal + _deliveryFee + expressFee + _tip;
  }

  void _setTip(String mode) {
    setState(() {
      final isSameSelection = _tipMode == mode && mode != 'none';

      if (isSameSelection) {
        _tipMode = 'none';
        _tip = 0.0;
        _showTipOptions = false;
        _customTipController.clear();
      } else {
        _tipMode = mode;

        if (mode == 'none') {
          _tip = 0.0;
          _customTipController.clear();
          _showTipOptions = false;
        } else if (mode == '1') {
          _tip = 1.0;
          _customTipController.clear();
          _showTipOptions = true;
        } else if (mode == '2') {
          _tip = 2.0;
          _customTipController.clear();
          _showTipOptions = true;
        } else if (mode == '5') {
          _tip = 5.0;
          _customTipController.clear();
          _showTipOptions = true;
        } else if (mode == '10') {
          _tip = 10.0;
          _customTipController.clear();
          _showTipOptions = true;
        } else if (mode == 'custom') {
          // Always show tip options when custom is selected
          _showTipOptions = true;
          if (_customTipController.text.isEmpty) {
            _tip = 0.0;
          }
        }

        _refreshExpressSelection();
      }
    });

    if (mode == 'custom' && _showTipOptions) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        FocusScope.of(context).requestFocus(_customTipFocusNode);
      });
    } else {
      _customTipFocusNode.unfocus();
    }
  }

  void _updateCustomTip(String value) {
    if (value.isEmpty) {
      setState(() {
        _tip = 0.0;
        _refreshExpressSelection();
      });
      return;
    }
    final tipValue = double.tryParse(value) ?? 0.0;
    if (tipValue >= 0) {
      setState(() {
        _tip = tipValue;
        _refreshExpressSelection();
      });
    }
  }

  Future<void> _showAddressSelector() async {
    final addresses = await AddressService.getAddresses();

    if (addresses.isEmpty) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddressesManagementScreen(),
        ),
      );
      if (result == true) {
        await _loadDeliveryAddress();
      }
      return;
    }

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Expanded(child: Text('Choisir une adresse')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: addresses.length + 1,
            itemBuilder: (context, index) {
              if (index == addresses.length) {
                return InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddressesManagementScreen(),
                      ),
                    );
                    if (result == true) {
                      await _loadDeliveryAddress();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Ajouter une nouvelle adresse',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final address = addresses[index];
              final isSelected = _selectedAddress?['id'] == address['id'];
              final isDefault = address['isDefault'] == true;

              return InkWell(
                onTap: () => Navigator.pop(context, address),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppTheme.primaryColor : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    address['label'] ?? 'Adresse',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Par défaut',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address['fullAddress'] ?? '',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selected != null) {
      await AddressService.setDefaultAddress(selected['id']);
      setState(() {
        _selectedAddress = selected;
        _updateDeliveryContext(selected);
      });
    }
  }

  Future<void> _createOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre panier est vide'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une adresse de livraison'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (!_deliveryAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livraison indisponible pour cette adresse'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    try {
      final cartTotal = _getCartTotal();
      final expressFee = _expressDelivery && _isExpressAvailable(cartTotal)
          ? _expressDeliveryFee
          : 0.0;
      final finalTotal = _getFinalTotal();
      final deliveryAddress =
          _selectedAddress!['fullAddress'] ?? 'Non spécifiée';
      final deliveryLabel = _selectedAddress!['label']?.toString();
      final wilaya =
          _resolvedWilayaName ?? _selectedAddress!['wilaya']?.toString() ?? '';
      final wilayaCode = _selectedAddress!['wilayaCode']?.toString() ?? '06';

      // Aggressively wake up server before PayPal checkout
      // This ensures Render server is ready and reduces payment delay
      if (mounted) {
        // Show a brief loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Préparation du paiement...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );

        // Wake up server aggressively
        await ServerWakeupService.aggressiveWakeup();

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
      }

      // Navigate to PayPal checkout screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PayPalCheckoutScreen(
              cartItems: _cartItems,
              cartTotal: cartTotal,
              deliveryFee: _deliveryFee,
              expressFee: expressFee,
              tip: _tip,
              finalTotal: finalTotal,
              deliveryAddress: deliveryAddress,
              deliveryLabel: deliveryLabel,
              wilaya: wilaya,
              wilayaCode: wilayaCode,
              receiverName: _receiverName,
              receiverPhone: _receiverPhone,
              userId: FirebaseAuth.instance.currentUser?.uid,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartTotal = _getCartTotal();
    final finalTotal = _getFinalTotal();
    final canUseExpress = _isExpressAvailable(cartTotal);
    final expressFee = _expressDelivery && canUseExpress
        ? _expressDeliveryFee
        : 0.0;
    final hasTip = _tip > 0;
    final canPlaceOrder =
        _deliveryAvailable && _selectedAddress != null && _cartItems.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            PillPageHeader(title: 'Mon Panier', onBack: widget.onBackToHome),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    child: _loading
                        ? _buildAddressPlaceholder()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAddressSelectorCard(_cartItems.isNotEmpty),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _showReceiverPicker,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.blue,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          (_receiverName?.isNotEmpty == true ||
                                                  _receiverPhone?.isNotEmpty ==
                                                      true)
                                              ? '${_receiverName ?? ''}${(_receiverName?.isNotEmpty == true && _receiverPhone?.isNotEmpty == true) ? ' • ' : ''}${_receiverPhone ?? ''}'
                                              : 'Destinataire (nom, téléphone)',
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontWeight:
                                                (_receiverName?.isNotEmpty ==
                                                        true ||
                                                    _receiverPhone
                                                            ?.isNotEmpty ==
                                                        true)
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadCart();
                        await _loadDeliveryAddress();
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                        children: [
                          if (_cartItems.isEmpty)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 68,
                                    color: AppTheme.textLight,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Votre panier est vide',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Ajoutez des produits pour commencer',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            for (var i = 0; i < _cartItems.length; i++) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.98),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  dense: true,
                                  visualDensity: const VisualDensity(
                                    horizontal: -1,
                                    vertical: -2,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  leading: GestureDetector(
                                    onTap: () async {
                                      try {
                                        final allProducts =
                                            await RealtimeDatabaseService.getAllProducts();
                                        final product = allProducts.firstWhere(
                                          (p) =>
                                              p.id == _cartItems[i].productId,
                                        );
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProductDetailScreen(
                                                  product: product,
                                                ),
                                          ),
                                        );
                                        _loadCart();
                                      } catch (e) {
                                        print('Error loading product: $e');
                                      }
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child:
                                          _cartItems[i]
                                              .productImageUrl
                                              .isNotEmpty
                                          ? Image.network(
                                              _cartItems[i].productImageUrl,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    width: 46,
                                                    height: 46,
                                                    color: AppTheme.accentColor
                                                        .withOpacity(0.1),
                                                    child: const Icon(
                                                      Icons.image,
                                                      size: 30,
                                                    ),
                                                  ),
                                            )
                                          : Container(
                                              width: 46,
                                              height: 46,
                                              color: AppTheme.accentColor
                                                  .withOpacity(0.08),
                                              child: const Icon(
                                                Icons.image,
                                                size: 30,
                                              ),
                                            ),
                                    ),
                                  ),
                                  title: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _cartItems[i].productName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            _removeItem(_cartItems[i].id),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        color: AppTheme.errorColor,
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (_cartItems[i].isOnPromotion) ...[
                                        Row(
                                          children: [
                                            Text(
                                              _formatPrice(
                                                _cartItems[i].originalPrice! *
                                                    _cartItems[i].quantity,
                                              ),
                                              style: TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 10,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.successColor,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '-${_cartItems[i].discountPercentage!.toStringAsFixed(0)}%',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Livraison Express (48h) à partir de 25€ d\'achat',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              _expressDelivery ? 0.9 : 0.8,
                                            ),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Text(
                                        PricingUtils.formatPriceWithUnit(
                                          _cartItems[i].unitPrice,
                                          _cartItems[i].unit,
                                        ),
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.remove,
                                                size: 16,
                                              ),
                                              onPressed:
                                                  _cartItems[i].quantity >
                                                      _getIncrementStep(
                                                        _cartItems[i].unit,
                                                      )
                                                  ? () {
                                                      final step =
                                                          _getIncrementStep(
                                                            _cartItems[i].unit,
                                                          );
                                                      _updateQuantity(
                                                        _cartItems[i].id,
                                                        (_cartItems[i]
                                                                    .quantity -
                                                                step)
                                                            .clamp(
                                                              step,
                                                              double.infinity,
                                                            ),
                                                      );
                                                    }
                                                  : null,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 32,
                                                minHeight: 32,
                                              ),
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Text(
                                              '${_formatQuantity(_cartItems[i].quantity, _cartItems[i].unit)} ${_cartItems[i].unit}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.add,
                                                size: 16,
                                              ),
                                              onPressed: () {
                                                final step = _getIncrementStep(
                                                  _cartItems[i].unit,
                                                );
                                                _updateQuantity(
                                                  _cartItems[i].id,
                                                  _cartItems[i].quantity + step,
                                                );
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 30,
                                                minHeight: 30,
                                              ),
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatPrice(_cartItems[i].totalPrice),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (i != _cartItems.length - 1)
                                const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 16),
                          ],
                          if (!_deliveryAvailable) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.errorColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppTheme.errorColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Livraison non disponible pour ${_resolvedCommuneName ?? 'cette commune'} (${_resolvedWilayaName ?? 'wilaya'}). \nVeuillez sélectionner une adresse dans nos zones desservies (Béjaïa, Tizi Ouzou, Jijel, Sétif ou Bordj Bou Arreridj).',
                                      style: TextStyle(
                                        color: AppTheme.errorColor,
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_deliveryAvailable) ...[
                            Row(
                              children: [
                                // Compact Express Delivery (only if outside Béjaïa)
                                if (!_isBejaia) ...[
                                  Expanded(
                                    child: InkWell(
                                      onTap: canUseExpress
                                          ? () => setState(
                                              () => _expressDelivery =
                                                  !_expressDelivery,
                                            )
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: _expressDelivery
                                              ? const LinearGradient(
                                                  colors: [
                                                    AppTheme.secondaryColor,
                                                    AppTheme.primaryColor,
                                                  ],
                                                )
                                              : null,
                                          color: _expressDelivery
                                              ? null
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _expressDelivery
                                                ? Colors.transparent
                                                : AppTheme.primaryColor
                                                      .withOpacity(0.25),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(
                                                    _expressDelivery
                                                        ? 0.25
                                                        : 0.06,
                                                  ),
                                              blurRadius: _expressDelivery
                                                  ? 16
                                                  : 8,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.speed,
                                              color: _expressDelivery
                                                  ? Colors.white
                                                  : AppTheme.primaryColor,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Livraison Express',
                                              style: TextStyle(
                                                color: _expressDelivery
                                                    ? Colors.white
                                                    : AppTheme.primaryColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              _formatPrice(_expressDeliveryFee),
                                              style: TextStyle(
                                                color: _expressDelivery
                                                    ? Colors.white
                                                    : AppTheme.primaryColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                // Compact Tip Module
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _setTip('custom'),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: _tipMode == 'custom'
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF10AA2E),
                                                  Color(0xFF67DF47),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        color: _tipMode == 'custom'
                                            ? null
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _tipMode == 'custom'
                                              ? Colors.transparent
                                              : AppTheme.primaryColor
                                                    .withOpacity(0.25),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor
                                                .withOpacity(
                                                  _tipMode == 'custom'
                                                      ? 0.25
                                                      : 0.06,
                                                ),
                                            blurRadius: _tipMode == 'custom'
                                                ? 16
                                                : 8,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.money,
                                            color: _tipMode == 'custom'
                                                ? Colors.white
                                                : AppTheme.primaryColor,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Pourboire',
                                            style: TextStyle(
                                              color: _tipMode == 'custom'
                                                  ? Colors.white
                                                  : AppTheme.primaryColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _formatPrice(_tip),
                                            style: TextStyle(
                                              color: _tipMode == 'custom'
                                                  ? Colors.white
                                                  : AppTheme.primaryColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_tipMode == 'custom' && _showTipOptions) ...[
                              const SizedBox(height: 12),
                              // Predefined tip buttons row
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildTipButton('1', '1.00 €'),
                                    const SizedBox(width: 8),
                                    _buildTipButton('2', '2.00 €'),
                                    const SizedBox(width: 8),
                                    _buildTipButton('5', '5.00 €'),
                                    const SizedBox(width: 8),
                                    _buildTipButton('10', '10.00 €'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Custom tip input field
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: TextField(
                                  controller: _customTipController,
                                  focusNode: _customTipFocusNode,
                                  decoration: InputDecoration(
                                    labelText:
                                        'Montant du pourboire personnalisé',
                                    labelStyle: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.euro,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryColor,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppTheme.textSecondary
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onChanged: _updateCustomTip,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Total',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                _formatPrice(finalTotal),
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Dont livraison',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatPrice(_deliveryFee + expressFee),
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasTip)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'Merci pour votre pourboire !',
                                style: TextStyle(
                                  color: AppTheme.successColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (!hasTip)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'Ajoutez un pourboire pour remercier notre équipe ❤️',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _buildSecurePaymentHighlight(),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: ElevatedButton(
                              onPressed: canPlaceOrder
                                  ? _showOrderConfirmationDialog
                                  : null,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: AppTheme.primaryColor,
                                minimumSize: const Size(double.infinity, 44),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Passer commande',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurePaymentHighlight() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: isCompact ? 3.6 : 4.4,
                  child: Image.asset(
                    'lib/assets/images/secure-paiements.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipButton(String mode, String label) {
    final isSelected = _tipMode == mode;

    return GestureDetector(
      onTap: () => _setTip(mode),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: mode == 'custom' ? 14 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTheme.secondaryColor, AppTheme.primaryColor],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.primaryColor.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(
                isSelected ? 0.25 : 0.06,
              ),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAddressPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.35),
      highlightColor: Colors.white.withOpacity(0.75),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: MediaQuery.of(context).size.width * 0.4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSelectorCard(bool hasCart) {
    final label = _selectedAddress?['label']?.toString().trim();

    final displayLabel = label != null && label.isNotEmpty
        ? label
        : 'Choisissez votre adresse de livraison';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showAddressSelector,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayLabel,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: _selectedAddress != null
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.edit, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double value) {
    final locale = Localizations.localeOf(context);
    return FormattingUtils.formatPriceWithLocale(value, locale);
  }
}
