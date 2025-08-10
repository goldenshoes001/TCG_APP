import 'package:tcg_app/class/common/card.dart';

List<DeckCard> decks = List.generate(100, (index) {
  final int deckNumber = index + 1;
  final int playerNumber = index + 1;

  return DeckCard(texts: ['Deck$deckNumber', 'Player $playerNumber']);
});
