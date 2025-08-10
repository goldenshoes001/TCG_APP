import 'package:flutter/material.dart';
import 'package:tcg_app/class/lists.dart';

import 'package:tcg_app/class/common/show_card_array.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: 40),
        Showcardarray(cards: decks, crossAxisCount: decks.length),
        SizedBox(height: 40),
        Showcardarray(cards: cards, crossAxisCount: 1),
        SizedBox(height: 40),
      ],
    );
  }
}
