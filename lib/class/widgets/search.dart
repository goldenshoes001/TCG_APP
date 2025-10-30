import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController suchfeld = TextEditingController();
  Future<List<Map<String, dynamic>>>? _searchFuture;

  // State-Variable für die ausgewählte Karte
  Map<String, dynamic>? _selectedCard;

  @override
  Widget build(BuildContext context) {
    final data = CardData();

    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.height / 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height / 350),

          // --- Suchfeld ---
          TextField(
            decoration: InputDecoration(
              hintText: "Suchen...",
              prefixIcon: const Icon(Icons.search),
            ),
            onSubmitted: (value) {
              final trimmedValue = suchfeld.text.trim();
              if (trimmedValue.isNotEmpty) {
                setState(() {
                  _searchFuture = data
                      .ergebniseAnzeigen(trimmedValue)
                      .then((list) => list.cast<Map<String, dynamic>>());
                  _selectedCard = null; // Zurücksetzen bei neuer Suche
                });
              } else {
                setState(() {
                  _searchFuture = Future.value([]);
                  _selectedCard = null;
                });
              }
            },
            controller: suchfeld,
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 55),

          // --- Ergebnis-Anzeige oder Detail-Ansicht ---
          Expanded(
            child: _selectedCard != null
                ? _buildCardDetail()
                : _buildSearchResults(data),
          ),
        ],
      ),
    );
  }

  // Sucherergebnisse anzeigen
  Widget _buildSearchResults(CardData data) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (_searchFuture == null) {
          return const Center(child: Text('Geben Sie einen Suchbegriff ein.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Fehler beim Laden: ${snapshot.error}'));
        }

        final cards = snapshot.data;

        if (cards == null || cards.isEmpty) {
          return const Center(
            child: Text(
              'Keine Karten mit diesem Prefix gefunden.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            CardData cardData = CardData();

            final cardName = card["name"] ?? 'Unbekannte Karte';

            final List<dynamic>? cardImagesDynamic = card["card_images"];
            final List<String> cardImages = [];

            if (cardImagesDynamic != null) {
              for (var imageObj in cardImagesDynamic) {
                if (imageObj is Map<String, dynamic>) {
                  final imageUrl =
                      imageObj['image_url'] ??
                      imageObj['image_url_cropped'] ??
                      '';
                  if (imageUrl.isNotEmpty) {
                    cardImages.add(imageUrl.toString());
                  }
                }
              }
            }

            Future<String> imageUrlFuture = cardData.getCorrectImgPath(
              cardImages,
            );

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCard = card;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FutureBuilder<String>(
                      future: imageUrlFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            width: 50,
                            height: 70,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        } else if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const SizedBox(
                            width: 50,
                            height: 70,
                            child: Icon(Icons.broken_image),
                          );
                        } else {
                          return Image.network(
                            snapshot.data!,
                            height: 70,
                            width: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                width: 50,
                                height: 70,
                                child: Icon(Icons.broken_image),
                              );
                            },
                          );
                        }
                      },
                    ),

                    const SizedBox(width: 15),

                    Expanded(child: Text(cardName)),

                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCardDetail() {
    return CardDetailView(
      cardData: _selectedCard!,
      onBack: () {
        setState(() {
          _selectedCard = null;
        });
      },
    );
  }
}
