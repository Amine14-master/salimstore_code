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
      "cartTotal": ${subtotal.toStringAsFixed(2)},
      "deliveryFee": ${delivery.toStringAsFixed(2)},
      "expressFee": ${express.toStringAsFixed(2)},
      "tip": ${tipAmount.toStringAsFixed(2)},
      "finalTotal": ${total.toStringAsFixed(2)},
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
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _controller),

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
                    const Color(0xFF0070BA), // PayPal Blue
                    const Color(0xFF003087), // PayPal Dark Blue
                    const Color(0xFF009CDE), // PayPal Light Blue
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Animated PayPal Logo Container
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.payment,
                                size: 70,
                                color: const Color(0xFF0070BA),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Pulsing Progress Indicator
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.2),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 5,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              backgroundColor: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        );
                      },
                      onEnd: () {
                        // Restart animation
                        if (mounted && _showLoadingAnimation) {
                          setState(() {});
                        }
                      },
                    ),

                    const SizedBox(height: 50),

                    // Animated Text
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Column(
                              children: [
                                Text(
                                  'Paiement Sécurisé',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Préparation de votre paiement PayPal...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.95),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Security Badge
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Connexion sécurisée SSL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 3),

                    // Payment Amount Display
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.euro, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Montant: ${widget.finalTotal.toStringAsFixed(2)}€',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

          // Top AppBar with gradient (only shown after loading)
          if (!_showLoadingAnimation)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paiement Sécurisé',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Montant: ${_formatPrice(widget.finalTotal)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Sécurisé',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
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
            ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(2)}€';
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
          builder: (_) => const LivriYESHomePage(initialIndex: 4),
        ),
        (route) => false,
      );
    }
  }
}
