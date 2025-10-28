import 'package:flutter/material.dart';
// Importe für Firebase Storage und die angepasste CardData Klasse
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

// Importe für Theme-Daten (angenommen, diese existieren in Ihrem Projekt)

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController suchfeld = TextEditingController();

  // State-Variable, die das Future für die Suche hält.
  Future<List<Map<String, dynamic>>>? _searchFuture;

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
                // Setze den State, um das FutureBuilder zu triggern
                setState(() {
                  _searchFuture = data
                      .ergebniseAnzeigen(trimmedValue)
                      // Cast für Typsicherheit
                      .then((list) => list.cast<Map<String, dynamic>>());
                });
              } else {
                setState(() {
                  // Setze das Future zurück, falls der Suchbegriff leer ist
                  _searchFuture = Future.value([]);
                });
              }
            },
            controller: suchfeld,
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 55),

          // --- Ergebnis-Anzeige (FutureBuilder) ---
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _searchFuture,
              builder: (context, snapshot) {
                // Fall 0: Keine Suche gestartet
                if (_searchFuture == null) {
                  return const Center(
                    child: Text('Geben Sie einen Suchbegriff ein.'),
                  );
                }

                // Fall 1: Daten werden geladen
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Fall 2: Fehler
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Fehler beim Laden: ${snapshot.error}'),
                  );
                }

                // Fall 3: Daten sind geladen (Erfolg oder leere Liste)
                final cards = snapshot.data;

                if (cards == null || cards.isEmpty) {
                  return const Center(
                    child: Text(
                      'Keine Karten mit diesem Prefix gefunden.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // --- ListView.builder ---
                return ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    CardData cardData = CardData();

                    // Holt den Kartennamen
                    final cardName = card["name"] ?? 'Unbekannte Karte';

                    // card_images ist eine Liste von Maps mit gs:// URLs
                    final List<dynamic>? cardImagesDynamic =
                        card["card_images"];
                    final List<String> cardImages = [];

                    if (cardImagesDynamic != null) {
                      for (var imageObj in cardImagesDynamic) {
                        if (imageObj is Map<String, dynamic>) {
                          // Priorisiere image_url (hohe Auflösung), dann image_url_cropped
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

                    // Diese Liste enthält jetzt gs:// URLs
                    Future<String> imageUrlFuture = cardData.getCorrectImgPath(
                      cardImages,
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Element: Das Bild (FutureBuilder für imageUrlFuture)
                          FutureBuilder<String>(
                            future: imageUrlFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                // Platzhalter, während das Bild lädt
                                return const SizedBox(
                                  width: 50,
                                  height: 70,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              } else if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                // Fehler oder kein Bildpfad gefunden
                                return const SizedBox(
                                  width: 50,
                                  height: 70,
                                  child: Icon(Icons.broken_image),
                                );
                              } else {
                                // Das geladene Bild
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
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return const SizedBox(
                                          width: 50,
                                          height: 70,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                );
                              }
                            },
                          ),

                          // Fügt Platz zwischen Bild und Text hinzu
                          const SizedBox(width: 15),

                          // 2. Element: Der Name der Karte
                          Expanded(child: Text(cardName)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Firestore Suchfunktion (Prefix-Suche) ---
