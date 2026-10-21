import 'dart:async';
import 'dart:io';

import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:flutter/material.dart';
import 'package:Picon/utils/print_quality_utils.dart';
import 'package:Picon/utils/image_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Picon/api_service.dart';
import 'package:Picon/models/photo_frame.dart';
import 'package:Picon/utils/order_line_pricing.dart';
import 'package:Picon/widgets/auth_network_image.dart';

// ─────────────────────────────────────────────
//  Modèle de classement d'un format d'impression
// ─────────────────────────────────────────────
class _FormatOption {
  final String dimension;
  final double price;
  final PrintFitAnalysis analysis;
  final bool isRecommended;

  const _FormatOption({
    required this.dimension,
    required this.price,
    required this.analysis,
    this.isRecommended = false,
  });

  PrintQuality get quality => analysis.quality;
  Color get color => qualityColor(quality);
  Color get lightColor => qualityLightColor(quality);
  IconData get icon => qualityIcon(quality);
  String get label => qualityLabelForAnalysis(analysis);
}

// ─────────────────────────────────────────────
//  Widget principal
// ─────────────────────────────────────────────
class PhotoPreviewScreen extends StatefulWidget {
  final List<String> images;
  final Map<String, Map<String, dynamic>> photoDetails;
  final Map<String, double> prices;
  final Map<String, double?> framePrices;
  final List<PhotoFrame> frames;

