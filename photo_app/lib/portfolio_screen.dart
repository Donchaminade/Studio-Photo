import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/widgets/picon_ui.dart';

class PhotoFormat {
  final String dimension;
  final int price;
  final List<String> images;
  final String title;
  final String description;
  final bool isPopular;

  const PhotoFormat({
    required this.dimension,
    required this.price,
    required this.images,
    required this.title,
    required this.description,
    this.isPopular = false,
  });
}

const List<PhotoFormat> photoFormats = [
  PhotoFormat(dimension: '9x13 cm', price: 75, images: ['assets/carousel/car.jpg', 'assets/carousel/car1.jpg'], title: 'Petit Format Classique', description: 'Idéal pour les albums photos ou les petits cadres. Un souvenir intime et abordable.'),
  PhotoFormat(dimension: '10x15 cm', price: 150, images: ['assets/carousel/car1.jpg', 'assets/carousel/mxx.jpeg', 'assets/carousel/pflex.jpeg'], title: 'Format Standard', description: 'Le format le plus courant pour partager vos moments. Parfait pour les tirages du quotidien.', isPopular: true),
  PhotoFormat(dimension: '13x18 cm', price: 125, images: ['assets/carousel/mxx.jpeg', 'assets/carousel/pflex.jpeg'], title: 'Portrait Élégant', description: 'Un choix populaire pour les portraits et les photos de famille. Offre une belle présence.', isPopular: true),
  PhotoFormat(dimension: '15x21 cm', price: 175, images: ['assets/carousel/pflex.jpeg', 'assets/carousel/Pink Modern Pink October Instagram Post .png'], title: 'Polyvalent et Pratique', description: 'Excellent pour la plupart des photos, offre un bon équilibre entre taille et détail.'),
  PhotoFormat(dimension: '20x25 cm', price: 375, images: ['assets/carousel/Pink Modern Pink October Instagram Post .png', 'assets/carousel/Ajouter un sous-titre.png'], title: 'Agrandissement Modéré', description: 'Mettez en valeur vos clichés préférés. Idéal pour les petits cadres muraux.', isPopular: true),
  PhotoFormat(dimension: '20x30 cm', price: 500, images: ['assets/carousel/Ajouter un sous-titre.png', 'assets/images/pro.png', 'assets/logos/mixbyyass.jpg'], title: 'Format A4 Photo', description: 'Le format classique pour une reproduction fidèle. Idéal pour les présentations ou cadres.'),
  PhotoFormat(dimension: '24x30 cm', price: 750, images: ['assets/images/pro.png', 'assets/logos/mixbyyass.jpg'], title: 'Grand Format Équilibré', description: 'Une taille imposante sans être démesurée. Pour un impact visuel certain.'),
  PhotoFormat(dimension: '30x40 cm', price: 1250, images: ['assets/logos/mixbyyass.jpg', 'assets/carousel/car.jpg', 'assets/carousel/car1.jpg'], title: 'Galerie d\'Art', description: 'Transformez vos photos en œuvres d\'art. Un choix audacieux et expressif.', isPopular: true),
  PhotoFormat(dimension: '30x45 cm', price: 1500, images: ['assets/carousel/car.jpg', 'assets/carousel/car1.jpg'], title: 'Panorama Standard', description: 'Parfait pour les paysages ou les photos de groupe. Un champ de vision étendu.'),
  PhotoFormat(dimension: '30x90 cm', price: 2000, images: ['assets/carousel/car1.jpg', 'assets/carousel/mxx.jpeg'], title: 'Bandeau Panoramique', description: 'Pour des vues panoramiques spectaculaires. Créez un point focal unique.'),
  PhotoFormat(dimension: '40x50 cm', price: 2500, images: ['assets/carousel/mxx.jpeg', 'assets/carousel/pflex.jpeg'], title: 'Affichage Mural', description: 'Impression grand format pour décorer un mur. Une présence forte et élégante.'),
  PhotoFormat(dimension: '40x60 cm', price: 3250, images: ['assets/carousel/pflex.jpeg', 'assets/carousel/Pink Modern Pink October Instagram Post .png'], title: 'Impact Visuel Fort', description: 'Le choix des professionnels pour les expositions. Une clarté et un détail exceptionnels.'),
  PhotoFormat(dimension: '50x60 cm', price: 3750, images: ['assets/carousel/Pink Modern Pink October Instagram Post .png', 'assets/carousel/Ajouter un sous-titre.png'], title: 'Très Grand Format', description: 'Pour immortaliser vos plus beaux souvenirs avec grandeur. Effet "wow" garanti.'),
  PhotoFormat(dimension: '60x90 cm', price: 4500, images: ['assets/carousel/Ajouter un sous-titre.png', 'assets/images/pro.png'], title: 'Poster Géant', description: 'La taille idéale pour les posters ou les affiches promotionnelles. Attire tous les regards.'),
  PhotoFormat(dimension: '60x120 cm', price: 6250, images: ['assets/images/pro.png', 'assets/logos/mixbyyass.jpg'], title: 'Immersion Maximale', description: 'La plus grande taille disponible pour une immersion totale. Une déclaration artistique.'),
];

