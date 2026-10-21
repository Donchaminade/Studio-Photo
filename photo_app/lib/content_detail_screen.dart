import 'package:Picon/api_service.dart';
import 'package:Picon/models/featured_content.dart';
import 'package:Picon/models/promotion.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/auth_network_image.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Détail d'une promotion (GET /promotions/{id}) ou d'un contenu à la une
/// (GET /featured-content/{id}). Données 100 % API, lecture seule.
class ContentDetailScreen extends StatefulWidget {
  final int id;
  final bool isPromotion;
  final String? initialTitle;
  final String? initialImageUrl;

  const ContentDetailScreen.promotion({super.key, required this.id, this.initialTitle, this.initialImageUrl})
      : isPromotion = true;
  const ContentDetailScreen.featured({super.key, required this.id, this.initialTitle, this.initialImageUrl})
      : isPromotion = false;

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _Detail {
  final String title;
  final String imageUrl;
  final String? actionLabel;
  final String? actionUrl;
  final bool active;
  final DateTime createdAt;
  const _Detail(this.title, this.imageUrl, this.actionLabel, this.actionUrl, this.active, this.createdAt);
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  late Future<_Detail> _future = _load();

  Future<_Detail> _load() async {
    if (widget.isPromotion) {
      final Promotion p = await ApiService.fetchPromotionById(widget.id);
      return _Detail(p.title, p.imageUrl, 'En profiter', p.targetUrl, p.active, p.createdAt);
    }
    final FeaturedContent f = await ApiService.fetchFeaturedContentById(widget.id);
    return _Detail(f.title, f.imageUrl, f.buttonText, f.buttonAction, f.active, f.createdAt);
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Lien indisponible pour le moment.")));
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _hero(String url) => AuthNetworkImage(
        ApiService.getFullImageUrl(url),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorWidget: const ColoredBox(
          color: AppColors.primary,
          child: Center(child: PiconMark(size: 72)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final kind = widget.isPromotion ? 'Promotion' : 'À la une';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<_Detail>(
        future: _future,
        builder: (context, snap) {
          final d = snap.data;
          final title = d?.title ?? widget.initialTitle ?? kind;
          final image = d?.imageUrl ?? widget.initialImageUrl;
          return CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              leading: const Padding(padding: EdgeInsets.all(6), child: PiconBackButton(dark: true)),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  if (image != null && image.isNotEmpty)
                    _hero(image)
                  else
                    const ColoredBox(color: AppColors.primary, child: Center(child: PiconMark(size: 72))),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x55000000), Colors.transparent, Color(0xCC071433)],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                child: snap.hasError
                    ? SizedBox(
                        height: 470,
                        child: AppInlineError(
                          error: snap.error!,
                          onRetry: () => setState(() => _future = _load()),
                        ),
                      )
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(kind,
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                          const Spacer(),
                          if (d != null)
                            Text(DateFormat('dd/MM/yyyy').format(d.createdAt),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                        ]),
                        const SizedBox(height: 12),
                        Text(title,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                        const SizedBox(height: 18),
                        if (d == null)
                          const PiconSkeleton(height: 52, radius: 16)
                        else if ((d.actionUrl ?? '').isNotEmpty)
                          PiconButton(
                            label: (d.actionLabel ?? '').isNotEmpty ? d.actionLabel! : 'Découvrir',
                            icon: Icons.open_in_new_rounded,
                            onPressed: () => _open(d.actionUrl!),
                          )
                        else
                          const Text('Aucun lien associé à ce contenu.',
                              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                        if (d != null && !d.active) ...[
                          const SizedBox(height: 10),
                          const Text('Ce contenu n’est plus actif.',
                              textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
                        ],
                      ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
