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
    final safeColumns = crossAxisCount > cards.length
        ? 1
        : crossAxisCount.clamp(crossAxisCount, cards.length);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Horizontal scrollen
      child: SizedBox(
        width: _calculateTotalWidth(
          context,
          safeColumns,
        ), // Gesamtbreite berechnen
        child: GridView.builder(
          shrinkWrap: true,
          // GridView scrollt nicht
          itemCount: cards.length,
          itemBuilder: (context, index) {
            return cards[index];
          },
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: safeColumns,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            childAspectRatio: crossAxisCount == 1 ? 3.0 : 2.0,
          ),
        ),
      ),
    );
  }

  double _calculateTotalWidth(BuildContext context, int columns) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth;
    crossAxisCount == 1 ? cardWidth = screenWidth : cardWidth = 350;

    return (cardWidth) * columns;
  }
}
