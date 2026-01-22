import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/utils/geometric_background.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

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
          const GeometricBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildInfoCard(context),
                  const SizedBox(height: 30),
                  Text(
                    'Suivez-nous',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  _buildSocialRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              _ContactInfoTile(
                icon: Icons.location_on_outlined,
                title: 'Notre Studio',
                subtitle: 'Rue de la Photo, Lomé, Togo',
                onTap: () { /* TODO: Open Maps */ },
              ),
              const Divider(height: 1, indent: 20, endIndent: 20, color: Colors.white30),
              _ContactInfoTile(
                icon: Icons.phone_outlined,
                title: 'Téléphone',
                subtitle: '+228 90 00 00 00',
                onTap: () => _launchUrl('tel:+22890000000', context),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20, color: Colors.white30),
              _ContactInfoTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: 'contact@studiophoto.com',
                onTap: () => _launchUrl('mailto:contact@studiophoto.com', context),
              ),
               const Divider(height: 1, indent: 20, endIndent: 20, color: Colors.white30),
              const _ContactInfoTile(
                icon: Icons.access_time,
                title: 'Horaires d\'ouverture',
                subtitle: 'Lundi - Samedi : 09:00 - 18:00',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialRow() {
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
  
  Future<void> _launchUrl(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
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
      leading: Icon(icon, color: AppColors.primary, size: 30),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary) : null,
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
