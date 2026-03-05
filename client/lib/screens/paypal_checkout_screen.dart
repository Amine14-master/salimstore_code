import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';
import '../services/cart_service.dart';
import 'home_page.dart';

class PayPalCheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double cartTotal;
  final double deliveryFee;
  final double expressFee;
  final double tip;
  final double finalTotal;
  final String deliveryAddress;
  final String? deliveryLabel;
  final String wilaya;
  final String? wilayaCode;
  final String? receiverName;
  final String? receiverPhone;
  final String? userId;

  const PayPalCheckoutScreen({
    super.key,
    required this.cartItems,
    required this.cartTotal,
    required this.deliveryFee,
    required this.expressFee,
    required this.tip,
    required this.finalTotal,
    required this.deliveryAddress,
    this.deliveryLabel,
    required this.wilaya,
    this.wilayaCode,
    this.receiverName,
    this.receiverPhone,
    this.userId,
  });

  @override
  State<PayPalCheckoutScreen> createState() => _PayPalCheckoutScreenState();
}

class _PayPalCheckoutScreenState extends State<PayPalCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _showLoadingAnimation = true;

  @override
  void initState() {
    super.initState();
    // Initialize controller synchronously first
    _controller = WebViewController();

    // setJavaScriptMode, setBackgroundColor and enableZoom might not be supported on Web
    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      _controller.setBackgroundColor(Colors.white);
      _controller.enableZoom(true);
    }

    // Then configure it asynchronously
    _initializeWebView();
  }

  void _initializeWebView() async {
    try {
      // Load both HTML and JS files
      final String htmlContent = await rootBundle.loadString(
        'assets/html/paypal_checkout.html',
      );
      final String jsContent = await rootBundle.loadString(
        'assets/html/paypal_checkout.js',
      );

      // Replace the script src with inline script containing the JS code
      final String modifiedHtml = htmlContent.replaceFirst(
        '<script src="paypal_checkout.js"></script>',
        '<script>$jsContent</script>',
      );

      // Configure the controller
      if (!kIsWeb) {
        await _controller.addJavaScriptChannel(
          'PayPalSuccess',
          onMessageReceived: (JavaScriptMessage message) {
            _handlePaymentSuccess(message.message);
          },
        );

        await _controller.addJavaScriptChannel(
          'PayPalCancel',
          onMessageReceived: (JavaScriptMessage message) {
            debugPrint('Payment cancelled by user');
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        );

        await _controller.setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }

              // Handle Web payment success via URL interception (only works if NavigationDelegate is supported)
              if (url.contains('/payment-success') &&
                  url.contains('orderId=')) {
                final uri = Uri.parse(url);
                final orderId = uri.queryParameters['orderId'];
                if (orderId != null) {
                  _handlePaymentSuccess(orderId);
                }
              }
            },
            onPageFinished: (String url) {
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _showLoadingAnimation = false;
                  });
                }
              });
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView error: ${error.description}');
            },
          ),
        );

        // Android-specific configuration
        if (_controller.platform is AndroidWebViewController) {
          AndroidWebViewController.enableDebugging(true);
          final androidController =
              _controller.platform as AndroidWebViewController;
          androidController.setMediaPlaybackRequiresUserGesture(false);
        }
      } else {
        // Fallback for Web: Hide loading after a short delay since we can't detect onPageFinished
        // and NavigationDelegate is not supported
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _showLoadingAnimation = false;
            });
          }
        });
      }

      // Use your hosted backend as the base (https) to avoid mixed-content issues
      const String baseUrl = 'https://salimstore.onrender.com';

      // Prepare cart data for PayPal
      final cartData = _prepareCartData();

      // Inject cart data into HTML
      final htmlWithData = modifiedHtml.replaceFirst(
        '<!-- CART_DATA_PLACEHOLDER -->',
        '<script>window.cartData = $cartData;</script>',
      );

      await _controller.loadHtmlString(htmlWithData, baseUrl: baseUrl);
    } catch (e) {
      debugPrint('Error initializing WebView: $e');
      if (mounted) {
        setState(() {
          _showLoadingAnimation = false;
        });
      }
    }
  }

  String _prepareCartData() {
    // Prepare cart items with complete product information
    final itemsJson = widget.cartItems
        .map(
          (item) => {
            'id': item.id,
            'productId': item.productId,
            'name': item.productName,
            'quantity': item.quantity,
            'unit': item.unit,
            'price': item.unitPrice,
            'totalPrice': item.totalPrice,
            if (item.originalPrice != null) 'originalPrice': item.originalPrice,
            if (item.discountPercentage != null)
              'discountPercentage': item.discountPercentage,
          },
        )
        .toList();

    // Calculate totals including tip
    final subtotal = widget.cartTotal;
    final delivery = widget.deliveryFee;
    final express = widget.expressFee;
    final tipAmount = widget.tip;
    final total = widget.finalTotal;

    // Get userId from widget or Firebase Auth
    final userId =
        widget.userId ??
        firebase_auth.FirebaseAuth.instance.currentUser?.uid ??
        '';

    return '''{
      "userId": "${userId.replaceAll('"', '\\"')}",
      "items": ${_jsonEncode(itemsJson)},
      "cartTotal": ${subtotal.toString()},
      "deliveryFee": ${delivery.toString()},
      "expressFee": ${express.toString()},
      "tip": ${tipAmount.toString()},
      "finalTotal": ${total.toString()},
      "deliveryAddress": "${widget.deliveryAddress.replaceAll('"', '\\"')}",
      "deliveryLabel": "${widget.deliveryLabel?.replaceAll('"', '\\"') ?? ''}",
      "wilaya": "${widget.wilayaCode ?? '06'}",
      "receiverName": "${widget.receiverName?.replaceAll('"', '\\"') ?? ''}",
      "receiverPhone": "${widget.receiverPhone?.replaceAll('"', '\\"') ?? ''}"
    }''';
  }

  String _jsonEncode(dynamic obj) {
    if (obj is String) {
      return '"${obj.replaceAll('"', '\\"')}"';
    } else if (obj is num) {
      return obj.toString();
    } else if (obj is bool) {
      return obj.toString();
    } else if (obj is List) {
      return '[${obj.map(_jsonEncode).join(',')}]';
    } else if (obj is Map) {
      final entries = obj.entries
          .map((e) => '"${e.key}":${_jsonEncode(e.value)}')
          .join(',');
      return '{$entries}';
    }
    return 'null';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content: Header + WebView
          Column(
            children: [
              // Top AppBar with gradient (only shown after loading)
              if (!_showLoadingAnimation)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        const Color(0xFF0C8A25), // Slightly darker green
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Paiement Sécurisé',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Montant à régler: ${_formatPrice(widget.finalTotal)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Sécurisé',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // WebView occupies the rest of the space
              Expanded(child: WebViewWidget(controller: _controller)),
            ],
          ),

          // Beautiful Fullscreen Loading Overlay
          if (_showLoadingAnimation)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    const Color(0xFF0C8A25),
                    const Color(0xFF056619),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Animated Icon Container
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 60,
                                color: Color(0xFF10AA2E),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 50),

                    // Pulsing Progress Indicator
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Animated Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          const Text(
                            'Paiement Sécurisé',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Initialisation de la transaction PayPal...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Amount Info
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Montant: ${widget.finalTotal.toStringAsFixed(2)}€',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toString()}€';
  }

  void _handlePaymentSuccess(String message) {
    try {
      // Parse the message (should be JSON with orderId)
      final data = message.isNotEmpty ? message : '{}';
      debugPrint('Payment success data: $data');

      // Clear cart immediately
      _clearCart();

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('Commande Réussie!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Votre paiement a été traité avec succès.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Numéro de commande:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vous serez redirigé vers vos commandes dans quelques secondes...',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _redirectToOrders();
                  },
                  child: const Text('Voir mes commandes'),
                ),
              ],
            );
          },
        );

        // Auto-redirect after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pop(); // Close dialog
            _redirectToOrders();
          }
        });
      }
    } catch (e) {
      debugPrint('Error handling payment success: $e');
    }
  }

  Future<void> _clearCart() async {
    try {
      await CartService.clearCart();
      debugPrint('Cart cleared successfully');
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
  }

  void _redirectToOrders() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LivriyesHomePage(initialIndex: 4),
        ),
        (route) => false,
      );
    }
  }
}
