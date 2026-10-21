import 'package:Picon/api_service.dart';
import 'package:flutter/material.dart';

/// Widget qui charge une image réseau en injectant automatiquement
/// le token d'authentification dans les headers HTTP.
/// À utiliser à la place de [Image.network] pour toutes les URLs
/// qui pointent vers le backend (notamment /uploads/**).
class AuthNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Widget? errorWidget;
  final Widget? loadingWidget;

  const AuthNetworkImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.errorWidget,
    this.loadingWidget,
  });

  static Map<String, String> get _authHeaders => ApiService.imageAuthHeaders;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiService.getFullImageUrl(url);
    return Image.network(
      resolvedUrl,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      headers: _authHeaders,
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ??
          const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 30),
          ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return loadingWidget ??
            Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: Colors.grey,
              ),
            );
      },
    );
  }
}
