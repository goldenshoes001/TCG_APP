// image_cache_manager.dart
// Diese Klasse implementiert mehrere Optimierungen für schnelleres Bildladen

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

    try {
      final storage = FirebaseStorage.instance;
      final uri = Uri.parse(gsPath);
      final path = Uri.decodeComponent(uri.path.substring(1));

      final Reference gsReference = storage.ref(path);
      final String downloadUrl = await gsReference.getDownloadURL();

      // Speichere im Cache
      _urlCache[gsPath] = downloadUrl;

      return downloadUrl;
    } catch (e) {
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
    return FutureBuilder<String>(
      future: ImageCacheManager().getCachedImageUrl(imageUrl),
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
          snapshot.data!,
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
// ============================================================================

class OptimizedCardListItem extends StatelessWidget {
  final Map<String, dynamic> card;
  final VoidCallback onTap;

  const OptimizedCardListItem({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const imageSize = 60.0;

    // Extrahiere Bild-URL
    String imageUrl = '';
    if (card["card_images"] != null &&
        card["card_images"] is List &&
        (card["card_images"] as List).isNotEmpty) {
      imageUrl = card["card_images"][0]["image_url"] ?? '';
    }

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Optimiertes Bild-Widget
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: imageSize,
              height: imageSize,
              borderRadius: BorderRadius.circular(4),
              placeholder: Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.error, size: 30),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                card["name"] ?? 'Unbekannt',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BATCH PRELOADING FÜR LISTEN
// ============================================================================

class ImagePreloader {
  /// Lädt Bilder für eine Liste von Karten vor
  static Future<void> preloadCardImages(
    List<Map<String, dynamic>> cards, {
    int maxToPreload = 300,
  }) async {
    final imageCache = ImageCacheManager();
    final imagePaths = <String>[];

    // Sammle alle Bild-URLs
    for (var card in cards.take(maxToPreload)) {
      if (card["card_images"] != null &&
          card["card_images"] is List &&
          (card["card_images"] as List).isNotEmpty) {
        final imageUrl = card["card_images"][0]["image_url"];
        if (imageUrl != null && imageUrl.toString().isNotEmpty) {
          imagePaths.add(imageUrl.toString());
        }
      }
    }

    // Lade alle Bilder parallel (in Batches)
    await imageCache.preloadImages(imagePaths, maxConcurrent: 100);
  }
}

// ============================================================================
// ANWENDUNGSBEISPIEL
// ============================================================================

/*
VERWENDUNG IN DEINEM CODE:

1. In main.dart beim Preloading:
   
   // Statt einzelner Bild-Läufe
   await ImagePreloader.preloadCardImages(allBannlistCards, maxToPreload: 100);

2. In home.dart und meta.dart:

   // Ersetze FutureBuilder mit Image.network durch:
   CachedNetworkImage(
     imageUrl: card["card_images"][0]["image_url"],
     width: 60,
     height: 60,
     borderRadius: BorderRadius.circular(4),
   )

3. Für Listen mit vielen Bildern:

   @override
   void initState() {
     super.initState();
     // Preload sichtbare Bilder
     ImagePreloader.preloadCardImages(cards, maxToPreload: 20);
   }

VORTEILE:
✅ Bilder werden nur einmal geladen
✅ Paralleles Laden mehrerer Bilder
✅ Kleinere Bildversionen für Listen (cacheWidth/cacheHeight)
✅ Progressives Laden mit Fortschrittsanzeige
✅ Automatisches Caching in Flutter's Image Cache
*/
