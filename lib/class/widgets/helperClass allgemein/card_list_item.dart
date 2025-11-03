// card_list_item.dart - KORRIGIERT (Mit Fallback-Logik)

import 'package:flutter/material.dart';
import 'package:tcg_app/class/Imageloader.dart';

// Entferne den alten, nicht mehr benötigten Import
// import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

class CardListItem extends StatelessWidget {
  final Map<String, dynamic> card;
  // Entferne das nicht mehr benötigte Feld
  // final CardData cardData;
  final VoidCallback onTap;

  const CardListItem({
    super.key,
    required this.card,
    // required this.cardData, // ENTFERNT
    required this.onTap,
  });

  // NEUE HILFSFUNKTION: Versucht, alle URLs nacheinander aufzulösen, bis eine funktioniert.
  Future<String> _resolveFirstWorkingImageUrl() async {
    final imageCache = ImageCacheManager();
    final List<dynamic>? cardImagesDynamic = card["card_images"];

    if (cardImagesDynamic == null || cardImagesDynamic.isEmpty) {
      return ''; // Keine Bilder vorhanden
    }

    // Sammle alle potenziellen URLs (image_url und image_url_cropped)
    // in der Reihenfolge, in der sie versucht werden sollen.
    final potentialGsPaths = <String>[];

    for (var item in cardImagesDynamic) {
      if (item is Map<String, dynamic>) {
        final imageObj = item;
        // 1. Zuerst die hohe Auflösung (image_url) versuchen
        final url = imageObj['image_url'] ?? '';
        if (url.isNotEmpty && url.startsWith('gs://')) {
          potentialGsPaths.add(url);
        }
        // 2. Dann die gecroppte Version (image_url_cropped) als Fallback versuchen
        final croppedUrl = imageObj['image_url_cropped'] ?? '';
        if (croppedUrl.isNotEmpty && croppedUrl.startsWith('gs://')) {
          potentialGsPaths.add(croppedUrl);
        }
      }
    }

    // Versuche, jede URL nacheinander aufzulösen und den ersten Erfolg zurückzugeben
    for (var gsPath in potentialGsPaths) {
      // getCachedImageUrl gibt einen leeren String ('') zurück, wenn das Laden fehlschlägt
      final downloadUrl = await imageCache.getCachedImageUrl(gsPath);

      if (downloadUrl.isNotEmpty) {
        return downloadUrl; // Erfolgreich aufgelöste URL (HTTP) gefunden
      }
    }

    return ''; // Kein Bild konnte erfolgreich aufgelöst werden
  }

  @override
  Widget build(BuildContext context) {
    final cardName = card["name"] ?? 'Unbekannte Karte';

    const imageWidth = 50.0;
    const imageHeight = 70.0;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Das Future ist nun die neue Fallback-Logik
            FutureBuilder<String>(
              future: _resolveFirstWorkingImageUrl(),
              builder: (context, snapshot) {
                // Wenn noch geladen wird, zeige Placeholder
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: imageWidth,
                    height: imageHeight,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                // Wenn Fehler oder keine URL gefunden wurde (snapshot.data ist leer)
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  // Fehler oder keine gültige URL gefunden -> Broken Image Icon
                  return const SizedBox(
                    width: imageWidth,
                    height: imageHeight,
                    child: Icon(Icons.broken_image, size: 30),
                  );
                }

                // Erfolgreich aufgelöste URL (die finale HTTP-URL) gefunden.
                return CachedNetworkImage(
                  imageUrl: snapshot.data!, // Dies ist die finale HTTP-URL
                  width: imageWidth,
                  height: imageHeight,
                  borderRadius: BorderRadius.circular(4),
                );
              },
            ),

            const SizedBox(width: 15),
            Expanded(
              child: Text(
                cardName,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ],
        ),
      ),
    );
  }
}
