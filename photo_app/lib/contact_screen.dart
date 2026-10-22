import 'dart:ui';

import 'package:Picon/api_service.dart';
import 'package:Picon/models/contact_info.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late Future<ContactInfo> _contactInfoFuture;

  @override
  void initState() {
    super.initState();
    _contactInfoFuture = ApiService.fetchContactInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Contactez-nous',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Stack(
        children: [
          GeometricBackground(),
          SafeArea(
            child: FutureBuilder<ContactInfo>(
              future: _contactInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      children: [
                        PiconSkeleton(height: 150, radius: 26),
                        SizedBox(height: 18),
                        PiconSkeleton(height: 260, radius: 24),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return AppInlineError(
                    error: snapshot.error!,
                    onRetry: () => setState(() {
                      _contactInfoFuture = ApiService.fetchContactInfo();
                    }),
                  );
                }
                if (snapshot.hasData) {
                  final contactInfo = snapshot.data!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Reveal(child: _buildHero(context, contactInfo)),
                        const SizedBox(height: 18),
                        Reveal(index: 1, child: _buildInfoCard(context, contactInfo)),
                        const SizedBox(height: 30),
                        Text(
                          'Suivez-nous',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 20),
                        _buildSocialRow(contactInfo),
                      ],
                    ),
                  );
                }
                return const Center(
                  child: Text(
                    'Aucune information de contact disponible.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Carte d'en-tête : studio + actions rapides (données réelles du backend).
  Widget _buildHero(BuildContext context, ContactInfo info) {
    final actions = <(IconData, String, VoidCallback)>[
      if (info.phoneNumber.isNotEmpty)
        (Icons.call_rounded, 'Appeler', () => _launchUrl('tel:${info.phoneNumber.split('/').first.trim()}', context)),
      if ((info.whatsappNumber ?? '').isNotEmpty)
        (Icons.chat_rounded, 'WhatsApp', () => _launchUrl('https://wa.me/${info.whatsappNumber!.replaceAll(RegExp(r'[^0-9]'), '')}', context)),
      if (info.email.isNotEmpty)
        (Icons.alternate_email_rounded, 'Email', () => _launchUrl('mailto:${info.email}', context)),
      if (info.address.isNotEmpty)
        (Icons.map_rounded, 'Itinéraire', () => _launchUrl('https://maps.google.com/?q=${info.address}', context)),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
        boxShadow: const [BoxShadow(color: Color(0x330B1A3A), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Studio PICON', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            info.openingHours.isEmpty ? 'Nous sommes à votre écoute' : info.openingHours,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final a in actions)
                Expanded(
                  child: TapScale(
                    onTap: a.$3,
                    tooltip: a.$2,
                    child: Column(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Icon(a.$1, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(a.$2, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ContactInfo info) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _ContactInfoTile(
                icon: Icons.location_on_outlined,
                title: 'Notre Studio',
                subtitle: info.address,
                onTap: info.address.isNotEmpty
                    ? () => _launchUrl(
                        'https://maps.google.com/?q=${info.address}', context)
                    : null,
              ),
              const Divider(
                  height: 1, indent: 20, endIndent: 20, color: AppColors.line),
              _ContactInfoTile(
                icon: Icons.phone_outlined,
                title: 'Téléphone',
                subtitle: info.phoneNumber,
                onTap: info.phoneNumber.isNotEmpty
                    ? () => _launchUrl('tel:${info.phoneNumber}', context)
                    : null,
              ),
              const Divider(
                  height: 1, indent: 20, endIndent: 20, color: AppColors.line),
              _ContactInfoTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: info.email,
                onTap: info.email.isNotEmpty
                    ? () => _launchUrl('mailto:${info.email}', context)
                    : null,
              ),
              const Divider(
                  height: 1, indent: 20, endIndent: 20, color: AppColors.line),
              _ContactInfoTile(
                icon: Icons.access_time,
                title: 'Horaires d\'ouverture',
                subtitle: info.openingHours,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialRow(ContactInfo info) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (info.facebookUrl != null && info.facebookUrl!.isNotEmpty)
          _SocialButton(
              icon: FontAwesomeIcons.facebook, url: info.facebookUrl!),
        if (info.twitterUrl != null && info.twitterUrl!.isNotEmpty)
          _SocialButton(icon: FontAwesomeIcons.twitter, url: info.twitterUrl!),
        if (info.instagramUrl != null && info.instagramUrl!.isNotEmpty)
          _SocialButton(
              icon: FontAwesomeIcons.instagram, url: info.instagramUrl!),
        if (info.linkedinUrl != null && info.linkedinUrl!.isNotEmpty)
          _SocialButton(
              icon: FontAwesomeIcons.linkedin, url: info.linkedinUrl!),
      ],
    );
  }

  Future<void> _launchUrl(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir $url')),
      );
    }
  }
}

class _ContactInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ContactInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios,
              size: 16, color: AppColors.textSecondary)
          : null,
    );
  }
}

class _SocialButton extends StatelessWidget {
  final FaIconData icon;
  final String url;

  const _SocialButton({required this.icon, required this.url});

  Future<void> _launchUrl(BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: url,
      child: InkWell(
        onTap: () => _launchUrl(context),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
          ),
          child: Center(
            child: FaIcon(icon, color: AppColors.primary, size: 28),
          ),
        ),
      ),
    );
  }
}
