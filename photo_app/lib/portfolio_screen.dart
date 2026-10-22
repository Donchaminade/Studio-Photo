import 'dart:ui';
import 'package:Picon/api_service.dart';
import 'package:Picon/models/photo_format.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';



final NumberFormat currencyFormatter =
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

/// ===============================
/// SCREEN
/// ===============================
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late Future<List<PhotoFormat>> _dimensionsFuture;

  @override
  void initState() {
    super.initState();
    _dimensionsFuture = ApiService.fetchDimensions();
  }

  void _openDetails(BuildContext context, PhotoFormat format) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => DimensionDetailDialog(format: format),
    );
  }

  Future<void> _refreshDimensions() async {
    setState(() {
      _dimensionsFuture = ApiService.fetchDimensions();
    });
    await _dimensionsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.navyDeep,
      appBar: AppBar(
        title: const Text('Guide des Dimensions'),
        
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const ColoredBox(color: AppColors.navyDeep, child: SizedBox.expand()),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshDimensions,
              color: AppColors.primary,
              child: FutureBuilder<List<PhotoFormat>>(
              future: _dimensionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(48, 24, 48, 120),
                    child: PiconSkeleton(height: double.infinity, radius: 28, dark: true),
                  );
                } else if (snapshot.hasError) {
                  return AppInlineError(error: snapshot.error!, onRetry: _refreshDimensions);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 200),
                          Center(
                            child: PiconEmpty(
                              icon: Icons.photo_size_select_large_outlined,
                              title: 'Aucune dimension trouvée.',
                              subtitle: 'Les formats du studio apparaîtront ici.',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                final photoFormats = snapshot.data!;
                  return _FormatGallery(
                    formats: photoFormats,
                    onOpen: (format) => _openDetails(context, format),
                  );
                  // Grille d'origine, conservée comme vue alternative.
                  // ignore: dead_code
                  return GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: photoFormats.length,
                  itemBuilder: (context, index) {
                    final format = photoFormats[index];
                    return GestureDetector(
                      onTap: () => _openDetails(context, format),
                      child: DimensionTile(format: format),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
}

/// ===============================
/// TILE
/// ===============================
class DimensionTile extends StatelessWidget {
  final PhotoFormat format;

  const DimensionTile({super.key, required this.format});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: format.images.isEmpty ? '' : ApiService.getFullImageUrl(format.images.first),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: 480,
            placeholder: (context, url) => const PiconSkeleton(height: double.infinity, radius: 0),
            errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
          ),
          _TileInfo(format: format),
          if (format.isPopular) const _PopularBadge(),
        ],
      ),
    );
  }
}

class _TileInfo extends StatelessWidget {
  final PhotoFormat format;

  const _TileInfo({required this.format});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.black.withOpacity(0.45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    format.dimension,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currencyFormatter.format(format.price),
                    style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600),
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

class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Populaire',
          style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// ===============================
/// DETAIL DIALOG
/// ===============================
class DimensionDetailDialog extends StatefulWidget {
  final PhotoFormat format;

  const DimensionDetailDialog({super.key, required this.format});

  @override
  State<DimensionDetailDialog> createState() =>
      _DimensionDetailDialogState();
}

class _DimensionDetailDialogState extends State<DimensionDetailDialog> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 300,
                        viewportFraction: 1,
                        onPageChanged: (i, _) =>
                            setState(() => currentIndex = i),
                      ),
                      items: widget.format.images.map((img) {
                        return CachedNetworkImage(
                          imageUrl: ApiService.getFullImageUrl(img),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          placeholder: (context, url) => const PiconSkeleton(height: 300, radius: 0, dark: true),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white54),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.format.title,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.format.description,
                            style: const TextStyle(
                                color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.format.dimension,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  currencyFormatter
                                      .format(widget.format.price),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: AppColors.primaryLight,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.primary), // Use primary color for icon
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// GALERIE (réf. carrousel verre dépoli DeO_5_FTXn2)
/// ===============================
class _FormatGallery extends StatefulWidget {
  final List<PhotoFormat> formats;
  final ValueChanged<PhotoFormat> onOpen;

  const _FormatGallery({required this.formats, required this.onOpen});

  @override
  State<_FormatGallery> createState() => _FormatGalleryState();
}

class _FormatGalleryState extends State<_FormatGallery> {
  final PageController _page = PageController(viewportFraction: 0.74);
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  String _cover(PhotoFormat f) => f.images.isEmpty ? '' : ApiService.getFullImageUrl(f.images.first);

  @override
  Widget build(BuildContext context) {
    final formats = widget.formats;
    final current = formats[_index.clamp(0, formats.length - 1)];
    final reduced = reduceMotion(context);
    return Stack(
      children: [
        // Fond : visuel courant flouté, comme une scène.
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: reduced ? 1 : 450),
            child: ImageFiltered(
              key: ValueKey(current.dimension),
              imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: _cover(current).isEmpty
                  ? const ColoredBox(color: AppColors.primary)
                  : CachedNetworkImage(
                      imageUrl: _cover(current),
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                      errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.primary),
                    ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.navyDeep.withValues(alpha: 0.55),
                  AppColors.navyDeep.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
        ),
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Galerie des formats',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${_index + 1} / ${formats.length}',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 420,
                child: RepaintBoundary(
                  child: PageView.builder(
                    controller: _page,
                    itemCount: formats.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final f = formats[i];
                      final active = i == _index;
                      return AnimatedScale(
                        scale: active ? 1 : 0.9,
                        duration: Duration(milliseconds: reduced ? 1 : 260),
                        curve: Curves.easeOutCubic,
                        child: TapScale(
                          onTap: () => widget.onOpen(f),
                          child: _GlassFormatCard(format: f, cover: _cover(f), active: active),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: formats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final active = i == _index;
                    return GestureDetector(
                      onTap: () => reduced
                          ? _page.jumpToPage(i)
                          : _page.animateToPage(i,
                              duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: reduced ? 1 : 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? AppColors.accent : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: active ? AppColors.accent : Colors.white24),
                        ),
                        child: Text(
                          formats[i].dimension,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Text(
                  'Tous les formats',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => GestureDetector(
                    onTap: () => widget.onOpen(formats[i]),
                    child: DimensionTile(format: formats[i]),
                  ),
                  childCount: formats.length,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassFormatCard extends StatelessWidget {
  final PhotoFormat format;
  final String cover;
  final bool active;

  const _GlassFormatCard({required this.format, required this.cover, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: active ? Colors.white.withValues(alpha: 0.55) : Colors.white24,
            width: active ? 1.4 : 1,
          ),
          boxShadow: active
              ? const [BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 18))]
              : const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cover.isEmpty)
                const ColoredBox(color: AppColors.primary)
              else
                CachedNetworkImage(
                  imageUrl: cover,
                  fit: BoxFit.cover,
                  memCacheWidth: 720,
                  placeholder: (_, __) => const PiconSkeleton(height: double.infinity, radius: 0, dark: true),
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: AppColors.primary,
                    child: Icon(Icons.image_not_supported_outlined, color: Colors.white54),
                  ),
                ),
              if (format.isPopular) const _PopularBadge(),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            format.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          if (format.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              format.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                format.dimension,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  currencyFormatter.format(format.price),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
