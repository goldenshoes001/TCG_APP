// search_results_view.dart

import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/widgets/helperClass%20allgemein/card_list_item.dart'; // Import der neuen Datei

class SearchResultsView extends StatelessWidget {
  final Future<List<Map<String, dynamic>>>? searchFuture;
  final CardData cardData;
  final Function(Map<String, dynamic> card) onCardSelected;

  const SearchResultsView({
    super.key,
    required this.searchFuture,
    required this.cardData,
    required this.onCardSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: searchFuture,
      builder: (context, snapshot) {
        if (searchFuture == null) {
          return const Center(
            child: Text(
              'Geben Sie einen Suchbegriff ein.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Laden...', style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Fehler beim Laden: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final cards = snapshot.data;

        if (cards == null || cards.isEmpty) {
          return const Center(
            child: Text(
              'Keine Karten gefunden.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${cards.length} Karte(n) gefunden'),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return CardListItem(
                    card: card,

                    onTap: () => onCardSelected(card),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