  const PhotoPreviewScreen({
    super.key,
    required this.images,
    required this.photoDetails,
    required this.prices,
    this.framePrices = const {},
    this.frames = const [],
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isSuggesting = false;

  /// Cache des tailles réelles des images (en pixels)
  final Map<String, Size> _imageSizes = {};
  final Map<String, Future<Size>> _sizeFutures = {};

  /// Copie locale modifiable des détails
  late final Map<String, Map<String, dynamic>> _localDetails;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    // Copie défensive des détails fournis
    _localDetails = {
      for (final img in widget.images)
        img: Map<String, dynamic>.from(
          widget.photoDetails[img] ?? {'size': widget.prices.keys.firstOrNull ?? '', 'quantity': 1},
        ),
    };
    for (final img in widget.images) {
      final size = _localDetails[img]?['size'] as String? ?? '';
      _syncFrameDefaults(img, size);
    }

    // Préchargement asynchrone
    _preloadAndAssignBestFormats();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _preloadAndAssignBestFormats() async {
    for (final img in widget.images) {
      final size = await _loadImageSize(img);
      if (!mounted) return;
      if (_localDetails[img] != null) {
        final best = findBestFormatForImage(size, widget.prices.keys);
        if (_localDetails[img]!['_autoAssigned'] != true) {
          setState(() {
            _localDetails[img]!['size'] = best;
            _localDetails[img]!['_autoAssigned'] = true;
            _syncFrameDefaults(img, best);
          });
        }
      }
    }
  }

  Future<Size> _loadImageSize(String imageUrl) {
    if (_imageSizes.containsKey(imageUrl)) {
      return Future.value(_imageSizes[imageUrl]);
    }
    if (_sizeFutures.containsKey(imageUrl)) {
      return _sizeFutures[imageUrl]!;
    }

    final future = getImageDimensions(imageUrl).then((size) {
      _imageSizes[imageUrl] = size;
      return size;
    });
    _sizeFutures[imageUrl] = future;
    return future;
  }

  List<_FormatOption> _buildFormatOptions(Size imageSize) {
    final recommendedDim = findBestFormatForImage(imageSize, widget.prices.keys);
    final options = widget.prices.entries.map((e) {
      final analysis = analyzePrintFit(imageSize, e.key);
      return _FormatOption(
        dimension: e.key,
        price: e.value,
        analysis: analysis,
        isRecommended: e.key == recommendedDim,
      );
    }).toList();

    options.sort((a, b) {
      if (a.isRecommended && !b.isRecommended) return -1;
      if (!a.isRecommended && b.isRecommended) return 1;
      return a.quality.index.compareTo(b.quality.index);
    });
    return options;
  }

  bool _offersFrame(String dimension) =>
      OrderLinePricing.offersFrame(widget.framePrices[dimension]);

  void _syncFrameDefaults(String imageUrl, String dimension) {
    final details = _localDetails[imageUrl];
    if (details == null) return;

    if (_offersFrame(dimension) && widget.frames.isNotEmpty) {
      details['withFrame'] = true;
      final currentId = details['frameId'];
      PhotoFrame? selected;
      if (currentId != null) {
        for (final frame in widget.frames) {
          if (frame.id == currentId) {
            selected = frame;
            break;
          }
        }
      }
      selected ??= widget.frames.first;
      details['frameId'] = selected.id;
      details['frameName'] = selected.name;
      details['frameImageUrl'] = selected.primaryImage;
    } else {
      details['withFrame'] = false;
      details.remove('frameId');
      details.remove('frameName');
      details.remove('frameImageUrl');
    }
  }

  void _applyFrameSelection(Map<String, dynamic> details, PhotoFrame frame) {
    details['frameId'] = frame.id;
    details['frameName'] = frame.name;
    details['frameImageUrl'] = frame.primaryImage;
  }

  Future<bool> _hasUnsuitablePhotos() async {
    for (final img in widget.images) {
      final dim = _localDetails[img]?['size'] as String? ?? '';
      final imageSize = await _loadImageSize(img);
      if (analyzePrintFit(imageSize, dim).quality == PrintQuality.tooSmall) {
        return true;
      }
    }
    return false;
  }

  Future<void> _confirm() async {
    for (final entry in _localDetails.entries) {
      final size = entry.value['size'] as String? ?? '';
      if (entry.value['withFrame'] == true && _offersFrame(size)) {
        if (entry.value['frameId'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Choisissez un cadre parmi les images proposées.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }
    }

    final hasUnsuitable = await _hasUnsuitablePhotos();
    if (!mounted) return;

    if (hasUnsuitable) {
      final proceed = await _showUnsuitableWarning();
      if (!proceed) return;
    }

    for (final entry in _localDetails.entries) {
      final clean = Map<String, dynamic>.from(entry.value)
        ..remove('_autoAssigned');
      widget.photoDetails[entry.key] = clean;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<bool> _showUnsuitableWarning() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100)),
            SizedBox(width: 8),
            Text('Qualité insuffisante'),
          ],
        ),
        content: const Text(
          'Une ou plusieurs photos sont dans un format déconseillé. '
          'Le résultat final risque d''être flou ou pixelisé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Modifier'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuer quand même'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _suggestBestFormat() async {
    if (widget.prices.isEmpty || widget.images.isEmpty) return;
    setState(() => _isSuggesting = true);

    final images = widget.images;
    final sizes = await Future.wait(images.map(_loadImageSize));

    for (int i = 0; i < images.length; i++) {
      final url = images[i];
      final size = sizes[i];
      final bestDim = findBestFormatForImage(size, widget.prices.keys);
      _localDetails[url] ??= {};
      _localDetails[url]!['size'] = bestDim;
      _localDetails[url]!['_autoAssigned'] = true;
      _syncFrameDefaults(url, bestDim);
    }

    if (mounted) {
      setState(() => _isSuggesting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: const [
          Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text('Formats optimaux attribués à chaque photo !')),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _addMorePhotos() async {
    final picker = ImagePicker();
    List<XFile> pickedFiles = [];
    try {
      pickedFiles = await picker.pickMultiImage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'ouvrir la galerie. Vérifiez les permissions."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (pickedFiles.isNotEmpty && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      try {
        final compressedPaths = await compressBatch(pickedFiles);
        final compressedFiles = compressedPaths.map((p) => File(p)).toList();
        final uploadedUrls = await ApiService.uploadPhotos(compressedFiles);
        
        if (mounted) {
          setState(() {
            final oldLength = widget.images.length;
            widget.images.addAll(uploadedUrls);
            
            // Set details for new photos
            for (final url in uploadedUrls) {
              _localDetails[url] = {
                'size': widget.prices.keys.firstOrNull ?? '',
                'quantity': 1,
              };
            }
            
            // Auto sort them to best format
            _preloadAndAssignBestFormats();
            
            // Select the newly added first photo
            _selectedIndex = oldLength;
          });
        }
      } catch (e) {
        // Handle error silently or log
      } finally {
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading
        }
      }
    }
  }

  Widget _buildImage(String url, {BoxFit fit = BoxFit.cover, Alignment alignment = Alignment.center}) {
    // Résoudre les URLs relatives (ex: /uploads/...) en URLs absolues
    final resolvedUrl = ApiService.getFullImageUrl(url);

    if (resolvedUrl.startsWith('http')) {
      final headers = <String, String>{};
      if (ApiService.authToken != null) {
        headers['Authorization'] = 'Bearer ${ApiService.authToken}';
      }
      return Image.network(
        resolvedUrl,
        fit: fit,
        alignment: alignment,
        headers: headers,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 30),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(resolvedUrl),
        fit: fit,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 30),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Prévisualisation'),
        ),
        body: const Center(child: Text('Aucune photo sélectionnée.')),
      );
    }

    if (_selectedIndex >= widget.images.length) {
      _selectedIndex = widget.images.length - 1;
    }

    final selectedImage = widget.images[_selectedIndex];
    final selectedDimension =
        _localDetails[selectedImage]?['size'] as String? ??
            (widget.prices.keys.firstOrNull ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Choisir le format'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: AppColors.primary, size: 20),
              tooltip: 'Annuler',
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Ajouter des photos',
            onPressed: _addMorePhotos,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            const Positioned.fill(child: GeometricBackground()),
            Column(
              children: [
                _buildThumbnailStrip(),
                const SizedBox(height: 12),

                FutureBuilder<Size>(
                  future: _loadImageSize(selectedImage),
                  builder: (context, snap) {
                    final imageSize = snap.data;
                    return _buildFormatDropdown(
                      selectedImage: selectedImage,
                      selectedDimension: selectedDimension,
                      imageSize: imageSize,
                    );
                  },
                ),
                if (_offersFrame(selectedDimension) && widget.frames.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFrameSelector(
                    selectedImage: selectedImage,
                    selectedDimension: selectedDimension,
                  ),
                ],
                const SizedBox(height: 12),

                // ── Bouton Suggestion (Auto-optimiser) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: _isSuggesting ? null : _suggestBestFormat,
                      icon: _isSuggesting
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.auto_awesome, size: 16),
                      label: Text(
                        _isSuggesting ? 'Analyse...' : 'Auto-optimiser',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: AppColors.primary.withOpacity(0.05),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: FutureBuilder<Size>(
                    future: _loadImageSize(selectedImage),
                    builder: (context, snap) {
                      final imageSize = snap.data ?? const Size(1, 1);
                      final analysis =
                          analyzePrintFit(imageSize, selectedDimension);
                      final targetAspect = analysis.displayAspect;

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final maxW = constraints.maxWidth;
                          final maxH = constraints.maxHeight * 0.76;
                          double pW = maxW - 32;
                          double pH = pW / targetAspect;
                          if (pH > maxH) {
                            pH = maxH;
                            pW = pH * targetAspect;
                          }
                          final opt = _FormatOption(
                            dimension: selectedDimension,
                            price: 0,
                            analysis: analysis,
                          );
                          return SingleChildScrollView(
                            child: _buildPreviewCard(
                              selectedImage: selectedImage,
                              imageSize: imageSize,
                              previewW: pW,
                              previewH: pH,
                              option: opt,
                              analysis: analysis,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                _buildConfirmButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    return Container(
      height: 90,
      padding: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          final url = widget.images[index];
          final isSelected = index == _selectedIndex;
          final dim = _localDetails[url]?['size'] as String? ?? '';

          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(url),
                    // Badge de qualité DPI
                    FutureBuilder<Size>(
                      future: _loadImageSize(url),
                      builder: (context, snap) {
                        if (snap.hasData && dim.isNotEmpty) {
                          final q = analyzePrintFit(snap.data!, dim).quality;
                          return Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: qualityColor(q),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    // Bouton de suppression X
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            widget.images.removeAt(index);
                            _localDetails.remove(url);
                            widget.photoDetails.remove(url);
                            // Adjust selected index if it's out of bounds
                            if (_selectedIndex >= widget.images.length && _selectedIndex > 0) {
                              _selectedIndex--;
                            }
                          });
                          if (widget.images.isEmpty) {
                            Navigator.of(context).pop(false);
                          }
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.only(topRight: Radius.circular(8)),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrameSelector({
    required String selectedImage,
    required String selectedDimension,
  }) {
    final details = _localDetails[selectedImage] ?? {};
    final withFrame = details['withFrame'] == true;
    final framePrice = widget.framePrices[selectedDimension] ?? 0;
    final printPrice = widget.prices[selectedDimension] ?? 0;
    final selectedFrameId = details['frameId'] as int?;
    final unitTotal = OrderLinePricing.unitTotal(
      printPrice: printPrice,
      framePrice: framePrice,
      withFrame: withFrame,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_size_select_large,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Cadre photo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Text(
                  '${unitTotal.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tirage ${printPrice.toStringAsFixed(0)} F'
              '${withFrame ? ' + cadre ${framePrice.toStringAsFixed(0)} F' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 10),
            RadioListTile<bool>(
              value: true,
              groupValue: withFrame,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                'Avec cadre (+${framePrice.toStringAsFixed(0)} F)',
                style: const TextStyle(fontSize: 14),
              ),
              onChanged: (value) {
                setState(() {
                  details['withFrame'] = true;
                  _syncFrameDefaults(selectedImage, selectedDimension);
                });
              },
            ),
            RadioListTile<bool>(
              value: false,
              groupValue: withFrame,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Sans cadre', style: TextStyle(fontSize: 14)),
              onChanged: (value) {
                setState(() {
                  details['withFrame'] = false;
                  details.remove('frameId');
                  details.remove('frameName');
                  details.remove('frameImageUrl');
                });
              },
            ),
            if (withFrame) ...[
              const SizedBox(height: 8),
              const Text(
                'Choisissez votre cadre :',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.frames.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final frame = widget.frames[index];
                    final isSelected = selectedFrameId == frame.id;
                    final imageUrl = frame.primaryImage;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _applyFrameSelection(details, frame);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(11)),
                                child: imageUrl != null
                                    ? AuthNetworkImage(
                                        imageUrl,
                                        width: 110,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorWidget: const Center(
                                          child: Icon(Icons.image_not_supported),
                                        ),
                                      )
                                    : Container(
                                        width: 110,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image_outlined,
                                            size: 32),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 6),
                              child: Text(
                                frame.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormatDropdown({
    required String selectedImage,
    required String selectedDimension,
    required Size? imageSize,
  }) {
    if (imageSize == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: LinearProgressIndicator(),
      );
    }

    final options = _buildFormatOptions(imageSize);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedDimension,
            isExpanded: true,
            icon: const Icon(Icons.expand_more, color: AppColors.primary),
            items: options.map((opt) {
              return DropdownMenuItem<String>(
                value: opt.dimension,
                child: Row(
                  children: [
                    Icon(opt.icon, color: opt.color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        opt.dimension,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (opt.isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Recommandé',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _localDetails[selectedImage]!['size'] = val;
                  _localDetails[selectedImage]!['_autoAssigned'] = true;
                  _syncFrameDefaults(selectedImage, val);
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard({
    required String selectedImage,
    required Size imageSize,
    required double previewW,
    required double previewH,
    required _FormatOption option,
    required PrintFitAnalysis analysis,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Container(
            width: previewW,
            height: previewH,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _buildImage(
                selectedImage,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (analysis.orientationSwapped)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Orientation adaptée : tirage ${analysis.effectiveSizeLabel}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              printPreviewHint(analysis),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildQualityIndicator(option, analysis),
        ],
      ),
    );
  }

  Widget _buildQualityIndicator(_FormatOption option, PrintFitAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: option.lightColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: option.color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: option.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(option.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        color: option.color.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${analysis.dpi.toInt()} DPI · ${cropSummary(analysis)}',
                      style: TextStyle(
                        color: option.color.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (qualityAdviceForAnalysis(analysis) != null) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: option.color.withOpacity(0.25)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: option.color.withOpacity(0.9),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conseil : ${qualityAdviceForAnalysis(analysis)}',
                    style: TextStyle(
                      color: option.color.withOpacity(0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: ElevatedButton.icon(
        onPressed: _confirm,
        icon: const Icon(Icons.check_circle_outline),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: const Text('Confirmer les formats'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
