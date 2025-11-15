import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/payment_service.dart';

class AdminPaymentsSection extends StatefulWidget {
  const AdminPaymentsSection({super.key});

  @override
  State<AdminPaymentsSection> createState() => _AdminPaymentsSectionState();
}

class _AdminPaymentsSectionState extends State<AdminPaymentsSection> {
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












