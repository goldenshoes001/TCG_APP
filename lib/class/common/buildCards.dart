import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

class CardDetailView extends StatelessWidget {
  final Map<String, dynamic> cardData;
  final VoidCallback onBack;

  const CardDetailView({
    super.key,
    required this.cardData,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> details = {};

    String name = cardData["name"];
    String cardText = cardData["desc"];
    details["attribute"] = cardData["attribute"];
    details["type"] = cardData["type"];
    details["card type"] = cardData["cardType"];
    details["atk"] = cardData["atk"];
    details["def"] = cardData["def"];
    details["level"] = cardData["lvl"];
    details["race"] = cardData["race"];
    details["archetype"] = cardData["archetype"];
    details["scale"] = cardData["scale"];
    details["link"] = cardData["linkval"];

    // Filtern der Details (nur gültige Werte)
    final filteredDetails = details.entries
        .where(
          (element) =>
              element.value != null &&
              element.value != "?" &&
              element.value != -1,
        )
        .toList();

    // Aufteilen in zwei Spalten
    final leftColumnDetails = <MapEntry<String, dynamic>>[];
    final rightColumnDetails = <MapEntry<String, dynamic>>[];

    for (int i = 0; i < filteredDetails.length; i++) {
      if (i % 2 == 0) {
        leftColumnDetails.add(filteredDetails[i]);
      } else {
        rightColumnDetails.add(filteredDetails[i]);
      }
    }

    final List<dynamic>? cardImagesDynamic = cardData["card_images"];
    final List<String> cardImages = [];

    if (cardImagesDynamic != null) {
      for (var imageObj in cardImagesDynamic) {
        if (imageObj is Map<String, dynamic>) {
          final imageUrl =
              imageObj['image_url'] ?? imageObj['image_url_cropped'] ?? '';
          if (imageUrl.isNotEmpty) {
            cardImages.add(imageUrl.toString());
          }
        }
      }
    }

    CardData cardDataHelper = CardData();
    Future<String> imageUrlFuture = cardDataHelper.getCorrectImgPath(
      cardImages,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kartenbild
          Center(
            child: FutureBuilder<String>(
              future: imageUrlFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 150,
                    height: 210,
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const SizedBox(
                    width: 150,
                    height: 210,
                    child: Icon(Icons.broken_image, size: 100),
                  );
                } else {
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.white,
                        onPressed: onBack,
                      ),
                      Image.network(
                        snapshot.data!,
                        height: 310,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 150,
                            height: 210,
                            child: Icon(Icons.broken_image, size: 100),
                          );
                        },
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 30),

          // Name
          Text(
            name,
            style: TextStyle(
              fontFamily: "Arial",
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),

          // Beschreibung
          Text(cardText),
          const SizedBox(height: 20),

          // Details in zwei Spalten
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linke Spalte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: leftColumnDetails.map((element) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Key
                          Text(
                            element.key.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          // Value
                          Text(
                            element.value.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(width: 16),

              // Rechte Spalte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rightColumnDetails.map((element) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Key
                          Text(
                            element.key.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          // Value
                          Text(
                            element.value.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Zurück-Button
        ],
      ),
    );
  }
}
