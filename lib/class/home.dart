import 'package:flutter/material.dart';
import 'package:tcg_app/class/lists.dart';

import 'package:tcg_app/class/common/show_card_array.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Showcardarray(cards: decks, crossAxisCount: decks.length),
    );
  }
}
