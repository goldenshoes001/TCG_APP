// Imageloader.dart - KORRIGIERT FÜR FLEXIBLE URLS

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageCacheManager {
  // Singleton Pattern
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  // In-Memory Cache für bereits geladene URLs
  final Map<String, String> _urlCache = {};

  // Cache für Firebase Storage Pfade
  final Map<String, String> _storageCache = {};

  /// Holt die Download-URL aus dem Cache oder lädt sie neu
  Future<String> getCachedImageUrl(String gsPath) async {
    // Prüfe ob bereits im Cache
    if (_urlCache.containsKey(gsPath)) {
      return _urlCache[gsPath]!;
    }

    // Wenn der Pfad nicht mit 'gs://' beginnt, kann er nicht über Firebase Storage aufgelöst werden
    if (!gsPath.startsWith('gs://')) {
      return ''; // Ungültiger Pfad für Firebase-Auflösung
    }

    try {
      final storage = FirebaseStorage.instance;
      final uri = Uri.parse(gsPath);
      // Entfernt das führende "/" nach dem Bucket-Namen, z.B. aus /o/path/to/file.jpg
      final path = Uri.decodeComponent(uri.path.substring(1));

      final Reference gsReference = storage.ref(path);
      final String downloadUrl = await gsReference.getDownloadURL();

      // Speichere im Cache
      _urlCache[gsPath] = downloadUrl;

      return downloadUrl;
    } catch (e) {
      // Wenn das Laden fehlschlägt (z.B. Datei nicht gefunden), gib leeren String zurück
      return '';
    }
  }

  /// Lädt mehrere URLs parallel (Batch-Loading)
  Future<Map<String, String>> batchLoadUrls(List<String> gsPaths) async {
    final Map<String, String> results = {};

    // Filtere bereits gecachte URLs
    final uncachedPaths = gsPaths
        .where((path) => !_urlCache.containsKey(path))
        .toList();

    if (uncachedPaths.isEmpty) {
      // Alle URLs sind bereits gecacht
      for (var path in gsPaths) {
        results[path] = _urlCache[path]!;
      }
      return results;
    }

    // Lade alle URLs parallel
    final futures = uncachedPaths
        .map((path) => getCachedImageUrl(path))
        .toList();
    final urls = await Future.wait(futures);

    // Baue Ergebnis-Map
    for (int i = 0; i < uncachedPaths.length; i++) {
      results[uncachedPaths[i]] = urls[i];
    }

    // Füge gecachte URLs hinzu
    for (var path in gsPaths) {
      if (_urlCache.containsKey(path)) {
        results[path] = _urlCache[path]!;
      }
    }

    return results;
  }

  /// Preload-Funktion für wichtige Bilder
  Future<void> preloadImages(
    List<String> gsPaths, {
    int maxConcurrent = 5,
  }) async {
    // Teile die Liste in Batches auf
    for (int i = 0; i < gsPaths.length; i += maxConcurrent) {
      final batch = gsPaths.skip(i).take(maxConcurrent).toList();
      await batchLoadUrls(batch);
    }
  }

  /// Cache leeren (für Speicherverwaltung)
  void clearCache() {
    _urlCache.clear();
    _storageCache.clear();
  }

  /// Cache-Größe abfragen
  int getCacheSize() => _urlCache.length;
}

// ============================================================================
// OPTIMIERTES IMAGE WIDGET
// ============================================================================

class CachedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Definiere das Future basierend auf dem URL-Typ
    final Future<String> urlFuture;

    // Prüfe, ob die URL bereits die finale HTTP(S)-Download-URL ist
    if (imageUrl.startsWith('http')) {
      // Wenn ja, direkt verwenden (wichtig für die neue Logik in CardListItem)
      urlFuture = Future.value(imageUrl);
    } else if (imageUrl.startsWith('gs://')) {
      // Wenn es ein gs:// Pfad ist, lade und cachen über den Manager
      urlFuture = ImageCacheManager().getCachedImageUrl(imageUrl);
    } else {
      // Leerer oder ungültiger Pfad
      urlFuture = Future.value('');
    }

    return FutureBuilder<String>(
      future: urlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ??
              SizedBox(
                width: width,
                height: height,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return errorWidget ??
              SizedBox(
                width: width,
                height: height,
                child: const Icon(Icons.broken_image),
              );
        }

        Widget image = Image.network(
          snapshot.data!, // Dies ist die erfolgreich gefundene HTTP-URL
          width: width,
          height: height,
          fit: fit ?? BoxFit.cover,
          // Wichtig: Cache-Eigenschaften setzen
          cacheWidth: width != null ? (width! * 2).toInt() : null,
          cacheHeight: height != null ? (height! * 2).toInt() : null,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ??
                SizedBox(
                  width: width,
                  height: height,
                  child: const Icon(Icons.broken_image),
                );
          },
          // Lade-Builder für progressives Laden
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return SizedBox(
              width: width,
              height: height,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        );

        if (borderRadius != null) {
          image = ClipRRect(borderRadius: borderRadius!, child: image);
        }

        return image;
      },
    );
  }
}

// ============================================================================
// BEISPIEL: OPTIMIERTE VERWENDUNG IN CARD LIST
// ... (Rest der Datei bleibt unverändert)
