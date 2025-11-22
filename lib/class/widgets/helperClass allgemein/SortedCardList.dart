import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

class sortedCardList extends StatefulWidget {
  final Future<Map<String, List<dynamic>>> sortedCards;
  final Function(bool) onCardSelectionChanged;

  const sortedCardList({
    required this.sortedCards,
    required this.onCardSelectionChanged,
    super.key,
  });

  @override
  State<sortedCardList> createState() => _sortedCardListState();
}

class _sortedCardListState extends State<sortedCardList> {
  final CardData _cardData = CardData();
  Map<String, dynamic>? _selectedCard;

  @override
  Widget build(BuildContext context) {
    // Wenn eine Karte ausgewählt ist, zeige CardDetailView
    if (_selectedCard != null) {
      return CardDetailView(
        cardData: _selectedCard!,
        onBack: () {
          setState(() {
            _selectedCard = null;
          });
          widget.onCardSelectionChanged(false); // Buttons wieder anzeigen
        },
      );
    }

    // Sonst zeige die Bannlist
    return FutureBuilder<Map<String, List<dynamic>>>(
      future: widget.sortedCards,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<Map<String, List<dynamic>>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.transparent),
                ),
              );
            } else if (snapshot.hasData) {
              final banned = snapshot.data!['banned'] ?? [];
              final limited = snapshot.data!['limited'] ?? [];
              final semiLimited = snapshot.data!['semiLimited'] ?? [];

              return ListView(
                children: [
                  if (banned.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Forbidden',
                      const Color.fromARGB(255, 255, 255, 255),
                    ),
                    _buildSectionContainer(
                      color: Colors.transparent,
                      cards: banned,
                      icon: Icons.cancel,
                      iconText: null,
                    ),
                  ],
                  if (limited.isNotEmpty) ...[
                    _buildSectionHeader('limited', Colors.white),
                    _buildSectionContainer(
                      color: Colors.transparent,
                      cards: limited,
                      icon: null,
                      iconText: '1',
                    ),
                  ],
                  if (semiLimited.isNotEmpty) ...[
                    _buildSectionHeader('Semi-limited', Colors.white),
                    _buildSectionContainer(
                      color: Colors.transparent,
                      cards: semiLimited,
                      icon: null,
                      iconText: '2',
                    ),
                  ],
                ],
              );
            } else {
              return const Center(child: Text("No Cards found"));
            }
          },
    );
  }

  /// Baut den Container für die Kartenliste
  Widget _buildSectionContainer({
    required Color color,
    required List<dynamic> cards,
    IconData? icon,
    String? iconText,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      padding: const EdgeInsets.only(top: 4.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...cards.map(
            (card) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildCardItem(
                card: card,
                icon: icon,
                iconText: iconText,
                iconColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Baut den Sektionstitel
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title),
    );
  }

  /// Baut einen einzelnen Karten-Eintrag
  Widget _buildCardItem({
    required Map<String, dynamic> card,
    IconData? icon,
    String? iconText,
    required Color iconColor,
  }) {
    final Future<String> imgPathFuture = _cardData.getImgPath(
      card["card_images"][0]["image_url"],
    );

    const imageSize = 60.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCard = card;
        });
        widget.onCardSelectionChanged(true); // Buttons verstecken
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Icon oder Zahl
          Center(
            child: icon != null
                ? Icon(icon, color: iconColor, size: 20)
                : Text(iconText ?? ''),
          ),
          const SizedBox(width: 8),
          // Kartenbild
          FutureBuilder<String>(
            future: imgPathFuture,
            builder: (context, imgSnapshot) {
              if (imgSnapshot.connectionState == ConnectionState.done &&
                  imgSnapshot.hasData &&
                  imgSnapshot.data!.isNotEmpty) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    imgSnapshot.data!,
                    width: imageSize,
                    height: imageSize,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: imageSize,
                        height: imageSize,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.error, size: 30),
                      );
                    },
                  ),
                );
              }
              return Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Kartenname
          Expanded(
            child: Text(
              card["name"],

              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// CardDetailView Klasse (muss importiert werden oder hier definiert sein)
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

    // Filtern der Details
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    return Image.network(
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
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 30),

            // Name
            Text(name),
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
                            Text(element.key.toUpperCase()),
                            Text(element.value.toString()),
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
                            Text(element.key.toUpperCase()),
                            Text(element.value.toString()),
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
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),

                  onPressed: onBack,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
