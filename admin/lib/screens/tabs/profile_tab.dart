import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Future<void> _callSupport() async {
    final uri = Uri(
      scheme: 'tel',
      path: '+213${ContactSupportConfig.supportPhone.replaceFirst('0', '')}',
    );
    final ok = await launchUrl(uri);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir l\'application téléphone.'),
        ),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/213${ContactSupportConfig.supportWhatsApp.replaceFirst('0', '')}',
    );
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir WhatsApp.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F4FF), Color(0xFFE8F5FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Support & Assistance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nous sommes là pour vous aider',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Contact Methods Grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _ContactMethodCard(
                icon: Icons.phone_rounded,
                label: 'Appeler',
                color: const Color(0xFF4CAF50),
                onTap: _callSupport,
              ),
              _ContactMethodCard(
                icon: Icons.email_rounded,
                label: 'Email',
                color: const Color(0xFF2196F3),
                onTap: () async {
                  final uri = ContactSupportConfig.buildSupportEmailUri();
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              _ContactMethodCard(
                icon: Icons.chat_bubble_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: _openWhatsApp,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Email Display with Shimmer
          Shimmer.fromColors(
            baseColor: AppTheme.primaryColor.withOpacity(0.6),
            highlightColor: Colors.white,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ContactSupportConfig.supportEmail,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15);
  }
}

class _ContactMethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactMethodCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFAFCFF), Color(0xFFF0F8FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Informations du compte',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: _editing
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => setState(() => _editing = !_editing),
                  icon: Icon(
                    _editing ? Icons.check_rounded : Icons.edit_rounded,
                    color: _editing ? Colors.white : AppTheme.primaryColor,
                  ),
                  tooltip: _editing ? 'Terminer' : 'Modifier',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildField('Nom complet', Icons.person_rounded, _nameCtrl,
              enabled: _editing),
          const SizedBox(height: 16),
          _buildField('Adresse email', Icons.email_rounded, _emailCtrl,
              enabled: _editing),
          const SizedBox(height: 16),
          _buildField('Téléphone', Icons.phone_rounded, _phoneCtrl,
              enabled: _editing),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _editing
                  ? const Color(0xFFFFF3CD)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _editing
                    ? const Color(0xFFFFD700).withOpacity(0.3)
                    : const Color(0xFF4CAF50).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _editing ? Icons.info_rounded : Icons.check_circle_rounded,
                  color: _editing
                      ? const Color(0xFFFFA500)
                      : const Color(0xFF4CAF50),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _editing
                        ? 'Les modifications ne sont pas encore enregistrées.'
                        : 'Les informations sont d\'exemple (non enregistrées).',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15);
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool enabled = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? AppTheme.primaryColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: enabled ? AppTheme.primaryColor : Colors.grey,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: TextStyle(
            color: enabled ? AppTheme.primaryColor : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
