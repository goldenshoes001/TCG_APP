import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/card.dart';

class Showcardarray extends StatelessWidget {
  final List<DeckCard> cards;
  final int crossAxisCount;

  const Showcardarray({
    super.key,
    required this.cards,
    this.crossAxisCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(10),
      // Entferne Column und Expanded
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return cards[index];
      },
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount > 10 ? 1 : crossAxisCount,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        childAspectRatio: _calculateSafeAspectRatio(context, crossAxisCount),
      ),
    );
  }

  double _calculateSafeAspectRatio(BuildContext context, int crossAxisCount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 10.0;
    final spacing = 10.0 * (crossAxisCount - 1);
    final cardWidth = (screenWidth - padding - spacing) / crossAxisCount;
    return (cardWidth / 140).clamp(1.5, 5.0);
  }
}
