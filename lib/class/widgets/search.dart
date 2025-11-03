import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';
import 'package:tcg_app/class/widgets/helperClass%20allgemein/search_results_view.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  // CardData als State-Variable, um Cache zu erhalten
  final CardData _cardData = CardData();
  final TextEditingController suchfeld = TextEditingController();
  Future<List<Map<String, dynamic>>>? _searchFuture;
  Map<String, dynamic>? _selectedCard;

  @override
  Widget build(BuildContext context) {
    if (_selectedCard != null) {
      return _buildCardDetail();
    }

    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.height / 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height / 350),

          // --- Suchfeld ---
          TextField(
            decoration: const InputDecoration(
              hintText: "Suchen...",
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) {
              final trimmedValue = suchfeld.text.trim();
              if (trimmedValue.isNotEmpty) {
                setState(() {
                  _searchFuture = _cardData.ergebniseAnzeigen(trimmedValue).then(
                    (list) async {
                      final cards = list.cast<Map<String, dynamic>>();
                      // Preload der URLs, damit sie beim Rendern im Cache sind
                      await _cardData.preloadCardImages(cards);
                      return cards;
                    },
                  );
                  _selectedCard = null;
                });
              } else {
                setState(() {
                  _searchFuture = Future.value([]);
                  _selectedCard = null;
                });
              }
            },
            controller: suchfeld,
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 55),

          // --- Ergebnis-Anzeige (Ausgelagert) ---
          Expanded(
            child: SearchResultsView(
              searchFuture: _searchFuture,
              cardData: _cardData,
              onCardSelected: (card) {
                setState(() {
                  _selectedCard = card;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetail() {
    return CardDetailView(
      cardData: _selectedCard!,
      onBack: () {
        setState(() {
          _selectedCard = null;
        });
      },
    );
  }
}
