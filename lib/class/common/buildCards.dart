import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

class CardDetailView extends StatefulWidget {
  final Map<String, dynamic> cardData;
  final VoidCallback onBack;

  const CardDetailView({
    super.key,
    required this.cardData,
    required this.onBack,
  });

  @override
  State<CardDetailView> createState() => _CardDetailViewState();
}

class _CardDetailViewState extends State<CardDetailView> {
  bool _isFullscreen = false;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> details = {};

    String name = widget.cardData["name"];
    String cardText = widget.cardData["desc"];
    details["attribute"] = widget.cardData["attribute"];
    details["type"] = widget.cardData["type"];
    details["card type"] = widget.cardData["cardType"];
    details["atk"] = widget.cardData["atk"];
    details["def"] = widget.cardData["def"];
    details["level"] = widget.cardData["level"];
    details["race"] = widget.cardData["race"];
    details["archetype"] = widget.cardData["archetype"];
    details["scale"] = widget.cardData["scale"];
    details["link"] = widget.cardData["linkval"];

    // Filtern der Details (nur gültige Werte)
    final filteredDetails = details.entries
        .where(
          (element) =>
              element.value != null &&
              element.value != "?" &&
              element.value != -1 &&
              element.value != null &&
              element.value != "",
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

    final List<dynamic>? cardImagesDynamic = widget.cardData["card_images"];
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

    // Fullscreen Overlay
    if (_isFullscreen) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _isFullscreen = false;
          });
        },
        child: Container(
          color: Colors.black,
          child: Center(
            child: FutureBuilder<String>(
              future: imageUrlFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.white,
                  );
                } else {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      snapshot.data!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          size: 100,
                          color: Colors.white,
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ),
      );
    }

    // Normal Detail View
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zurück-Button + Kartenbild
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Zurück-Button links
                IconButton(
                  icon: const Icon(Icons.arrow_back),

                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 22),
                // Kartenbild (anklickbar für Fullscreen)
                FutureBuilder<String>(
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
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _isFullscreen = true;
                          });
                        },
                        child: Image.network(
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
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Name
            Text(
              name,
              style: const TextStyle(
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
          ],
        ),
      ),
    );
  }
}
