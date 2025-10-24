import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

class sortedCardList extends StatelessWidget {
  final CardData _cardData = CardData();
  final Future<Map<String, List<dynamic>>> sortedCards;
  sortedCardList({required this.sortedCards, super.key});

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
              final limited = snapshot.data!['limited'] ?? [];
              final semiLimited = snapshot.data!['semiLimited'] ?? [];

              return ListView(
                children: [
                  if (banned.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Forbidden',
                      const Color.fromARGB(255, 240, 18, 2),
                    ),
                    _buildSectionContainer(
                      color: const Color.fromARGB(255, 240, 18, 2),
                      cards: banned,
                      icon: Icons.cancel,
                      iconText: null,
                    ),
                  ],
                  if (limited.isNotEmpty) ...[
                    _buildSectionHeader('limited', Colors.orange),
                    _buildSectionContainer(
                      color: Colors.orange.shade700,
                      cards: limited,
                      icon: null,
                      iconText: '1',
                    ),
                  ],
                  if (semiLimited.isNotEmpty) ...[
                    _buildSectionHeader('Semi-limited', Colors.yellow.shade300),
                    _buildSectionContainer(
                      color: Colors.yellow,
                      cards: semiLimited,
                      icon: null,
                      iconText: '2',
                    ),
                  ],
                ],
              );
            } else {
              return const Center(child: Text("Keine Karten gefunden"));
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
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Icon oder Zahl
        Center(
          child: icon != null
              ? Icon(icon, color: iconColor, size: 20)
              : Text(
                  iconText ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
