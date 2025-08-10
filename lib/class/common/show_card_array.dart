import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/card.dart';

class Showcardarray extends StatelessWidget {
  final List<DeckCard> cards;
  final int crossAxisCount;

  const Showcardarray({
    super.key,
    required this.cards,
    this.crossAxisCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return cards[index];
            },
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 0.0,
              crossAxisSpacing: 0.0,
              childAspectRatio: 0.7,
            ),
          ),
        ),
      ],
    );
  }
}