final NumberFormat currencyFormatter =
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final PageController _page = PageController(viewportFraction: 0.86);
  int _index = 0;

  void _openDetails(PhotoFormat format) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => DimensionDetailDialog(format: format),
    );
  }

  void _go(int index) {
    if (reduceMotion(context)) {
      _page.jumpToPage(index);
    } else {
      _page.animateToPage(index, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final format = photoFormats[_index];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navyDeep,
        appBar: piconBar('Guide des Dimensions', dark: true),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Galerie',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${_index + 1} / ${photoFormats.length}',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  itemCount: photoFormats.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, index) {
                    final item = photoFormats[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: _GlassFormatCard(
                        format: item,
                        onTap: () => _openDetails(item),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Précédent',
                      onPressed: _index == 0 ? null : () => _go(_index - 1),
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        format.dimension,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Suivant',
                      onPressed: _index == photoFormats.length - 1 ? null : () => _go(_index + 1),
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 78,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemExtent: 76,
                  itemCount: photoFormats.length,
                  itemBuilder: (context, index) {
                    final active = index == _index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _go(index),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active ? AppColors.accent : Colors.white24,
                              width: active ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              photoFormats[index].images.first,
                              width: 64,
                              height: 56,
                              fit: BoxFit.cover,
                              cacheWidth: 180,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 64,
                                height: 56,
                                child: Icon(Icons.image_not_supported, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassFormatCard extends StatelessWidget {
  final PhotoFormat format;
  final VoidCallback onTap;

  const _GlassFormatCard({required this.format, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.asset(
                  format.images.first,
                  fit: BoxFit.cover,
                  cacheWidth: 900,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.white54, size: 42),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            format.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ),
                        if (format.isPopular) const _PopularBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      format.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            format.dimension,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            currencyFormatter.format(format.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DimensionTile extends StatelessWidget {
  final PhotoFormat format;

  const DimensionTile({super.key, required this.format});

  @override
  Widget build(BuildContext context) {
    return _GlassFormatCard(format: format, onTap: () {});
  }
}

class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Populaire',
        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class DimensionDetailDialog extends StatefulWidget {
  final PhotoFormat format;

  const DimensionDetailDialog({super.key, required this.format});

  @override
  State<DimensionDetailDialog> createState() => _DimensionDetailDialogState();
}

class _DimensionDetailDialogState extends State<DimensionDetailDialog> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: const Color(0xF0101830),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 280,
                        viewportFraction: 1,
                        enableInfiniteScroll: widget.format.images.length > 1,
                        onPageChanged: (i, _) => setState(() => currentIndex = i),
                      ),
                      items: widget.format.images.map((img) {
                        return Image.asset(
                          img,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          cacheWidth: 1000,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white),
                        );
                      }).toList(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        tooltip: 'Fermer',
                        onPressed: () => Navigator.pop(context),
                        icon: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.close, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.format.images.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.format.images.length, (i) {
                        final active = i == currentIndex;
                        return Container(
                          width: active ? 16 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: active ? AppColors.accent : Colors.white24,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.format.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.format.description, style: const TextStyle(color: Colors.white70, height: 1.35)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(widget.format.dimension, style: const TextStyle(fontSize: 18, color: Colors.white)),
                          const Spacer(),
                          Text(
                            currencyFormatter.format(widget.format.price),
                            style: const TextStyle(fontSize: 18, color: AppColors.accent, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
