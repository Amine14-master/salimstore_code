import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_search_bar.dart';
import '../../firebase_options.dart';

enum _DeliveryCodeValidation { success, missing, mismatch }

class _AdminDeliveryValidationSheet extends StatefulWidget {
  const _AdminDeliveryValidationSheet({required this.onConfirm});

  final Future<_DeliveryCodeValidation> Function(String code) onConfirm;

  @override
  State<_AdminDeliveryValidationSheet> createState() =>
      _AdminDeliveryValidationSheetState();
}

class _AdminDeliveryValidationSheetState
    extends State<_AdminDeliveryValidationSheet> {
  final TextEditingController _codeController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleValidation() async {
    final input = _codeController.text.trim();
    if (input.length != 4) {
      setState(() {
        _error = 'Veuillez saisir un code à 4 chiffres.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await widget.onConfirm(input);
      if (!mounted) return;

      switch (result) {
        case _DeliveryCodeValidation.success:
          Navigator.of(context).pop(true);
          break;
        case _DeliveryCodeValidation.missing:
          setState(() {
            _submitting = false;
            _error = 'Aucun code enregistré pour cette commande.';
          });
          break;
        case _DeliveryCodeValidation.mismatch:
          setState(() {
            _submitting = false;
            _error = 'Le code ne correspond pas. Réessayez.';
          });
          break;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 140,
                child: Lottie.asset(
                  'lib/assets/animations/category_loader.json',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Valider la livraison',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez le code communiqué par le client pour clôturer cette commande.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Code à 4 chiffres',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _handleValidation,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.successColor,
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.verified_user_rounded),
                      label: Text(
                        _submitting ? 'Validation...' : 'Valider',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusVisuals {
  final Color color;
  final String label;
  final IconData icon;
  final int stageIndex;

  const _StatusVisuals({
    required this.color,
    required this.label,
    required this.icon,
    required this.stageIndex,
  });
}

class _ClientProfile {
  final String name;
  final String? photoUrl;
  final String? email;
  final String? phone;

  const _ClientProfile({
    required this.name,
    this.photoUrl,
    this.email,
    this.phone,
  });
}

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _allOrders = [];
  late TabController _tabController;
  StreamSubscription<DatabaseEvent>? _ordersSubscription;
  StreamSubscription<DatabaseEvent>? _usersSubscription;
  String _searchQuery = '';
  final Map<String, _ClientProfile> _clientProfiles = {};
  final Set<String> _pdfInProgress = <String>{};
  bool _bulkExporting = false;
  static const List<String> _tabStatusKeys = [
    'pending',
    'processing',
    'delivered',
  ];
  static const Map<String, String> _tabDisplayLabels = {
    'pending': 'En attente',
    'processing': 'En livraison',
    'delivered': 'Terminée',
  };

  _StatusVisuals _resolveStatusVisuals(String status) {
    final normalized = status.toLowerCase();

    if (normalized == 'pending' || normalized == 'en attente') {
      return _StatusVisuals(
        color: AppTheme.warningColor,
        label: 'En attente',
        icon: Icons.watch_later_rounded,
        stageIndex: 0,
      );
    }

    if (normalized == 'processing' ||
        normalized == 'en cours' ||
        normalized == 'en cours de livraison' ||
        normalized == 'livraison') {
      return _StatusVisuals(
        color: AppTheme.accentColor,
        label: 'En livraison',
        icon: Icons.local_shipping_outlined,
        stageIndex: 2,
      );
    }

    if (normalized == 'awaiting_confirmation' ||
        normalized == 'validation' ||
        normalized == 'client_confirmed') {
      return _StatusVisuals(
        color: AppTheme.warningColor,
        label: 'Code à valider',
        icon: Icons.verified_outlined,
        stageIndex: 3,
      );
    }

    if (normalized == 'delivered' ||
        normalized == 'livré' ||
        normalized == 'delivre' ||
        normalized == 'delivré' ||
        normalized == 'termines' ||
        normalized == 'terminé' ||
        normalized == 'termine') {
      return _StatusVisuals(
        color: AppTheme.successColor,
        label: 'Terminée',
        icon: Icons.task_alt,
        stageIndex: 3,
      );
    }

    if (normalized == 'awaiting_confirmation' ||
        normalized == 'validation' ||
        normalized == 'client_confirmed') {
      return _StatusVisuals(
        color: AppTheme.warningColor,
        label: 'Code à valider',
        icon: Icons.verified_outlined,
        stageIndex: 3,
      );
    }

    return _StatusVisuals(
      color: AppTheme.textSecondary,
      label: status,
      icon: Icons.info_outline_rounded,
      stageIndex: 0,
    );
  }

  double _safeToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  Future<({pw.Font base, pw.Font bold})> _loadPdfFonts() async {
    try {
      final regular = await PdfGoogleFonts.interRegular();
      final bold = await PdfGoogleFonts.interSemiBold();
      return (base: regular, bold: bold);
    } catch (e) {
      debugPrint('PDF font download failed, fallback to Helvetica: $e');
      return (base: pw.Font.helvetica(), bold: pw.Font.helveticaBold());
    }
  }

  Future<Uint8List> _createOrderPdf(Map<String, dynamic> order) async {
    final doc = pw.Document();
    final fonts = await _loadPdfFonts();
    final regularFont = fonts.base;
    final boldFont = fonts.bold;
    final pdfTheme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);
    final orderId = _resolveOrderId(order);
    final statusVisuals = _resolveStatusVisuals(
      (order['status'] ?? '').toString(),
    );
    final customerName =
        (order['customerName'] ?? order['userName'] ?? 'Client').toString();
    final deliveryAddress =
        (order['deliveryAddress'] ?? 'Adresse non spécifiée').toString();
    final phone = (order['phone'] ?? order['phoneNumber'] ?? 'Non fourni')
        .toString();
    final createdAt = _parseOrderDate(order['createdAt']);
    final formattedDate = _formatOrderDate(createdAt);

    final items = _extractOrderItems(order);
    final cartTotal = _safeToDouble(order['cartTotal']);
    final deliveryFee = _safeToDouble(order['deliveryFee']);
    final expressFee = _safeToDouble(order['expressFee']);
    final tip = _safeToDouble(order['tip']);
    final total = _safeToDouble(order['total']);

    String formatCurrency(double value) => '${value.toStringAsFixed(2)} €';

    final itemRows = items.map((item) {
      final name = (item['productName'] ?? 'Produit').toString();
      final qty = _formatQuantity(item['quantity']);
      final unit = (item['unit'] ?? '').toString();
      final itemTotal = _safeToDouble(item['totalPrice'] ?? item['price'] ?? 0);
      return [
        name,
        unit.isNotEmpty ? '$qty $unit' : qty,
        formatCurrency(itemTotal),
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        theme: pdfTheme,
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.orange400, PdfColors.deepOrange600],
              ),
              borderRadius: pw.BorderRadius.circular(18),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Tableau Admin SalimStore',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    font: boldFont,
                    fontSize: 22,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Récapitulatif de commande',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 14),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Commande #$orderId',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    font: boldFont,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(16),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Informations client',
                  style: pw.TextStyle(font: boldFont, fontSize: 15),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Client: $customerName'),
                pw.Text('Téléphone: $phone'),
                pw.Text('Adresse: $deliveryAddress'),
                pw.Text('Date: $formattedDate'),
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 12,
                        height: 12,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(
                            statusVisuals.color.toARGB32(),
                          ),
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        statusVisuals.label,
                        style: pw.TextStyle(font: boldFont),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (itemRows.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              'Détails des articles',
              style: pw.TextStyle(font: boldFont, fontSize: 15),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Produit', 'Quantité', 'Total'],
              data: itemRows,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.deepOrange400,
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.2),
              },
            ),
          ],
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Sous-total'),
                    pw.Text(formatCurrency(cartTotal)),
                  ],
                ),
                if (deliveryFee > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Frais de livraison'),
                      pw.Text(formatCurrency(deliveryFee)),
                    ],
                  ),
                if (expressFee > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Livraison express'),
                      pw.Text(formatCurrency(expressFee)),
                    ],
                  ),
                if (tip > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Pourboire'),
                      pw.Text(formatCurrency(tip)),
                    ],
                  ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total encaissé',
                      style: pw.TextStyle(font: boldFont),
                    ),
                    pw.Text(
                      formatCurrency(total),
                      style: pw.TextStyle(font: boldFont),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (order['notes'] != null &&
              order['notes'].toString().trim().isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'Notes internes',
              style: pw.TextStyle(font: boldFont, fontSize: 14),
            ),
            pw.SizedBox(height: 6),
            pw.Text(order['notes'].toString()),
          ],
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _exportOrderAsPdf(Map<String, dynamic> order) async {
    final orderId = _resolveOrderId(order);
    if (orderId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande introuvable pour PDF'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_pdfInProgress.contains(orderId)) return;

    setState(() => _pdfInProgress.add(orderId));
    try {
      final bytes = await _createOrderPdf(order);
      final printingInfo = await Printing.info();
      String successMessage;

      if (printingInfo.canShare) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'commande_admin_$orderId.pdf',
        );
        successMessage =
            'PDF généré pour la commande #$orderId et prêt à être partagé.';
      } else if (printingInfo.canPrint || kIsWeb) {
        await Printing.layoutPdf(onLayout: (_) async => bytes);
        successMessage =
            'Aperçu du reçu ouvert — vous pouvez l\'imprimer ou l\'enregistrer.';
      } else {
        throw UnsupportedError(
          'Le partage de PDF n\'est pas disponible sur cet appareil.',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is UnsupportedError
                  ? e.message ??
                        'Le partage de PDF n\'est pas disponible sur cet appareil.'
                  : 'Erreur: $e',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _pdfInProgress.remove(orderId));
      } else {
        _pdfInProgress.remove(orderId);
      }
    }
  }

  DateTime? _parseOrderDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  String _formatOrderDate(DateTime? date) {
    if (date == null) return 'Date indisponible';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  List<Map<String, dynamic>> _extractOrderItems(Map<String, dynamic> order) {
    final rawItems = order['items'];
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map>()
        .map((element) => Map<String, dynamic>.from(element))
        .toList();
  }

  String _formatQuantity(dynamic value) {
    if (value is num) {
      return value % 1 == 0
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
    }
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return '1';
  }

  Widget _buildStatusTimeline(int activeStage, Color accentColor) {
    final stages = [
      {'icon': Icons.receipt_long, 'label': 'Reçue'},
      {'icon': Icons.inventory_2_rounded, 'label': 'Préparation'},
      {'icon': Icons.local_shipping_outlined, 'label': 'Livraison'},
      {'icon': Icons.verified_rounded, 'label': 'Terminée'},
    ];

    final clampedStage = activeStage.clamp(0, stages.length - 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(stages.length, (index) {
        final isReached = index <= clampedStage;
        final isCurrent = index == clampedStage;
        final hasLeftConnector = index > 0;
        final hasRightConnector = index < stages.length - 1;

        BoxDecoration _connectorDecoration(bool active) => BoxDecoration(
          gradient: LinearGradient(
            colors: active
                ? [
                    accentColor.withValues(alpha: 0.7),
                    accentColor.withValues(alpha: 0.2),
                  ]
                : [
                    AppTheme.textLight.withValues(alpha: 0.5),
                    AppTheme.textLight.withValues(alpha: 0.2),
                  ],
          ),
        );

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: EdgeInsets.only(
                          right: hasLeftConnector ? 8 : 0,
                        ),
                        decoration: hasLeftConnector
                            ? _connectorDecoration(index - 1 <= clampedStage)
                            : const BoxDecoration(color: Colors.transparent),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isReached
                            ? accentColor.withValues(alpha: 0.15)
                            : Colors.white,
                        border: Border.all(
                          color: isReached ? accentColor : AppTheme.textLight,
                          width: 2,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.28),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        stages[index]['icon'] as IconData,
                        size: 16,
                        color: isReached ? accentColor : AppTheme.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: EdgeInsets.only(
                          left: hasRightConnector ? 8 : 0,
                        ),
                        decoration: hasRightConnector
                            ? _connectorDecoration(index < clampedStage)
                            : const BoxDecoration(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stages[index]['label'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isReached
                      ? accentColor
                      : AppTheme.textSecondary.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label, {
    Color? textColor,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.textLight.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor ?? AppTheme.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor ?? AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupRealtimeListener();
    _setupClientProfilesListener();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _usersSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealtimeListener() {
    setState(() => _loading = true);
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
    );
    final ref = db.ref('orders');

    _ordersSubscription = ref.onValue.listen(
      (event) {
        if (!mounted) return;
        List<Map<String, dynamic>> found = [];

        if (event.snapshot.exists) {
          final value = event.snapshot.value;
          if (value is Map) {
            value.forEach((id, orderData) {
              if (orderData != null && orderData is Map) {
                final orderMap = Map<String, dynamic>.from(orderData);
                orderMap['id'] = orderMap['orderId'] ?? id;
                found.add(orderMap);
              }
            });
          }
        }

        found.sort((a, b) {
          final aTime = a['createdAt'] is int
              ? a['createdAt'] as int
              : (a['createdAt'] is String
                    ? DateTime.tryParse(
                            a['createdAt'],
                          )?.millisecondsSinceEpoch ??
                          0
                    : 0);
          final bTime = b['createdAt'] is int
              ? b['createdAt'] as int
              : (b['createdAt'] is String
                    ? DateTime.tryParse(
                            b['createdAt'],
                          )?.millisecondsSinceEpoch ??
                          0
                    : 0);
          return bTime.compareTo(aTime);
        });

        if (mounted) {
          setState(() {
            _allOrders = found;
            _loading = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Error listening to orders: $error');
        if (mounted) {
          setState(() => _loading = false);
        }
      },
    );
  }

  void _setupClientProfilesListener() {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
    );
    final ref = db.ref('users');

    _usersSubscription = ref.onValue.listen(
      (event) {
        if (!mounted) return;

        final Map<String, _ClientProfile> resolved = {};

        if (event.snapshot.exists && event.snapshot.value is Map) {
          final raw = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          raw.forEach((key, value) {
            if (value is Map) {
              final data = Map<dynamic, dynamic>.from(value);
              final name =
                  _resolveStringCandidate(data['name']) ??
                  _resolveStringCandidate(data['displayName']) ??
                  _resolveStringCandidate(data['fullName']) ??
                  _resolveStringCandidate(data['username']) ??
                  'Client';
              final photo = _resolveStringCandidate(
                data['photoUrl'] ?? data['photoURL'] ?? data['avatar'],
              );
              final email = _resolveStringCandidate(
                data['email'] ?? data['mail'] ?? data['contactEmail'],
              );
              final phone = _resolveStringCandidate(
                data['phone'] ?? data['phoneNumber'] ?? data['contactPhone'],
              );
              resolved[key.toString()] = _ClientProfile(
                name: name,
                photoUrl: photo,
                email: email,
                phone: phone,
              );
            }
          });
        }

        setState(() {
          _clientProfiles
            ..clear()
            ..addAll(resolved);
        });
      },
      onError: (error) =>
          debugPrint('Error listening to user profiles for orders: $error'),
    );
  }

  String? _resolveStringCandidate(dynamic value) {
    if (value == null) return null;
    final candidate = value.toString().trim();
    if (candidate.isEmpty) return null;
    if (candidate.toLowerCase() == 'null') return null;
    return candidate;
  }

  String _resolveCustomerName(Map<String, dynamic> order) {
    final userId = _resolveStringCandidate(order['userId']);
    if (userId != null) {
      final profile = _clientProfiles[userId];
      if (profile != null && profile.name.trim().isNotEmpty) {
        return profile.name;
      }
    }

    final keys = [
      'customerName',
      'clientName',
      'fullName',
      'name',
      'userName',
      'customer',
      'contactName',
    ];

    for (final key in keys) {
      final value = _resolveStringCandidate(order[key]);
      if (value != null &&
          value.isNotEmpty &&
          value.toLowerCase() != 'client') {
        return value;
      }
    }

    final customer = order['customer'];
    if (customer is Map) {
      final nested =
          _resolveStringCandidate(customer['name']) ??
          _resolveStringCandidate(customer['fullName']) ??
          _resolveStringCandidate(customer['displayName']);
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
    }

    return 'Client';
  }

  String? _resolveCustomerPhoto(Map<String, dynamic> order) {
    final userId = _resolveStringCandidate(order['userId']);
    if (userId != null) {
      final profile = _clientProfiles[userId];
      if (profile != null && profile.photoUrl != null) {
        final trimmed = profile.photoUrl!.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }

    final keys = [
      'photoUrl',
      'photoURL',
      'avatar',
      'customerPhoto',
      'clientPhoto',
    ];

    for (final key in keys) {
      final value = _resolveStringCandidate(order[key]);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    final customer = order['customer'];
    if (customer is Map) {
      final nested = _resolveStringCandidate(customer['photo']);
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
    }

    return null;
  }

  String? _resolveCustomerEmail(Map<String, dynamic> order) {
    final userId = _resolveStringCandidate(order['userId']);
    if (userId != null) {
      final profile = _clientProfiles[userId];
      final email = profile?.email;
      if (email != null && email.trim().isNotEmpty) {
        return email.trim();
      }
    }

    final keys = ['email', 'customerEmail', 'contactEmail', 'userEmail'];

    for (final key in keys) {
      final candidate = _resolveStringCandidate(order[key]);
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    final customer = order['customer'];
    if (customer is Map) {
      final nested = _resolveStringCandidate(
        customer['email'] ?? customer['contactEmail'],
      );
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
    }

    return null;
  }

  String? _resolveCustomerPhone(
    Map<String, dynamic> order, {
    String? fallback,
  }) {
    final userId = _resolveStringCandidate(order['userId']);
    if (userId != null) {
      final profile = _clientProfiles[userId];
      final phone = profile?.phone;
      if (phone != null && phone.trim().isNotEmpty) {
        return phone.trim();
      }
    }

    final keys = [
      'phone',
      'phoneNumber',
      'contactPhone',
      'customerPhone',
      'mobile',
    ];

    for (final key in keys) {
      final candidate = _resolveStringCandidate(order[key]);
      if (candidate != null && candidate.isNotEmpty && candidate != '—') {
        return candidate;
      }
    }

    final customer = order['customer'];
    if (customer is Map) {
      final nested = _resolveStringCandidate(
        customer['phone'] ?? customer['phoneNumber'] ?? customer['mobile'],
      );
      if (nested != null && nested.isNotEmpty && nested != '—') {
        return nested;
      }
    }

    final resolvedFallback = _resolveStringCandidate(fallback);
    if (resolvedFallback != null && resolvedFallback != '—') {
      return resolvedFallback;
    }
    return null;
  }

  bool _looksLikeCoordinates(String value) {
    final cleaned = value.trim();
    return RegExp(r'^-?\d+(?:\.\d+)?\s*,\s*-?\d+(?:\.\d+)?$').hasMatch(cleaned);
  }

  String _resolveDeliveryLabel(Map<String, dynamic> order) {
    final candidates = [
      order['deliveryLabel'],
      order['addressLabel'],
      order['customerAddressLabel'],
      order['addressName'],
    ];

    for (final candidate in candidates) {
      final resolved = _resolveStringCandidate(candidate);
      if (resolved != null) {
        return resolved;
      }
    }

    final address =
        _resolveStringCandidate(order['deliveryAddress'] ?? order['address']) ??
        '';
    if (address.isNotEmpty && !_looksLikeCoordinates(address)) {
      return address;
    }

    final commune = _resolveStringCandidate(order['commune']);
    final wilaya = _resolveStringCandidate(order['wilaya']);
    if (commune != null && wilaya != null) {
      return '$commune, $wilaya';
    }
    if (wilaya != null) {
      return 'Livraison - $wilaya';
    }
    if (address.isNotEmpty && _looksLikeCoordinates(address)) {
      return 'Position partagée';
    }
    return 'Adresse non renseignée';
  }

  Widget _buildAvatar(String name, {String? photoUrl, double size = 26}) {
    final trimmed = name.trim();
    final display = trimmed.isNotEmpty ? trimmed : 'Client';
    final initial = display.isNotEmpty ? display[0].toUpperCase() : 'C';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
          ? NetworkImage(photoUrl)
          : null,
      child: photoUrl == null || photoUrl.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
                fontSize: size * 0.5,
              ),
            )
          : null,
    );
  }

  Widget _buildClientChip(String name, {String? photoUrl}) {
    final trimmed = name.trim();
    final display = trimmed.isNotEmpty ? trimmed : 'Client';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.textLight.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatar(display, photoUrl: photoUrl, size: 26),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              display,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getOrdersByStatus(String status) {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = _allOrders.where((order) {
      final orderStatus = (order['status'] ?? 'pending')
          .toString()
          .toLowerCase();
      final searchStatus = status.toLowerCase();

      if (searchStatus == 'en attente' || searchStatus == 'pending') {
        return orderStatus == 'pending' || orderStatus == 'en attente';
      }
      if (searchStatus == 'en cours' || searchStatus == 'processing') {
        return orderStatus == 'processing' ||
            orderStatus == 'en cours' ||
            orderStatus == 'en cours de livraison' ||
            orderStatus == 'livraison' ||
            orderStatus == 'awaiting_confirmation';
      }
      if (searchStatus == 'livré' ||
          searchStatus == 'delivered' ||
          searchStatus == 'delivre') {
        return orderStatus == 'delivered' ||
            orderStatus == 'livré' ||
            orderStatus == 'delivre' ||
            orderStatus == 'termines' ||
            orderStatus == 'terminé' ||
            orderStatus == 'termine';
      }

      final matchesStatus = orderStatus == searchStatus;
      if (!matchesStatus) return false;

      if (query.isEmpty) return true;

      final customerName = (order['customerName'] ?? order['userName'] ?? '')
          .toString()
          .toLowerCase();
      final phone = (order['phone'] ?? order['phoneNumber'] ?? '')
          .toString()
          .toLowerCase();
      final address = (order['deliveryAddress'] ?? '').toString().toLowerCase();
      final orderId = (order['orderId'] ?? order['id'] ?? '')
          .toString()
          .toLowerCase();

      return customerName.contains(query) ||
          phone.contains(query) ||
          address.contains(query) ||
          orderId.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final aDate = _parseOrderDate(a['createdAt']);
      final bDate = _parseOrderDate(b['createdAt']);
      final aMillis = aDate?.millisecondsSinceEpoch ?? 0;
      final bMillis = bDate?.millisecondsSinceEpoch ?? 0;
      return bMillis.compareTo(aMillis);
    });

    return filtered;
  }

  String _statusKeyForIndex(int index) {
    if (index < 0 || index >= _tabStatusKeys.length) {
      return _tabStatusKeys.first;
    }
    return _tabStatusKeys[index];
  }

  Future<void> _exportCurrentTabOrders() async {
    final statusKey = _statusKeyForIndex(_tabController.index);
    final orders = _getOrdersByStatus(statusKey);
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final displayLabel = _tabDisplayLabels[statusKey] ?? statusKey;
    final normalized = displayLabel.toLowerCase().replaceAll(' ', '_');
    final filename = 'commandes_${normalized}_$timestamp.pdf';
    await _exportOrdersAsPdf(orders, filename);
  }

  Future<void> _exportOrdersAsPdf(
    List<Map<String, dynamic>> orders,
    String filename,
  ) async {
    if (orders.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune commande à exporter pour cet onglet.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
      return;
    }

    setState(() => _bulkExporting = true);
    try {
      final doc = pw.Document();
      final fonts = await _loadPdfFonts();
      final baseFont = fonts.base;
      final boldFont = fonts.bold;
      final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);

      for (final order in orders) {
        final items = _extractOrderItems(order);
        final cartTotal = _safeToDouble(order['cartTotal']);
        final deliveryFee = _safeToDouble(order['deliveryFee']);
        final expressFee = _safeToDouble(order['expressFee']);
        final tip = _safeToDouble(order['tip']);
        final total = _safeToDouble(order['total']);
        final orderId = _resolveOrderId(order);
        final createdAt = _parseOrderDate(order['createdAt']);
        final formattedDate = _formatOrderDate(createdAt);
        final customerName =
            (order['customerName'] ?? order['userName'] ?? 'Client').toString();
        final deliveryAddress =
            (order['deliveryAddress'] ?? 'Adresse non spécifiée').toString();
        final phone = (order['phone'] ?? order['phoneNumber'] ?? 'Non fourni')
            .toString();
        final status = (order['status'] ?? '').toString();
        final visuals = _resolveStatusVisuals(status);

        String formatCurrency(double value) => '${value.toStringAsFixed(2)} €';

        final itemRows = items.map((item) {
          final name = (item['productName'] ?? 'Produit').toString();
          final qty = _formatQuantity(item['quantity']);
          final unit = (item['unit'] ?? '').toString();
          final itemTotal = _safeToDouble(
            item['totalPrice'] ?? item['price'] ?? 0,
          );
          return [
            name,
            unit.isNotEmpty ? '$qty $unit' : qty,
            formatCurrency(itemTotal),
          ];
        }).toList();

        doc.addPage(
          pw.MultiPage(
            margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            theme: theme,
            build: (context) => [
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [PdfColors.orange400, PdfColors.deepOrange600],
                  ),
                  borderRadius: pw.BorderRadius.circular(18),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Tableau Admin SalimStore',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        font: boldFont,
                        fontSize: 22,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Récapitulatif de commande',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 14),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      orderId.isNotEmpty ? 'Commande #$orderId' : 'Commande',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        font: boldFont,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(16),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Informations client',
                      style: pw.TextStyle(font: boldFont, fontSize: 15),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Client: $customerName'),
                    pw.Text('Téléphone: $phone'),
                    pw.Text('Adresse: $deliveryAddress'),
                    pw.Text('Date: $formattedDate'),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 12,
                            height: 12,
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(visuals.color.toARGB32()),
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            visuals.label,
                            style: pw.TextStyle(font: boldFont),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (itemRows.isNotEmpty) ...[
                pw.SizedBox(height: 18),
                pw.Text(
                  'Détails des articles',
                  style: pw.TextStyle(font: boldFont, fontSize: 15),
                ),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headers: ['Produit', 'Quantité', 'Total'],
                  data: itemRows,
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.deepOrange400,
                  ),
                  headerStyle: pw.TextStyle(
                    color: PdfColors.white,
                    font: boldFont,
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.5),
                    1: const pw.FlexColumnWidth(1.2),
                    2: const pw.FlexColumnWidth(1.2),
                  },
                ),
              ],
              pw.SizedBox(height: 18),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Sous-total'),
                        pw.Text(formatCurrency(cartTotal)),
                      ],
                    ),
                    if (deliveryFee > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Frais de livraison'),
                          pw.Text(formatCurrency(deliveryFee)),
                        ],
                      ),
                    if (expressFee > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Livraison express'),
                          pw.Text(formatCurrency(expressFee)),
                        ],
                      ),
                    if (tip > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Pourboire'),
                          pw.Text(formatCurrency(tip)),
                        ],
                      ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total encaissé',
                          style: pw.TextStyle(font: boldFont),
                        ),
                        pw.Text(
                          formatCurrency(total),
                          style: pw.TextStyle(font: boldFont),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (order['notes'] != null &&
                  order['notes'].toString().trim().isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  'Notes internes',
                  style: pw.TextStyle(font: boldFont, fontSize: 14),
                ),
                pw.SizedBox(height: 6),
                pw.Text(order['notes'].toString()),
              ],
            ],
          ),
        );
      }

      final bytes = await doc.save();
      final printingInfo = await Printing.info();
      if (printingInfo.canShare) {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      } else if (printingInfo.canPrint || kIsWeb) {
        await Printing.layoutPdf(onLayout: (_) async => bytes);
      } else {
        throw UnsupportedError(
          'L\'export PDF n\'est pas supporté sur cet appareil.',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exporté (${orders.length} commandes).'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _bulkExporting = false);
      } else {
        _bulkExporting = false;
      }
    }
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
      );
      final orderId = order['orderId'] ?? order['id'];
      await db.ref('orders').child(orderId.toString()).update({
        'status': 'livraison',
        'acceptedAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande acceptée'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _resolveOrderId(Map<String, dynamic> order) {
    final dynamic raw = order['orderId'] ?? order['id'];
    if (raw == null) return '';
    return raw.toString();
  }

  Future<_DeliveryCodeValidation> _validateDeliveryCode(
    String orderId,
    String code,
  ) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
    );

    final snapshot = await db.ref('orders/$orderId/deliveryCode').get();
    if (!snapshot.exists || snapshot.value == null) {
      return _DeliveryCodeValidation.missing;
    }

    final storedCode = snapshot.value.toString().trim();
    return storedCode == code.trim()
        ? _DeliveryCodeValidation.success
        : _DeliveryCodeValidation.mismatch;
  }

  Future<void> _completeDelivery(String orderId) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
      );

      await db.ref('orders').child(orderId).update({
        'status': 'termines',
        'adminConfirmedAt': ServerValue.timestamp,
        'deliveryCodeValidatedAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      await db.ref('orders/$orderId/deliveryCode').remove();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Commande #$orderId complétée'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _showDeliveryValidationSheet(Map<String, dynamic> order) async {
    final orderId = _resolveOrderId(order);
    if (orderId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande introuvable'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final validated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _AdminDeliveryValidationSheet(
        onConfirm: (code) => _validateDeliveryCode(orderId, code),
      ),
    );

    if (validated == true) {
      await _completeDelivery(orderId);
    }
  }

  Future<void> _showOrderDetails(Map<String, dynamic> order) async {
    final items = _extractOrderItems(order);
    final cartTotal = _safeToDouble(order['cartTotal']);
    final deliveryFee = _safeToDouble(order['deliveryFee']);
    final expressFee = _safeToDouble(order['expressFee']);
    final tip = _safeToDouble(order['tip']);
    final total = _safeToDouble(order['total']);
    final deliveryAddress =
        (order['deliveryAddress'] ?? 'Adresse non spécifiée').toString();
    final fallbackPhone = (order['phone'] ?? order['phoneNumber'] ?? '—')
        .toString();
    final orderId = _resolveOrderId(order);
    final createdAt = _parseOrderDate(order['createdAt']);
    final formattedDate = _formatOrderDate(createdAt);
    final status = (order['status'] ?? '').toString();
    final visuals = _resolveStatusVisuals(status);
    final pdfBusy = orderId.isEmpty ? false : _pdfInProgress.contains(orderId);
    final theme = Theme.of(context);
    final customerName = _resolveCustomerName(order);
    final customerPhoto = _resolveCustomerPhoto(order);
    final customerEmail = _resolveCustomerEmail(order);
    final customerPhone = _resolveCustomerPhone(order, fallback: fallbackPhone);
    final deliveryLabel = _resolveDeliveryLabel(order);
    final emailLabel = (customerEmail ?? '').trim();
    final displayEmail = emailLabel.isEmpty
        ? 'Email non renseigné'
        : emailLabel;
    final normalizedPhone = (customerPhone ?? '').trim();
    final displayPhone = normalizedPhone.isEmpty || normalizedPhone == '—'
        ? 'Téléphone non renseigné'
        : normalizedPhone;
    final canCallClient = normalizedPhone.isNotEmpty && normalizedPhone != '—';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          contentPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, visuals.color.withValues(alpha: 0.05)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          visuals.color.withValues(alpha: 0.08),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: visuals.color.withValues(alpha: 0.15),
                          blurRadius: 26,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: visuals.color.withValues(
                                      alpha: 0.22,
                                    ),
                                    blurRadius: 22,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: _buildAvatar(
                                customerName,
                                photoUrl: customerPhoto,
                                size: 78,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Shimmer.fromColors(
                                    baseColor: AppTheme.textPrimary,
                                    highlightColor: visuals.color.withValues(
                                      alpha: 0.4,
                                    ),
                                    child: Text(
                                      customerName,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                            color: AppTheme.textPrimary,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Client premium',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: visuals.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    visuals.icon,
                                    color: visuals.color,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    visuals.label,
                                    style: TextStyle(
                                      color: visuals.color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildInfoChip(
                              Icons.calendar_today_outlined,
                              formattedDate,
                              textColor: AppTheme.textPrimary,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.85,
                              ),
                            ),
                            _buildInfoChip(
                              Icons.location_on_outlined,
                              deliveryLabel,
                              textColor: AppTheme.textPrimary,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.85,
                              ),
                            ),
                            _buildInfoChip(
                              Icons.mail_outline_rounded,
                              displayEmail,
                              textColor: emailLabel.isEmpty
                                  ? AppTheme.warningColor
                                  : AppTheme.textPrimary,
                              backgroundColor: emailLabel.isEmpty
                                  ? AppTheme.warningColor.withValues(
                                      alpha: 0.14,
                                    )
                                  : Colors.white.withValues(alpha: 0.9),
                            ),
                            _buildInfoChip(
                              Icons.phone_rounded,
                              displayPhone,
                              textColor: canCallClient
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                              backgroundColor: canCallClient
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : AppTheme.textLight.withValues(alpha: 0.32),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 140,
                    child: Lottie.asset(
                      'lib/assets/animations/category_loader.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Produits',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...items.map((item) {
                    final name = (item['productName'] ?? 'Produit').toString();
                    final qty = _formatQuantity(item['quantity']);
                    final unit = (item['unit'] ?? '').toString();
                    final totalItem = _safeToDouble(
                      item['totalPrice'] ?? item['price'] ?? 0,
                    );
                    final quantityLabel = unit.isEmpty ? qty : '$qty $unit';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$name ($quantityLabel)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${totalItem.toStringAsFixed(2)} €',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  _buildDetailRow(
                    'Sous-total',
                    '${cartTotal.toStringAsFixed(2)} €',
                  ),
                  if (deliveryFee > 0)
                    _buildDetailRow(
                      'Frais de livraison',
                      '${deliveryFee.toStringAsFixed(2)} €',
                    ),
                  if (expressFee > 0)
                    _buildDetailRow(
                      'Livraison express',
                      '${expressFee.toStringAsFixed(2)} €',
                    ),
                  if (tip > 0)
                    _buildDetailRow('Pourboire', '${tip.toStringAsFixed(2)} €'),
                  const Divider(),
                  _buildDetailRow(
                    'Total encaissé',
                    '${total.toStringAsFixed(2)} €',
                    isTotal: true,
                  ),
                  if (order['notes'] != null &&
                      order['notes'].toString().trim().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.sticky_note_2_outlined,
                            color: AppTheme.warningColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              order['notes'].toString(),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: visuals.color.withValues(alpha: 0.08),
                    ),
                    child: Row(
                      children: [
                        Icon(visuals.icon, color: visuals.color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            visuals.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: visuals.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Ouvrir la carte'),
                        onPressed: () async {
                          final encoded = Uri.encodeComponent(deliveryAddress);
                          final uri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$encoded',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.phone),
                        label: const Text('Appeler le client'),
                        onPressed: canCallClient
                            ? () async {
                                final uri = Uri.parse('tel:$normalizedPhone');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fermer'),
            ),
            if (orderId.isNotEmpty)
              FilledButton.icon(
                onPressed: pdfBusy
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                        _exportOrderAsPdf(order);
                      },
                icon: pdfBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: const Text('Exporter en PDF'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AppTheme.textLight,
              ),
              const SizedBox(height: 8),
              Text(
                'Aucune commande',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = orders[index];
        final total = (order['total'] ?? 0).toDouble();
        final status = (order['status'] ?? 'pending').toString();
        final visuals = _resolveStatusVisuals(status);
        final date = _parseOrderDate(order['createdAt']);
        final formattedDate = _formatOrderDate(date);
        final items = _extractOrderItems(order);
        final previewItems = items.take(3).toList();
        final remainingItems = items.length - previewItems.length;
        final customerName = _resolveCustomerName(order);
        final deliveryLabel = _resolveDeliveryLabel(order);
        final customerPhoto = _resolveCustomerPhoto(order);
        final orderCode = order['orderId'] != null
            ? 'Commande ${order['orderId']}'
            : 'Commande #${order['id'].toString().substring(0, 6).toUpperCase()}';
        final normalizedStatus = status.toLowerCase();
        final isPending =
            normalizedStatus == 'pending' || normalizedStatus == 'en attente';
        final awaitingValidation = normalizedStatus == 'awaiting_confirmation';

        return GestureDetector(
          onTap: () => _showOrderDetails(order),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [visuals.color.withValues(alpha: 0.14), Colors.white],
              ),
              border: Border.all(
                color: visuals.color.withValues(alpha: 0.2),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: visuals.color.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -28,
                  right: -20,
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          visuals.color.withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  visuals.color.withAlpha(36),
                                  visuals.color.withAlpha(12),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(
                              visuals.icon,
                              size: 24,
                              color: visuals.color,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  orderCode,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 3),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildClientChip(
                                      customerName,
                                      photoUrl: customerPhoto,
                                    ),
                                    _buildInfoChip(
                                      Icons.location_on_outlined,
                                      deliveryLabel,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: _buildInfoChip(
                              visuals.icon,
                              visuals.label,
                              textColor: Colors.white,
                              backgroundColor: visuals.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildStatusTimeline(visuals.stageIndex, visuals.color),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Résumé',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                  ),
                                  Text(
                                    '${total.toStringAsFixed(0)} €',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ...previewItems.map((item) {
                                final itemMap = Map<String, dynamic>.from(item);
                                final productName =
                                    (itemMap['productName'] ?? 'Produit')
                                        .toString();
                                final quantity = _formatQuantity(
                                  itemMap['quantity'],
                                );
                                final unit = (itemMap['unit'] ?? '').toString();
                                final itemTotal = (itemMap['totalPrice'] ?? 0)
                                    .toDouble();
                                final quantityLabel = unit.isEmpty
                                    ? quantity
                                    : '$quantity $unit';
                                final initial = productName.isNotEmpty
                                    ? productName[0].toUpperCase()
                                    : '?';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: visuals.color.withValues(
                                            alpha: 0.12,
                                          ),
                                        ),
                                        child: Text(
                                          initial,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: visuals.color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              productName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              quantityLabel,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppTheme.textSecondary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${itemTotal.toStringAsFixed(0)} €',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              if (remainingItems > 0)
                                Text(
                                  '+ $remainingItems article(s) supplémentaires',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildInfoChip(
                            Icons.calendar_today_outlined,
                            formattedDate,
                          ),
                          _buildInfoChip(
                            Icons.location_on_outlined,
                            deliveryLabel,
                          ),
                          _buildInfoChip(
                            Icons.shopping_bag_outlined,
                            '${items.length} article(s)',
                          ),
                          _buildInfoChip(
                            Icons.attach_money,
                            '${total.toStringAsFixed(0)} €',
                            textColor: Colors.white,
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.successColor,
                                AppTheme.successColor.withValues(alpha: 0.8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.successColor.withValues(
                                  alpha: 0.32,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _acceptOrder(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 20,
                            ),
                            label: const Text(
                              'Accepter la commande',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (awaitingValidation) ...[
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.warningColor.withValues(alpha: 0.9),
                                AppTheme.warningColor.withValues(alpha: 0.6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.warningColor.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Validation requise',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Demandez au client le code secret avant de finaliser la commande.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.lock_outline_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Le code à 4 chiffres est visible uniquement par le client.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.successColor,
                                        AppTheme.successColor.withValues(
                                          alpha: 0.85,
                                        ),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.successColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _showDeliveryValidationSheet(order),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.verified_rounded,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Valider le code de livraison',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final pendingCount = _getOrdersByStatus('pending').length;
    final inProgressCount = _getOrdersByStatus('en cours').length;
    final deliveredCount = _getOrdersByStatus('delivre').length;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Commandes',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: AdminSearchBar(
                hintText: 'Rechercher par client, téléphone ou commande...',
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
                tabs: [
                  Tab(child: _buildTabWithBadge('En attente', pendingCount)),
                  Tab(
                    child: _buildTabWithBadge('En livraison', inProgressCount),
                  ),
                  Tab(child: _buildTabWithBadge('Terminée', deliveredCount)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _bulkExporting
                                ? null
                                : _exportCurrentTabOrders,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: _bulkExporting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf_rounded),
                            label: Text(
                              _bulkExporting
                                  ? 'Export en cours...'
                                  : 'Exporter les commandes',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: _tabStatusKeys
                                .map(_getOrdersByStatus)
                                .map(_buildOrdersList)
                                .toList(),
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

  Widget _buildTabWithBadge(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
