import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:Picon/api_service.dart';
import 'package:Picon/utils/print_quality_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_size_getter/image_size_getter.dart' as isg;
import 'package:image_size_getter/file_input.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

// ─────────────────────────────────────────────────────────────
//  Dimensions (EXIF pris en compte sur fichiers locaux)
// ─────────────────────────────────────────────────────────────

/// Retourne la taille affichée (pixels) après orientation EXIF.
Future<ui.Size> getImageDimensions(String path) async {
  final resolvedPath = ApiService.getFullImageUrl(path);

  if (resolvedPath.startsWith('http')) {
    final headers = <String, String>{};
    if (ApiService.authToken != null) {
      headers['Authorization'] = 'Bearer ${ApiService.authToken}';
    }
    return _getImageDimensionsFallback(resolvedPath, headers: headers);
  }

  try {
    final file = File(resolvedPath);
    if (!await file.exists()) return const ui.Size(1, 1);

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return const ui.Size(1, 1);

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = ui.Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    return size;
  } catch (_) {
    try {
      final file = File(resolvedPath);
      final imageSize = isg.ImageSizeGetter.getSize(FileInput(file));
      if (imageSize.width > 0 && imageSize.height > 0) {
        return ui.Size(imageSize.width.toDouble(), imageSize.height.toDouble());
      }
    } catch (_) {}
    return _getImageDimensionsFallback(resolvedPath);
  }
}

Future<ui.Size> _getImageDimensionsFallback(
  String path, {
  Map<String, String>? headers,
}) async {
  final completer = Completer<ui.Size>();
  final ImageProvider provider = path.startsWith('http')
      ? NetworkImage(path, headers: headers)
      : FileImage(File(path)) as ImageProvider;
  final stream = provider.resolve(const ImageConfiguration());
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      final size = ui.Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      );
      if (!completer.isCompleted) completer.complete(size);
      stream.removeListener(listener);
    },
    onError: (_, __) {
      if (!completer.isCompleted) completer.complete(const ui.Size(1, 1));
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

// ─────────────────────────────────────────────────────────────
//  Compression HD avant upload (sans dégrader inutilement)
// ─────────────────────────────────────────────────────────────

/// ~45 cm au grand côté à 300 DPI — marge pour grands formats studio.
const int kMaxPrintDimension = 5200;

/// JPEG haute qualité (léger allègement, pas de perte visible).
const int kJpegQuality = 92;

/// Limite cible si on ne connaît pas les formats (équivalent 20×30 cm @ 300 DPI).
int _defaultMaxPixels() {
  const refFormat = '20x30 cm';
  final (w, h) = parseDimensionCm(refFormat);
  final longCm = w > h ? w : h;
  return ((longCm / kInchToCm) * 300).ceil();
}

/// Compresse pour l'upload : rotation EXIF, JPEG HQ, redimensionnement seulement si nécessaire.
Future<String> compressForUpload(String originalPath) async {
  try {
    final file = File(originalPath);
    if (!await file.exists()) return originalPath;

    final dimensions = await getImageDimensions(originalPath);
    int origW = dimensions.width.round();
    int origH = dimensions.height.round();

    final maxPixels = _defaultMaxPixels();
    final cap = maxPixels > kMaxPrintDimension ? maxPixels : kMaxPrintDimension;

    int targetW = origW;
    int targetH = origH;

    final longSide = origW > origH ? origW : origH;
    if (longSide > cap) {
      if (origW >= origH) {
        targetW = cap;
        targetH = (origH * cap / origW).round();
      } else {
        targetH = cap;
        targetW = (origW * cap / origH).round();
      }
    }

    final tempDir = await Directory.systemTemp.createTemp('img_compress_');
    final baseName = p.basenameWithoutExtension(originalPath);
    final outputPath = '${tempDir.path}/$baseName.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      originalPath,
      outputPath,
      quality: kJpegQuality,
      minWidth: targetW,
      minHeight: targetH,
      keepExif: false,
      autoCorrectionAngle: true,
      format: CompressFormat.jpeg,
    );

    if (result != null && await File(result.path).exists()) {
      final origSize = await file.length();
      final compSize = await File(result.path).length();
      debugPrint(
        '🗜️ HD : ${_formatBytes(origSize)} → ${_formatBytes(compSize)} '
        '| ${origW}x$origH → ${targetW}x$targetH',
      );
      return result.path;
    }
    return originalPath;
  } catch (e) {
    debugPrint('⚠️ Compression échouée, envoi original : $e');
    return originalPath;
  }
}

Future<List<String>> compressBatch(List<dynamic> files) async {
  final futures = files.map((f) => compressForUpload(f.path));
  return Future.wait(futures);
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1048576).toStringAsFixed(1)} MB';
}
