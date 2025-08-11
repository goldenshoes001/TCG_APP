import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/card.dart';
import 'package:tcg_app/class/common/lists.dart';
import 'package:tcg_app/class/common/show_card_array.dart';

class Meta extends StatelessWidget {
  const Meta({super.key});

  @override
  Widget build(BuildContext context) {
    // Die Listen der Karten
    final List<List<DeckCard>> listCards = [decks, cards, decks, cards, decks];

    // Die passenden crossAxisCount-Werte in einer parallelen Liste
    final List<int> crossAxisCounts = [1, 2, 3, 4, 5];
    final List<String> texts = ["Turnier Decks", "Turnier Karten"];

    return ListView.builder(
      itemCount: listCards.length,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            if (index % 2 == 0)
              Text(
                texts[0].toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              )
            else
              Text(
                texts[1].toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            SizedBox(height: 20),
            Showcardarray(
              cards: listCards[index],
              crossAxisCount: crossAxisCounts[index],
            ),
            if (index == listCards.length - 1) SizedBox(height: 40),
          ],
        );
      },
    );
  }
}
