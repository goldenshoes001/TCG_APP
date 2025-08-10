import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/card.dart';

class Showcardarray extends StatelessWidget {
  final List<DeckCard> cards;
  final int crossAxisCount;

  const Showcardarray({
    super.key,
    required this.cards,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    // Vertikal: nur die äußere ListView scrollt
    if (crossAxisCount == 1) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // wichtig
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

    const double cardWidth = 500;
    final double cardHeight = cardWidth / 5.0;

    return SizedBox(
      height: cardHeight + 8.0 + 8.0,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1, // eine Zeile
          mainAxisSpacing: 2.0,
          crossAxisSpacing: 2.0,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) =>
            SizedBox(width: cardWidth, child: cards[index]),
      ),
    );
  }
}
