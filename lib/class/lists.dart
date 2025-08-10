import 'dart:math';
import 'package:tcg_app/class/common/card.dart';

final _rng = Random();

List<String> cardTypes = ["monster", "spell", "trap"];

List<DeckCard> decks = List.generate(100, (index) {
  final deckNumber = index + 1;
  final playerNumber = index + 1;
  final rating = _rng.nextInt(5) + 1;

  return DeckCard(
    texts: ['Deck$deckNumber', 'Player $playerNumber'],
    rating: '$rating/5',
  );
});

List<DeckCard> cards = List.generate(100, (index) {
  final cardType = _rng.nextInt(3);
  final deckNumber = index + 1;
  final rating = _rng.nextInt(5) + 1;
  return DeckCard(
    texts: ['card$deckNumber', cardTypes[cardType]],
    rating: '$rating/5',
  );
});
