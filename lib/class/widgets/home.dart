import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final CardData _cardData = CardData();
  late Future<Map<String, List<dynamic>>> sortedCards = _cardData
      .sortTCGBannCards();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<dynamic>>>(
      future: sortedCards,
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
                  "Fehler: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            } else if (snapshot.hasData) {
              final banned = snapshot.data!['banned'] ?? [];
              final semiLimited = snapshot.data!['semiLimited'] ?? [];
              final limited = snapshot.data!['limited'] ?? [];

              return ListView(
                children: [
                  // VERBOTENE KARTEN (Rot)
                  if (banned.isNotEmpty) ...[
                    // 1. Header (Außerhalb des Containers)
                    _buildSectionHeader(
                      'Verboten',
                      const Color.fromARGB(255, 240, 18, 2),
                    ),
                    // 2. Container mit Karten
                    _buildSectionContainer(
                      color: const Color.fromARGB(255, 240, 18, 2),
                      cards: banned,
                      icon: Icons.cancel,
                      iconText: null,
                    ),
                  ],
                  if (limited.isNotEmpty) ...[
                    // 1. Header (Außerhalb des Containers)
                    _buildSectionHeader('Limitiert', Colors.orange),
                    // 2. Container mit Karten
                    _buildSectionContainer(
                      color: Colors.orange.shade700,
                      cards: limited,
                      icon: null,
                      iconText: '1',
                    ),

                    // SEMI-LIMITIERTE KARTEN (Orange)
                    if (semiLimited.isNotEmpty) ...[
                      // 1. Header (Außerhalb des Containers)
                      _buildSectionHeader(
                        'Semi-Limitiert',
                        Colors.green.shade300,
                      ),
                      // 2. Container mit Karten
                      _buildSectionContainer(
                        color: const Color.fromARGB(255, 20, 235, 127),
                        cards: semiLimited,
                        icon: null,
                        iconText: '2',
                      ),
                    ],

                    // LIMITIERTE KARTEN (Gelb)
                  ],
                ],
              );
            } else {
              return const Center(child: Text("Keine Karten gefunden"));
            }
          },
    );
  }

  // Baut den Container für die Kartenliste OHNE Header
  Widget _buildSectionContainer({
    required Color color,
    required List<dynamic> cards,
    IconData? icon,
    String? iconText,
  }) {
    // Die Farbe wird für den Hintergrund des Containers verwendet
    final Color containerColor = color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      padding: const EdgeInsets.only(top: 4.0), // Etwas Platz oben
      decoration: BoxDecoration(
        color: containerColor, // Hintergrundfarbe des Containers
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2), // Farblicher Rand
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Liste der Karten
          ...cards.map(
            (card) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildCardItem(
                card: card,
                icon: icon,
                iconText: iconText,
                iconColor: Colors.white, // Die Bannlisten-Farbe für Icons/Rand
              ),
            ),
          ),
          const SizedBox(height: 8), // Platz unten
        ],
      ),
    );
  }

  // Baut den Sektionstitel (jetzt separat)
  Widget _buildSectionHeader(String title, Color color) {
    // Weißer Text, aber Farbe zur Abgrenzung in einem leichten Padding
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color, // Die Farbe des Headers ist die Bannlisten-Farbe
        ),
      ),
    );
  }

  // Baut einen einzelnen Karten-Eintrag
  Widget _buildCardItem({
    required Map<String, dynamic> card,
    IconData? icon,
    String? iconText,
    required Color iconColor,
  }) {
    final Future<String> imgPathFuture = _cardData.getImgPath(
      card["card_images"][0]["image_url"],
    );
    const imageSize = 180.0; // Größe reduziert für besseres Layout

    // Die einzelne Karte erhält nun Padding, aber keinen eigenen weißen Container
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center, // Vertikale Ausrichtung zentriert
      children: [
        // 1. Verboten-Zeichen / Zahl (jetzt im eigenen Container mit weißem Hintergrund und farbigem Rand)
        Center(
          child: icon != null
              ? Icon(icon, color: iconColor, size: 10)
              : Text(
                  iconText ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
        ),
        // Abstand zwischen Icon und Bild
        // 2. Kartenbild (FutureBuilder NUR für das Bild)
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

            // Ladeanzeige NUR für das Bild
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

        // 3. Kartenname
        Expanded(
          child: Text(
            card["name"],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors
                  .white, // Textfarbe ist weiß, da der Container farbig ist
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
