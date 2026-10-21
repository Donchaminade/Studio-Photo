import 'dart:io';

import 'package:Picon/api_service.dart';
import 'package:Picon/login_screen.dart';
import 'package:Picon/models/contact_info.dart';
import 'package:Picon/notifications_screen.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/picon_premium.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Version affichée (synchronisée avec pubspec.yaml).
const String kPiconAppVersion = '1.0.3 (11)';

Widget _tile(IconData icon, String title, String? sub, VoidCallback? onTap, {Color? color, Widget? trailing}) =>
    ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
      subtitle: sub == null ? null : Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary)),
      onTap: onTap,
    );

Widget _group(List<Widget> children) => PiconCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 72, endIndent: 16),
          children[i],
        ],
      ]),
    );

/// Paramètres : notifications, cache local, version, déconnexion.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearCache(BuildContext context) async {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    var files = 0;
    if (!kIsWeb) {
      try {
        final dir = await getTemporaryDirectory();
        // Uniquement les archives photos téléchargées par l'app.
        for (final f in dir.listSync().whereType<File>()) {
          final name = f.uri.pathSegments.last;
          if (name.startsWith('picon_commande_') && name.endsWith('.zip')) {
            await f.delete();
            files++;
          }
        }
      } catch (_) {}
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(files > 0
            ? 'Cache vidé ($files archive${files > 1 ? 's' : ''} supprimée${files > 1 ? 's' : ''}).'
            : 'Cache d’images vidé.'),
      ));
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Déconnexion')),
        ],
      ),
    );
    if (ok != true) return;
    await ApiService.clearAuthDetails();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  void _soon(BuildContext context) => ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Bientôt disponible.')));

  @override
  Widget build(BuildContext context) {
    return PiconHeroScaffold(
      title: 'Paramètres',
      subtitle: 'Votre application PICON',
      icon: Icons.tune_rounded,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _group([
              _tile(Icons.notifications_active_outlined, 'Notifications', 'Vos alertes de commande', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              }),
              _tile(Icons.cleaning_services_outlined, 'Vider le cache', 'Images et archives téléchargées',
                  () => _clearCache(context)),
            ]),
            const SizedBox(height: 14),
            _group([
              _tile(Icons.lock_outline_rounded, 'Changer le mot de passe', 'Bientôt disponible', () => _soon(context)),
              _tile(Icons.person_remove_outlined, 'Supprimer mon compte', 'Bientôt disponible', () => _soon(context)),
            ]),
            const SizedBox(height: 14),
            _group([
              _tile(Icons.info_outline_rounded, 'Version', kPiconAppVersion, null),
              _tile(Icons.logout_rounded, 'Déconnexion', null, () => _logout(context), color: AppColors.error),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// À propos : infos studio (GET /public/contact-info), version, CGU « à venir ».
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late Future<ContactInfo> _future = ApiService.fetchContactInfo();

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _soon() => ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Document à venir.')));

  @override
  Widget build(BuildContext context) {
    return PiconHeroScaffold(
      title: 'À propos',
      subtitle: 'Studio photo PICON',
      icon: Icons.camera_alt_outlined,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PiconCard(
              child: Column(children: const [
                SizedBox(height: 6),
                PiconWordmark(height: 54, vertical: true),
                SizedBox(height: 10),
                Text('Version $kPiconAppVersion', style: TextStyle(color: AppColors.textSecondary)),
                SizedBox(height: 6),
              ]),
            ),
            const SizedBox(height: 14),
            FutureBuilder<ContactInfo>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return SizedBox(
                    height: 220,
                    child: AppInlineError(
                      error: snap.error!,
                      onRetry: () => setState(() => _future = ApiService.fetchContactInfo()),
                    ),
                  );
                }
                final c = snap.data;
                if (c == null) return const PiconSkeleton(height: 220, radius: 20);
                return _group([
                  _tile(Icons.place_outlined, 'Adresse', c.address, null),
                  _tile(Icons.schedule_rounded, 'Horaires', c.openingHours, null),
                  _tile(Icons.call_outlined, 'Téléphone', c.phoneNumber,
                      () => _launch('tel:${c.phoneNumber.split('/').first.replaceAll(' ', '')}')),
                  _tile(Icons.mail_outline_rounded, 'E-mail', c.email, () => _launch('mailto:${c.email}')),
                  if ((c.facebookUrl ?? '').isNotEmpty)
                    _tile(Icons.facebook_rounded, 'Facebook', 'Suivre le studio', () => _launch(c.facebookUrl!)),
                  if ((c.instagramUrl ?? '').isNotEmpty)
                    _tile(Icons.camera_outlined, 'Instagram', 'Suivre le studio', () => _launch(c.instagramUrl!)),
                ]);
              },
            ),
            const SizedBox(height: 14),
            _group([
              _tile(Icons.description_outlined, 'Conditions générales', 'À venir', _soon),
              _tile(Icons.privacy_tip_outlined, 'Politique de confidentialité', 'À venir', _soon),
            ]),
          ]),
        ),
      ),
    );
  }
}
