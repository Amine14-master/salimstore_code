import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/payment_service.dart';

class PaymentConfigPage extends StatefulWidget {
  const PaymentConfigPage({super.key});

  @override
  State<PaymentConfigPage> createState() => _PaymentConfigPageState();
}

class _PaymentConfigPageState extends State<PaymentConfigPage> {
  final TextEditingController _stripeBrandCtrl = TextEditingController(
    text: 'Visa',
  );
  final TextEditingController _stripeLast4Ctrl = TextEditingController();
  final TextEditingController _paypalEmailCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Configurer Paiements')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StripeCardSection(
              brandCtrl: _stripeBrandCtrl,
              last4Ctrl: _stripeLast4Ctrl,
              onSave: () async {
                setState(() => _saving = true);
                await PaymentService.addStripeCard(
                  brand: _stripeBrandCtrl.text.trim(),
                  last4: _stripeLast4Ctrl.text.trim(),
                );
                setState(() => _saving = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Carte Stripe ajoutée')),
                );
              },
              saving: _saving,
            ).animate().slideY(begin: 0.15, duration: 350.ms),
            const SizedBox(height: 12),
            _PayPalSection(
              emailCtrl: _paypalEmailCtrl,
              onSave: () async {
                setState(() => _saving = true);
                await PaymentService.addPayPalEmail(
                  email: _paypalEmailCtrl.text.trim(),
                );
                setState(() => _saving = false);
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('PayPal ajouté')));
              },
              saving: _saving,
            ).animate().slideY(begin: 0.15, duration: 350.ms, delay: 120.ms),
          ],
        ),
      ),
    );
  }
}

class _StripeCardSection extends StatelessWidget {
  final TextEditingController brandCtrl;
  final TextEditingController last4Ctrl;
  final VoidCallback onSave;
  final bool saving;
  const _StripeCardSection({
    required this.brandCtrl,
    required this.last4Ctrl,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: brandCtrl,
            decoration: const InputDecoration(
              labelText: 'Marque (ex: Visa)',
              prefixIcon: Icon(Icons.badge),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: last4Ctrl,
            decoration: const InputDecoration(
              labelText: '4 derniers chiffres',
              prefixIcon: Icon(Icons.numbers),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSave,
              icon: const Icon(Icons.save),
              label: Text(saving ? 'Enregistrement...' : 'Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayPalSection extends StatelessWidget {
  final TextEditingController emailCtrl;
  final VoidCallback onSave;
  final bool saving;
  const _PayPalSection({
    required this.emailCtrl,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Email PayPal',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSave,
              icon: const Icon(Icons.save),
              label: Text(saving ? 'Enregistrement...' : 'Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}












