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

    return SizedBox(
      height: MediaQuery.of(context).size.width,
      child: GridView.builder(
        scrollDirection: Axis.vertical,
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 2.0,
          crossAxisSpacing: 2.0,
          childAspectRatio: switch (crossAxisCount) {
            2 => 1.9,
            3 => 1.3,
            4 => 1,

            _ => 1,
          },
        ),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}
