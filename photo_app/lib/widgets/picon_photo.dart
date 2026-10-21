import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Image locale, asset ou réseau, décodée à une taille proche de l'affichage.
class PiconPhoto extends StatelessWidget {
  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int cachePixels;

  const PiconPhoto({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cachePixels = 720,
  });

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) {
      return _fallback(width, height);
    }
    if (source.startsWith('format:')) {
      // Tirage ajouté depuis les tarifs, sans photo associée pour l'instant.
      return SizedBox(
        width: width,
        height: height,
        child: const ColoredBox(
          color: Color(0xFFE6ECF8),
          child: Center(
              child: Icon(Icons.print_outlined, color: Color(0xFF032A85))),
        ),
      );
    }
    final pixels = cachePixels.clamp(48, 1400);
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: source,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: pixels,
        fadeInDuration: const Duration(milliseconds: 160),
        fadeOutDuration: const Duration(milliseconds: 80),
        filterQuality: pixels <= 320 ? FilterQuality.low : FilterQuality.medium,
        placeholder: (_, __) => _fallback(width, height, broken: false),
        errorWidget: (_, __, ___) => _fallback(width, height),
      );
    }
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: pixels,
        filterQuality: pixels <= 320 ? FilterQuality.low : FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallback(width, height),
      );
    }
    return Image.file(
      File(source),
      width: width,
      height: height,
      fit: fit,
      cacheWidth: pixels,
      filterQuality: pixels <= 320 ? FilterQuality.low : FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _fallback(width, height),
    );
  }
}

Widget _fallback(double? width, double? height, {bool broken = true}) {
  return SizedBox(
    width: width,
    height: height,
    child: ColoredBox(
      color: const Color(0xFFE8EDF5),
      child: broken
          ? const Center(
              child:
                  Icon(Icons.broken_image_outlined, color: Color(0xFF9AA3B2)),
            )
          : const SizedBox.expand(),
    ),
  );
}
