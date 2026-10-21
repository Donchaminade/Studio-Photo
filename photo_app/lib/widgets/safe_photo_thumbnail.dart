import 'dart:io';

import 'package:Picon/api_service.dart';
import 'package:flutter/material.dart';

/// Widget qui affiche n'importe quelle photo (fichier local, URL relative
/// `/uploads/...`, ou URL absolue `http(s)://...`) de manière sécurisée :
///
/// - Détecte automatiquement si le chemin est local ou distant.
/// - Injecte les headers d'authentification pour les URLs réseau.
/// - Catche toutes les erreurs (PathNotFoundException, 404, fichier
///   manquant, etc.) et affiche une icône d'image cassée à la place
///   au lieu de laisser Flutter rendre le texte de l'exception (qui
///   provoquait des overflows de plusieurs centaines de pixels).
class SafePhotoThumbnail extends StatelessWidget {
  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final Widget? loadingWidget;

  const SafePhotoThumbnail(
    this.source, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.errorWidget,
    this.loadingWidget,
  });

  static Map<String, String> get _authHeaders => ApiService.imageAuthHeaders;

  Widget _fallback() {
    final fallbackSize = (width != null && height != null)
        ? (width! < height! ? width! : height!) * 0.5
        : 30.0;
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.grey.shade500,
            size: fallbackSize.clamp(16.0, 80.0),
          ),
        );
  }

  Widget _loader() {
    return loadingWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiService.getFullImageUrl(source);
    final isNetwork = resolvedUrl.startsWith('http');

    Widget child;

    if (isNetwork) {
      child = Image.network(
        resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        headers: _authHeaders,
        errorBuilder: (_, __, ___) => _fallback(),
        loadingBuilder: (context, image, progress) {
          if (progress == null) return image;
          return _loader();
        },
      );
    } else {
      final file = File(resolvedUrl);
      // file.existsSync() peut throw si le chemin est invalide (ex: content://)
      // → on encapsule dans un try/catch
      bool exists = false;
      try {
        exists = file.existsSync();
      } catch (_) {
        exists = false;
      }
      if (!exists) {
        child = _fallback();
      } else {
        child = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      }
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }

    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }
}
