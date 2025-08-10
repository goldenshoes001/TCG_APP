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
      // Entferne Column und Expanded
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return cards[index];
      },
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount > 10 ? 1 : crossAxisCount,
        mainAxisSpacing: 0.0,
        crossAxisSpacing: 0.0,
        childAspectRatio: crossAxisCount > 10
            ? MediaQuery.of(context).size.width / 130
            : MediaQuery.of(context).size.width / 509,
      ),
    );
  }
}
