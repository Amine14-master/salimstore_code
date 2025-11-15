import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/contact_support_config.dart';
import '../../theme/app_theme.dart';
// Removed inline payments section; use dedicated config page instead
import '../payment_config_page.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: isDesktop ? 200 : 180,
              backgroundColor: AppTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: _ProfileHeader().animate().fadeIn(duration: 400.ms),
                title: const Text(
                  'Profil',
                  style: TextStyle(color: Colors.white),
                ),
                centerTitle: false,
              ),
              actions: [
                IconButton(
                  onPressed: () async => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Se Déconnecter',
                ),
              ],
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 40 : 16,
                16,
                isDesktop ? 40 : 16,
                8,
              ),
              sliver: SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 800 : double.infinity,
                  ),
                  child: _EditableInfoSection().animate().slideY(
                    begin: 0.15,
                    duration: 350.ms,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 16,
                vertical: 8,
              ),
              sliver: SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 800 : double.infinity,
                  ),
                  child: _SupportContactSection(isDesktop: isDesktop),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 16,
                vertical: 8,
              ),
              sliver: SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 800 : double.infinity,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentConfigPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune),
                      label: const Text('Configurer mes paiements'),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 40 : 16,
                8,
                isDesktop ? 40 : 16,
                24,
              ),
              sliver: SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 800 : double.infinity,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async => FirebaseAuth.instance.signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Se Déconnecter'),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportContactSection extends StatefulWidget {
  const _SupportContactSection({required this.isDesktop});

  final bool isDesktop;

  @override
  State<_SupportContactSection> createState() => _SupportContactSectionState();
}

class _SupportContactSectionState extends State<_SupportContactSection> {
  final TextEditingController _messageCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSendPressed() async {
    FocusScope.of(context).unfocus();
    final message = _messageCtrl.text.trim();
    final uri = Uri(
      scheme: 'mailto',
      path: ContactSupportConfig.supportEmail,
      queryParameters: {
        'subject': 'Assistance SalimStore',
        if (message.isNotEmpty) 'body': message,
      },
    );

    setState(() => _sending = true);
    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;

      if (success) {
        _messageCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre messagerie s\'ouvre pour rédiger le message.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application mail.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ouverture du mail: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _copyEmail() async {
    await Clipboard.setData(
      ClipboardData(text: ContactSupportConfig.supportEmail),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Adresse email copiée')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final animationWidget = DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFD8E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Lottie.network(
          'https://assets10.lottiefiles.com/packages/lf20_t24tpvcu.json',
          height: widget.isDesktop ? 220 : 180,
          frameRate: FrameRate.max,
          repeat: true,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.support_agent,
            size: 72,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support & assistance',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Besoin d\'aide ? Notre équipe répond rapidement à vos questions et vous accompagne dans la gestion de votre boutique.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        Shimmer.fromColors(
          baseColor: AppTheme.primaryColor.withOpacity(0.85),
          highlightColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.alternate_email, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  ContactSupportConfig.supportEmail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Décrivez votre demande',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageCtrl,
          maxLines: 4,
          minLines: 3,
          decoration: const InputDecoration(
            hintText: 'Comment pouvons-nous vous aider ?',
            prefixIcon: Icon(Icons.edit_note_rounded),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _sending ? null : _onSendPressed,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_sending ? 'Ouverture...' : 'Envoyer un email'),
            ),
            OutlinedButton.icon(
              onPressed: _copyEmail,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copier l\'adresse'),
            ),
          ],
        ),
      ],
    );

    final cardChild = widget.isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: content),
              const SizedBox(width: 28),
              SizedBox(width: 220, child: animationWidget),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [animationWidget, const SizedBox(height: 20), content],
          );

    return CustomCard(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isDesktop ? 30 : 20,
        vertical: widget.isDesktop ? 28 : 22,
      ),
      child: cardChild,
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.12);
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Admin';
    final email = user?.email ?? 'admin@demo.com';
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 34,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Administrateur',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 120.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableInfoSection extends StatefulWidget {
  @override
  State<_EditableInfoSection> createState() => _EditableInfoSectionState();
}

class _EditableInfoSectionState extends State<_EditableInfoSection> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = u?.displayName ?? 'Admin';
    _emailCtrl.text = u?.email ?? 'admin@demo.com';
    _phoneCtrl.text = u?.phoneNumber ?? '+213 555 55 55 55';
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Informations du compte',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _editing = !_editing),
                icon: Icon(_editing ? Icons.check_rounded : Icons.edit),
                color: AppTheme.primaryColor,
                tooltip: _editing ? 'Terminer' : 'Modifier',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildField('Nom', Icons.badge_rounded, _nameCtrl, enabled: _editing),
          const SizedBox(height: 10),
          _buildField(
            'Email',
            Icons.email_rounded,
            _emailCtrl,
            enabled: _editing,
          ),
          const SizedBox(height: 10),
          _buildField(
            'Téléphone',
            Icons.phone_rounded,
            _phoneCtrl,
            enabled: _editing,
          ),
          const SizedBox(height: 4),
          Text(
            _editing
                ? 'Les modifications ne sont pas encore enregistrées.'
                : 'Les informations sont d\'exemple (non enregistrées).',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool enabled = false,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
