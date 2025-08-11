import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/card.dart';

class ShowcardarrayHorizontal extends StatelessWidget {
  final List<DeckCard> cards;
  int crossAxisCount;

  ShowcardarrayHorizontal({
    super.key,
    required this.cards,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    // Vertikal: nur die äußere ListView scrollt
    crossAxisCount = crossAxisCount < 6
        ? crossAxisCount
        : 1; // Anzahl der Reihen
    // Horizontal: Korrektur für die Anzeige der Karten
    return SizedBox(
      height: switch (crossAxisCount) {
        1 => 100,
        2 => 200,
        3 => 300,
        4 => 400,
        5 => 500,
        _ => 100,
      }, // Eine feste Höhe für die horizontal scrollbare Liste
      child: GridView.builder(
        scrollDirection: Axis.horizontal, // Scrollrichtung ist horizontal
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 2.0,
          crossAxisSpacing: 2.0,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}
