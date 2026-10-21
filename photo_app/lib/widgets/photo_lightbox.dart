import 'dart:ui';

import 'package:Picon/utils/colors.dart';
import 'package:Picon/widgets/safe_photo_thumbnail.dart';
import 'package:flutter/material.dart';

/// Visionneuse premium : fond flouté navy, zoom (pinch / double-tap), infos format/qté.
Future<void> showPhotoLightbox(
  BuildContext context, {
  required String imageUrl,
  required String format,
  required int quantity,
  String? heroTag,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => _PhotoLightbox(
        imageUrl: imageUrl, format: format, quantity: quantity, heroTag: heroTag),
    transitionBuilder: (_, a, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.94, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

class _PhotoLightbox extends StatefulWidget {
  final String imageUrl;
  final String format;
  final int quantity;
  final String? heroTag;
  const _PhotoLightbox({required this.imageUrl, required this.format, required this.quantity, this.heroTag});
  @override
  State<_PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<_PhotoLightbox> {
  final _ctrl = TransformationController();

  void _toggleZoom() {
    _ctrl.value = _ctrl.value.getMaxScaleOnAxis() > 1.01
        ? Matrix4.identity()
        : (Matrix4.identity()..scale(2.2));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _chip(IconData i, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final image = SafePhotoThumbnail(widget.imageUrl,
        fit: BoxFit.contain, borderRadius: BorderRadius.circular(18));
    return Material(
      type: MaterialType.transparency,
      child: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: ColoredBox(color: AppColors.primaryDark.withValues(alpha: 0.82)),
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
              child: Row(children: [
                const Expanded(
                  child: Text('Votre photo',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.14)),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onDoubleTap: _toggleZoom,
                  child: InteractiveViewer(
                    transformationController: _ctrl,
                    minScale: 1,
                    maxScale: 5,
                    child: Center(
                      child: widget.heroTag == null ? image : Hero(tag: widget.heroTag!, child: image),
                    ),
                  ),
                ),
              ),
            ),
            Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 8, children: [
              _chip(Icons.straighten_rounded, widget.format),
              _chip(Icons.copy_all_rounded, '× ${widget.quantity}'),
            ]),
            const SizedBox(height: 10),
            Text('Pincez ou touchez deux fois pour zoomer',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5)),
            const SizedBox(height: 18),
          ]),
        ),
      ]),
    );
  }
}
