import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: piconBar('Contactez-nous'),
      body: Stack(
        children: [
          const GeometricBackground(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Reveal(child: _buildInfoCard(context)),
                  const SizedBox(height: 24),
                  Text(
                    'Suivez-nous',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  const Reveal(index: 1, child: _SocialRow()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return PiconCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ContactInfoTile(
            icon: Icons.location_on_outlined,
            title: 'Notre Studio',
            subtitle: 'Rue de la Photo, Lomé, Togo',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _ContactInfoTile(
            icon: Icons.phone_outlined,
            title: 'Téléphone',
            subtitle: '+228 90 00 00 00',
            onTap: () => _launchUrl('tel:+22890000000', context),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _ContactInfoTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'contact@studiophoto.com',
            onTap: () => _launchUrl('mailto:contact@studiophoto.com', context),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          const _ContactInfoTile(
            icon: Icons.access_time,
            title: "Horaires d'ouverture",
            subtitle: 'Lundi - Samedi : 09:00 - 18:00',
          ),
        ],
      ),
    );
  }

  static Future<void> _launchUrl(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir $url')),
      );
    }
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _SocialButton(icon: FontAwesomeIcons.facebook, url: 'https://facebook.com/your-page'),
        _SocialButton(icon: FontAwesomeIcons.twitter, url: 'https://twitter.com/your-handle'),
        _SocialButton(icon: FontAwesomeIcons.instagram, url: 'https://instagram.com/your-profile'),
        _SocialButton(icon: FontAwesomeIcons.linkedin, url: 'https://linkedin.com/in/your-profile'),
      ],
    );
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary) : null,
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
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
      child: TapScale(
        onTap: () => _launchUrl(context),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
          child: Center(
            child: FaIcon(icon, color: AppColors.primary, size: 22),
          ),
        ),
      ),
    );
  }
}
