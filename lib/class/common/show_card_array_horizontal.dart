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
    double size = MediaQuery.of(context).size.height;

    crossAxisCount = crossAxisCount < 6 ? crossAxisCount : 1;
    return SizedBox(
      height: switch (crossAxisCount) {
        1 => size / 2,
        2 => size / 2,
        3 => size / 2,
        4 => size / 1.4,
        5 => size / 1.5,
        _ => 100,
      },
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
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
