import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/payment_service.dart';

class PaymentConfigPage extends StatefulWidget {
  const PaymentConfigPage({super.key});

  @override
  State<PaymentConfigPage> createState() => _PaymentConfigPageState();
}

class _PaymentConfigPageState extends State<PaymentConfigPage> {
  final TextEditingController _stripeAccountIdCtrl = TextEditingController();
  final TextEditingController _stripePubKeyCtrl = TextEditingController();
  final TextEditingController _paypalMerchantIdCtrl = TextEditingController();
  final TextEditingController _paypalEmailCtrl = TextEditingController();
  bool _loading = true;

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
        setState(() => _loading = false);
        return;
      }
      final pub = await AdminPaymentService.getPublicInfo();
      if (!mounted) return;
      setState(() {
        _stripeAccountIdCtrl.text = pub['stripeAccountId'] ?? '';
        _stripePubKeyCtrl.text = pub['stripePublishableKey'] ?? '';
        _paypalMerchantIdCtrl.text = pub['paypalMerchantId'] ?? '';
        _paypalEmailCtrl.text = pub['paypalEmail'] ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    await AdminPaymentService.savePublicInfo(
      stripeAccountId: _stripeAccountIdCtrl.text.trim().isEmpty
          ? null
          : _stripeAccountIdCtrl.text.trim(),
      stripePublishableKey: _stripePubKeyCtrl.text.trim().isEmpty
          ? null
          : _stripePubKeyCtrl.text.trim(),
      paypalMerchantId: _paypalMerchantIdCtrl.text.trim().isEmpty
          ? null
          : _paypalMerchantIdCtrl.text.trim(),
      paypalEmail: _paypalEmailCtrl.text.trim().isEmpty
          ? null
          : _paypalEmailCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Informations enregistrées')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 160,
              backgroundColor: AppTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        child: Row(
                          children: const [
                            Icon(Icons.payments, color: Colors.white, size: 28),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Configurer les Paiements',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                title: const Text(
                  'Paiements',
                  style: TextStyle(color: Colors.white),
                ),
                centerTitle: false,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.credit_card,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Stripe',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
                                    labelText:
                                        'Stripe Publishable Key (pk_...)',
                                    prefixIcon: Icon(Icons.vpn_key),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().slideY(begin: 0.15, duration: 350.ms),
                          CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet,
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'PayPal',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
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
                              ],
                            ),
                          ).animate().slideY(
                            begin: 0.15,
                            duration: 350.ms,
                            delay: 100.ms,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _save,
                                  icon: const Icon(Icons.save),
                                  label: const Text('Enregistrer'),
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.2),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}












