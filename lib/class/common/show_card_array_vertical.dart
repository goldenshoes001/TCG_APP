import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/card.dart';

class ShowcardarrayVertical extends StatelessWidget {
  final List<DeckCard> cards;
  final int crossAxisCount;

  const ShowcardarrayVertical({
    super.key,
    required this.cards,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    // Vertikal: nur die äußere ListView scrollt
    if (crossAxisCount == 1 || crossAxisCount > 4) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          childAspectRatio: 4.0,
        ),
        itemBuilder: (context, index) => cards[index],
      );
    }

    // Horizontal: Korrektur für die Anzeige der Karten
    return SizedBox(
      height: 200, // Eine feste Höhe für die horizontal scrollbare Liste
      child: GridView.builder(
        scrollDirection: Axis.vertical, // Scrollrichtung ist horizontal
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount, // Anzahl der Reihen
          mainAxisSpacing: 2.0,
          crossAxisSpacing: 2.0,
          childAspectRatio: switch (crossAxisCount) {
            2 => 1.9,
            3 => 1.3,
            4 => 1,

            _ => 1, // Standardwert, um Fehler zu vermeiden
          },
        ),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}
