import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../firebase_options.dart';

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

class _DeliveryConfirmationSheet extends StatefulWidget {
  const _DeliveryConfirmationSheet({
    required this.code,
    required this.onConfirm,
    required this.onCopy,
  });

  final String code;
  final Future<bool> Function() onConfirm;
  final Future<void> Function() onCopy;

  @override
  State<_DeliveryConfirmationSheet> createState() =>
      _DeliveryConfirmationSheetState();
}

class _DeliveryConfirmationSheetState
    extends State<_DeliveryConfirmationSheet> {
  bool _submitting = false;
  String? _error;

  Future<void> _handleConfirm() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final ok = await widget.onConfirm();
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error = 'Impossible de valider la commande.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 28,
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
                    color: AppTheme.textLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 140,
                  child: Lottie.asset(
                    'lib/assets/animations/category_loader.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Valider la réception',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Partagez ce code avec l\'administrateur pour finaliser la commande.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Shimmer.fromColors(
                  baseColor: AppTheme.primaryColor.withOpacity(0.6),
                  highlightColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                    child: Text(
                      widget.code,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : widget.onCopy,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copier le code'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Plus tard'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.verified_rounded),
                    label: Text(
                      _submitting ? 'Validation...' : 'Confirmer la livraison',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => OrdersTabState();
}

class OrdersTabState extends State<OrdersTab>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _allOrders = [];
  late TabController _tabController;
  StreamSubscription<DatabaseEvent>? _ordersSubscription;
  final Map<String, String> _pendingDeliveryCodes = {};
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
      return const _StatusVisuals(
        color: AppTheme.warningColor,
        label: 'En attente',
        icon: Icons.watch_later_outlined,
        stageIndex: 1,
      );
    }

    if (normalized == 'processing' ||
        normalized == 'en cours' ||
        normalized == 'en cours de livraison' ||
        normalized == 'livraison') {
      return const _StatusVisuals(
        color: AppTheme.accentColor,
        label: 'En livraison',
        icon: Icons.route,
        stageIndex: 2,
      );
    }

    if (normalized == 'awaiting_confirmation' ||
        normalized == 'validation' ||
        normalized == 'client_confirmed') {
      return const _StatusVisuals(
        color: AppTheme.warningColor,
        label: 'Validation requise',
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
        icon: Icons.verified_rounded,
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

  String _resolveOrderId(Map<String, dynamic> order) {
    final dynamic raw = order['orderId'] ?? order['id'];
    if (raw == null) return '';
    return raw.toString();
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
      debugPrint('Client PDF font download failed, fallback to Helvetica: $e');
      return (base: pw.Font.helvetica(), bold: pw.Font.helveticaBold());
    }
  }

  List<pw.Widget> _buildOrderPdfContent(
    Map<String, dynamic> order,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    final orderId = _resolveOrderId(order);
    final customerName =
        (order['customerName'] ?? order['userName'] ?? 'Client').toString();
    final statusVisuals = _resolveStatusVisuals(
      (order['status'] ?? '').toString(),
    );
    final createdAt = _parseOrderDate(order['createdAt']);
    final formattedDate = _formatOrderDate(createdAt);
    final deliveryAddress =
        (order['deliveryAddress'] ?? 'Adresse non spécifiée').toString();
    final phone = (order['phone'] ?? order['phoneNumber'] ?? 'Non fourni')
        .toString();

    final items = _extractOrderItems(order);
    final cartTotal = _safeToDouble(order['cartTotal']);
    final deliveryFee = _safeToDouble(order['deliveryFee']);
    final expressFee = _safeToDouble(order['expressFee']);
    final tip = _safeToDouble(order['tip']);
    final total = _safeToDouble(order['total']);

    String formatCurrency(double value) => '${value.toStringAsFixed(2)} €';

    final itemRows = items.map((item) {
      final productName = (item['productName'] ?? 'Produit').toString();
      final qty = _formatQuantity(item['quantity']);
      final unit = (item['unit'] ?? '').toString();
      final totalPrice = _safeToDouble(
        item['totalPrice'] ?? item['price'] ?? 0,
      );
      return [
        productName,
        unit.isNotEmpty ? '$qty $unit' : qty,
        formatCurrency(totalPrice),
      ];
    }).toList();

    return [
      pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          gradient: const pw.LinearGradient(
            colors: [PdfColors.blue600, PdfColors.deepPurple400],
          ),
          borderRadius: pw.BorderRadius.circular(18),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'SalimStore',
              style: pw.TextStyle(
                fontSize: 26,
                font: boldFont,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Reçu de commande',
              style: pw.TextStyle(fontSize: 16, color: PdfColors.white),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              orderId.isNotEmpty ? 'Commande #$orderId' : 'Commande',
              style: pw.TextStyle(
                fontSize: 18,
                font: boldFont,
                color: PdfColors.white,
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
          border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Informations',
              style: pw.TextStyle(fontSize: 16, font: boldFont),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Client: $customerName'),
            pw.Text('Téléphone: $phone'),
            pw.Text('Adresse: $deliveryAddress'),
            pw.Text('Date: $formattedDate'),
            pw.SizedBox(height: 10),
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
                      color: PdfColor.fromInt(statusVisuals.color.value),
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
        pw.SizedBox(height: 20),
        pw.Text(
          'Articles commandés',
          style: pw.TextStyle(fontSize: 16, font: boldFont),
        ),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['Produit', 'Quantité', 'Montant'],
          data: itemRows,
          headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.blueGrey700,
          ),
          cellAlignment: pw.Alignment.centerLeft,
          columnWidths: {
            0: const pw.FlexColumnWidth(2.6),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1.2),
          },
        ),
      ],
      pw.SizedBox(height: 20),
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(16),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                children: [pw.Text('Pourboire'), pw.Text(formatCurrency(tip))],
              ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total à payer', style: pw.TextStyle(font: boldFont)),
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
        pw.SizedBox(height: 18),
        pw.Text(
          'Notes du client',
          style: pw.TextStyle(fontSize: 14, font: boldFont),
        ),
        pw.SizedBox(height: 6),
        pw.Text(order['notes'].toString()),
      ],
    ];
  }

  Future<Uint8List> _createOrderPdf(Map<String, dynamic> order) async {
    final doc = pw.Document();
    final fonts = await _loadPdfFonts();
    final regularFont = fonts.base;
    final boldFont = fonts.bold;
    final pdfTheme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);
    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        theme: pdfTheme,
        build: (context) => _buildOrderPdfContent(order, regularFont, boldFont),
      ),
    );

    return doc.save();
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
    final normalized = displayLabel.toLowerCase();
    final slug = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final descriptor = slug.isEmpty ? statusKey : slug;
    final filename = 'mes_commandes_${descriptor}_$timestamp.pdf';
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
      final regularFont = fonts.base;
      final boldFont = fonts.bold;
      final pdfTheme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);

      for (final order in orders) {
        doc.addPage(
          pw.MultiPage(
            margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            theme: pdfTheme,
            build: (context) =>
                _buildOrderPdfContent(order, regularFont, boldFont),
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
          'L\'export PDF n\'est pas pris en charge sur cet appareil.',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF exporté (${orders.length} commande${orders.length > 1 ? 's' : ''}).',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export des commandes: $e'),
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

  Future<void> _exportOrderAsPdf(Map<String, dynamic> order) async {
    final orderId = _resolveOrderId(order);
    if (orderId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identifiant de commande introuvable'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    if (_pdfInProgress.contains(orderId)) return;

    setState(() => _pdfInProgress.add(orderId));
    try {
      final pdfBytes = await _createOrderPdf(order);
      final printingInfo = await Printing.info();
      String successMessage;

      if (printingInfo.canShare) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'commande_$orderId.pdf',
        );
        successMessage =
            'PDF généré pour la commande #$orderId et prêt à être partagé.';
      } else if (printingInfo.canPrint || kIsWeb) {
        await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
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
                  : 'Erreur lors de la génération du PDF: $e',
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
    if (rawItems is List) {
      return rawItems
          .where((element) => element is Map)
          .map(
            (element) =>
                Map<String, dynamic>.from(element as Map<dynamic, dynamic>),
          )
          .toList();
    }
    return const [];
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
      {'icon': Icons.shopping_cart_checkout, 'label': 'Validée'},
      {'icon': Icons.kitchen_outlined, 'label': 'Préparation'},
      {'icon': Icons.local_shipping_outlined, 'label': 'En route'},
      {'icon': Icons.home_filled, 'label': 'Livrée'},
    ];

    final clamped = activeStage.clamp(0, stages.length - 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(stages.length, (index) {
        final isReached = index <= clamped;
        final isCurrent = index == clamped;
        final hasLeftConnector = index > 0;
        final hasRightConnector = index < stages.length - 1;

        BoxDecoration _connectorDecoration(bool active) => BoxDecoration(
          gradient: LinearGradient(
            colors: active
                ? [accentColor.withOpacity(0.8), accentColor.withOpacity(0.2)]
                : [
                    AppTheme.textLight.withOpacity(0.4),
                    AppTheme.textLight.withOpacity(0.1),
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
                            ? _connectorDecoration(index - 1 <= clamped)
                            : const BoxDecoration(color: Colors.transparent),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isReached
                            ? accentColor.withOpacity(0.18)
                            : Colors.white,
                        border: Border.all(
                          color: isReached
                              ? accentColor
                              : AppTheme.textLight.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.3),
                                  blurRadius: 16,
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
                            ? _connectorDecoration(index < clamped)
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
                      : AppTheme.textSecondary.withOpacity(0.7),
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
        color: backgroundColor ?? AppTheme.textLight.withOpacity(0.14),
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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealtimeListener() {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _allOrders = [];
        _loading = false;
      });
      return;
    }

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
                if (orderMap['userId'] == user.uid) {
                  orderMap['id'] = orderMap['orderId'] ?? id;
                  found.add(orderMap);
                }
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
        print('Error listening to orders: $error');
        if (mounted) {
          setState(() => _loading = false);
        }
      },
    );
  }

  void refresh() {
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _allOrders = [];
        _loading = false;
      });
      return;
    }
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
      );
      final ref = db.ref('orders');

      // Fetch all orders and filter client-side (no index needed)
      final snap = await ref.get();
      List<Map<String, dynamic>> found = [];

      if (snap.exists) {
        final value = snap.value;
        if (value is Map) {
          // Orders are stored with custom orderId keys
          value.forEach((id, orderData) {
            if (orderData != null && orderData is Map) {
              final orderMap = Map<String, dynamic>.from(orderData);
              // Filter by userId client-side
              if (orderMap['userId'] == user.uid) {
                // Use orderId if available, otherwise use the key
                orderMap['id'] = orderMap['orderId'] ?? id;
                found.add(orderMap);
              }
            }
          });
        } else if (value is List) {
          // Fallback for list format
          for (var item in value) {
            if (item is Map) {
              final orderMap = Map<String, dynamic>.from(item);
              if (orderMap['userId'] == user.uid) {
                found.add(orderMap);
              }
            }
          }
        }

        // Sort by createdAt (newest first)
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
      }

      print('Found ${found.length} orders for user ${user.uid}');
      setState(() {
        _allOrders = found;
        _loading = false;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        _allOrders = [];
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getOrdersByStatus(String status) {
    final filtered = _allOrders.where((order) {
      final orderStatus = (order['status'] ?? 'pending')
          .toString()
          .toLowerCase();
      final searchStatus = status.toLowerCase();

      // Map French status to English
      if (searchStatus == 'en attente') {
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

      // Direct match
      return orderStatus == searchStatus;
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

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildOrderCard(orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final total = (order['total'] ?? 0).toDouble();
    final status = (order['status'] ?? 'pending').toString();
    final visuals = _resolveStatusVisuals(status);
    final date = _parseOrderDate(order['createdAt']);
    final formattedDate = _formatOrderDate(date);
    final items = _extractOrderItems(order);
    final previewItems = items.take(3).toList();
    final remainingItems = items.length - previewItems.length;
    final deliveryAddress =
        (order['deliveryAddress'] ?? 'Adresse non renseignée').toString();
    final contactName =
        (order['customerName'] ??
                order['contactName'] ??
                order['userName'] ??
                'Vous')
            .toString();
    final orderIdValue = order['orderId']?.toString();
    final rawId = order['id']?.toString() ?? '';
    final shortenedId = rawId.length > 6 ? rawId.substring(0, 6) : rawId;
    final orderCode = orderIdValue != null && orderIdValue.isNotEmpty
        ? 'Commande $orderIdValue'
        : 'Commande #${shortenedId.toUpperCase()}';
    final normalizedStatus = status.toLowerCase();
    final awaitingAdminValidation = normalizedStatus == 'awaiting_confirmation';
    final canMarkDelivered =
        (normalizedStatus == 'processing' ||
            normalizedStatus == 'en cours' ||
            normalizedStatus == 'en cours de livraison' ||
            normalizedStatus == 'livraison') &&
        !awaitingAdminValidation;

    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [visuals.color.withOpacity(0.12), Colors.white],
          ),
          border: Border.all(
            color: visuals.color.withOpacity(0.18),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: visuals.color.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -28,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      visuals.color.withOpacity(0.2),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              visuals.color.withOpacity(0.22),
                              visuals.color.withOpacity(0.06),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          visuals.icon,
                          size: 26,
                          color: visuals.color,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildInfoChip(
                                  visuals.icon,
                                  visuals.label,
                                  textColor: Colors.white,
                                  backgroundColor: visuals.color,
                                ),
                                _buildInfoChip(
                                  Icons.person_outline,
                                  contactName,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${total.toStringAsFixed(0)} €',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildStatusTimeline(visuals.stageIndex, visuals.color),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Résumé de commande',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 10),
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
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: visuals.color.withOpacity(0.12),
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
                                  const SizedBox(width: 10),
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
                                        const SizedBox(height: 3),
                                        Text(
                                          quantityLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppTheme.textSecondary,
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
                        Icons.calendar_month_outlined,
                        formattedDate,
                      ),
                      _buildInfoChip(
                        Icons.location_on_outlined,
                        deliveryAddress,
                      ),
                      _buildInfoChip(
                        Icons.shopping_bag_outlined,
                        '${items.length} article(s)',
                      ),
                    ],
                  ),
                  if (awaitingAdminValidation) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.warningColor.withOpacity(0.9),
                            AppTheme.warningColor.withOpacity(0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.warningColor.withOpacity(0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'En attente de validation admin',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Communiquez ce code à l\'administrateur pour finaliser la commande.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Shimmer.fromColors(
                                baseColor: Colors.white,
                                highlightColor: Colors.white.withOpacity(0.4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                  child: Text(
                                    (order['deliveryCode'] ?? '----')
                                        .toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          letterSpacing: 6,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final code =
                                        (order['deliveryCode'] ?? '----')
                                            .toString();
                                    await Clipboard.setData(
                                      ClipboardData(text: code),
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Code copié'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Copier le code'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (canMarkDelivered) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.successColor,
                            AppTheme.successColor.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.successColor.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsDelivered(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          'Marquer comme livré',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
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
  }

  String _generateDeliveryCode() {
    final random = Random.secure();
    final code = random.nextInt(9000) + 1000;
    return code.toString();
  }

  Future<void> _markAsDelivered(Map<String, dynamic> order) async {
    final orderId = (order['orderId'] ?? order['id'] ?? '').toString();
    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande introuvable'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final generatedCode =
        _pendingDeliveryCodes[orderId] ?? _generateDeliveryCode();
    _pendingDeliveryCodes[orderId] = generatedCode;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _DeliveryConfirmationSheet(
          code: generatedCode,
          onCopy: () async {
            await Clipboard.setData(ClipboardData(text: generatedCode));
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Code copié')));
          },
          onConfirm: () async {
            final db = FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
            );
            await db.ref('orders').child(orderId).update({
              'status': 'awaiting_confirmation',
              'deliveryCode': generatedCode,
              'clientConfirmedAt': ServerValue.timestamp,
              'updatedAt': ServerValue.timestamp,
            });
            return true;
          },
        );
      },
    );

    if (result == true && mounted) {
      _pendingDeliveryCodes.remove(orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Code généré ! Partagez-le avec l\'admin pour finaliser la commande.',
          ),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  Future<void> _showOrderDetails(Map<String, dynamic> order) async {
    final items = _extractOrderItems(order);
    final cartTotal = _safeToDouble(order['cartTotal']);
    final deliveryFee = _safeToDouble(order['deliveryFee']);
    final expressFee = _safeToDouble(order['expressFee']);
    final tip = _safeToDouble(order['tip']);
    final total = _safeToDouble(order['total']);
    final deliveryAddress = (order['deliveryAddress'] ?? 'Non spécifiée')
        .toString();
    final createdAt = order['createdAt'];
    DateTime? date;

    if (createdAt != null) {
      if (createdAt is int) {
        date = DateTime.fromMillisecondsSinceEpoch(createdAt);
      } else if (createdAt is String) {
        try {
          date = DateTime.parse(createdAt);
        } catch (_) {}
      }
    }

    final orderId = _resolveOrderId(order);
    final pdfBusy = _pdfInProgress.contains(orderId);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Shimmer.fromColors(
                baseColor: AppTheme.primaryColor,
                highlightColor: AppTheme.primaryColor.withOpacity(0.4),
                child: Text(
                  'Détails de la commande',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Shimmer.fromColors(
                baseColor: AppTheme.accentColor,
                highlightColor: AppTheme.accentColor.withOpacity(0.3),
                child: Text(
                  orderId.isNotEmpty
                      ? 'Commande: #$orderId'
                      : order['id'] != null
                      ? 'Commande: #${order['id']}'
                      : 'Commande',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Produits:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...items.map<Widget>((item) {
                final qty = _formatQuantity(item['quantity']);
                final unit = (item['unit'] ?? '').toString();
                final itemTotal = _safeToDouble(
                  item['totalPrice'] ?? item['price'] ?? 0,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          unit.isNotEmpty
                              ? '${item['productName'] ?? 'Produit'} ($qty $unit)'
                              : '${item['productName'] ?? 'Produit'} ($qty)',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '${itemTotal.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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
                'Total final',
                '${total.toStringAsFixed(2)} €',
                isTotal: true,
              ),
              if (order['deliveryCode'] != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Code de validation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: AppTheme.primaryColor.withOpacity(0.5),
                  highlightColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Text(
                        (order['deliveryCode']).toString(),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (orderId.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2575FC).withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: pdfBusy
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            _exportOrderAsPdf(order);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: pdfBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                    label: Shimmer.fromColors(
                      baseColor: Colors.white,
                      highlightColor: Colors.white.withOpacity(0.7),
                      child: Text(
                        pdfBusy
                            ? 'Export en cours...'
                            : 'Télécharger le reçu PDF',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adresse de livraison:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          deliveryAddress,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (date != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Date: ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final encodedAddress = Uri.encodeComponent(deliveryAddress);
                    final googleMapsUri = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
                    );

                    if (await canLaunchUrl(googleMapsUri)) {
                      await launchUrl(
                        googleMapsUri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Adresse: $deliveryAddress'),
                            backgroundColor: AppTheme.warningColor,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text(
                    'Voir la position sur la carte',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final adminPhone = '213555555555';
                    final uri = Uri.parse('tel:$adminPhone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Impossible d\'ouvrir l\'application téléphone',
                            ),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text(
                    'Appeler le fournisseur',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final pendingCount = _getOrdersByStatus(_tabStatusKeys[0]).length;
    final inProgressCount = _getOrdersByStatus(_tabStatusKeys[1]).length;
    final deliveredCount = _getOrdersByStatus(_tabStatusKeys[2]).length;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mes Commandes',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchOrders,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
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
                  Tab(child: _buildMobileTab('En attente', pendingCount)),
                  Tab(child: _buildMobileTab('En livraison', inProgressCount)),
                  Tab(child: _buildMobileTab('Terminée', deliveredCount)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Content
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
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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
                                : const Icon(Icons.picture_as_pdf_outlined),
                            label: Text(
                              _bulkExporting
                                  ? 'Export en cours...'
                                  : 'Exporter les commandes',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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

  Widget _buildMobileTab(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
