import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/Imageloader.dart';
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

    // Wenn eine Karte ausgewählt ist, zeige nur CardDetailView (ohne Suchfeld)
    if (_selectedCard != null) {
      return _buildCardDetail();
    }

    // Normale Suchansicht mit Suchfeld
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.height / 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height / 350),

          // --- Suchfeld ---
          TextField(
            decoration: const InputDecoration(
              hintText: "Suchen...",
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) {
              final trimmedValue = suchfeld.text.trim();
              if (trimmedValue.isNotEmpty) {
                setState(() {
                  _searchFuture = data
                      .ergebniseAnzeigen(trimmedValue)
                      .then((list) => list.cast<Map<String, dynamic>>());
                  _selectedCard = null;
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

          // --- Ergebnis-Anzeige ---
          Expanded(child: _buildSearchResults(data)),
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
          return const Center(
            child: Text(
              'Geben Sie einen Suchbegriff ein.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Laden...', style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Fehler beim Laden: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final cards = snapshot.data;

        if (cards == null || cards.isEmpty) {
          return const Center(
            child: Text(
              'Keine Karten mit diesem Prefix gefunden.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cards.length} Karte(n) gefunden',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  final cardName = card["name"] ?? 'Unbekannte Karte';

                  final List<dynamic>? cardImagesDynamic = card["card_images"];
                  String imageUrl = '';

                  if (cardImagesDynamic != null &&
                      cardImagesDynamic.isNotEmpty) {
                    if (cardImagesDynamic[0] is Map<String, dynamic>) {
                      imageUrl = cardImagesDynamic[0]['image_url'] ?? '';
                    }
                  }

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
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 50,
                            height: 70,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              cardName,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
